// Live in-browser "Best of 3" demo. Connects a guest to the showcase backend in
// .bestof3-play[data-backend], joins the mode in [data-mode], and renders a
// four-player Rock-Paper-Scissors royale. Turn-based: throws stay hidden until
// the server reveals them. Vanilla JS, no build step. Falls back to a self-host
// card if the backend isn't reachable, so the page is safe before it's deployed.
(function () {
  "use strict";

  var root = document.querySelector(".bestof3-play");
  var btn = document.getElementById("bestof3-btn");
  var statusEl = document.getElementById("bestof3-status");
  var gameEl = document.getElementById("bestof3-game");
  if (!btn || !gameEl) return;

  var fallbackEl = document.getElementById("bestof3-fallback");
  var roundEl = document.getElementById("bestof3-round");
  var bannerEl = document.getElementById("bestof3-banner");
  var throwsEl = document.getElementById("bestof3-throws");
  var boardEl = document.getElementById("bestof3-board");

  var host = (root && root.dataset && root.dataset.backend) || "play.asobi.dev";
  var mode = (root && root.dataset && root.dataset.mode) || "bestof3";
  var API = "https://" + host;
  var WS = "wss://" + host + "/ws";

  var THROWS = [
    { key: "rock", glyph: "✊", label: "Rock" },
    { key: "paper", glyph: "✋", label: "Paper" },
    { key: "scissors", glyph: "✌", label: "Scissors" }
  ];
  var GLYPH = { rock: "✊", paper: "✋", scissors: "✌" };

  var ws = null, me = null, matchId = null, running = false, done = false, matchTimer = null;
  var myThrow = null, lastPhase = null;

  function setStatus(s) { if (statusEl) statusEl.textContent = s; }

  function fallback() {
    if (done) return;
    done = true;
    if (matchTimer) { clearTimeout(matchTimer); matchTimer = null; }
    if (ws) { try { ws.close(); } catch (e) {} }
    setStatus("");
    if (fallbackEl) fallbackEl.style.display = "block";
    btn.disabled = false;
  }

  function start() {
    if (fallbackEl) fallbackEl.style.display = "none";
    done = false;
    btn.disabled = true;
    setStatus("Connecting…");
    matchTimer = setTimeout(fallback, 12000);
    fetch(API + "/api/v1/auth/guest", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(guestCreds())
    })
      .then(function (r) { return r.json(); })
      .then(function (d) { if (d && d.access_token) connect(d.access_token); else fallback(); })
      .catch(fallback);
  }

  // Anonymous guest auth: a device id + secret kept in localStorage, so a return
  // visit resumes the same guest player. No username/password, no account to
  // create. Needs the env to enable guest_auth; otherwise /auth/guest 404s and
  // we fall back.
  function guestCreds() {
    var id, secret;
    try { id = localStorage.getItem("asobi_device_id"); secret = localStorage.getItem("asobi_device_secret"); } catch (e) {}
    if (!id || !secret) {
      var idb = new Uint8Array(16), sb = new Uint8Array(32), c = window.crypto || window.msCrypto;
      c.getRandomValues(idb); c.getRandomValues(sb);
      id = "web_" + Array.prototype.map.call(idb, function (x) { return ("0" + x.toString(16)).slice(-2); }).join("");
      var s = ""; for (var i = 0; i < sb.length; i++) s += String.fromCharCode(sb[i]);
      secret = btoa(s);
      try { localStorage.setItem("asobi_device_id", id); localStorage.setItem("asobi_device_secret", secret); } catch (e) {}
    }
    return { device_id: id, device_secret: secret };
  }

  function connect(token) {
    ws = new WebSocket(WS);
    ws.onopen = function () { ws.send(JSON.stringify({ type: "session.connect", payload: { token: token } })); };
    ws.onmessage = function (ev) {
      var msg;
      try { msg = JSON.parse(ev.data); } catch (e) { return; }
      if (msg.type === "session.connected") {
        me = msg.payload.player_id;
        setStatus("Finding a match — filling seats with bots…");
        ws.send(JSON.stringify({ type: "matchmaker.add", payload: { mode: mode } }));
      } else if (msg.type === "match.matched") {
        if (matchTimer) { clearTimeout(matchTimer); matchTimer = null; }
        matchId = msg.payload.match_id;
        running = true;
        gameEl.style.display = "block";
        renderThrows();
        setStatus("You're in. Pick a throw — everyone reveals at once.");
        ws.send(JSON.stringify({ type: "match.join", payload: { match_id: matchId } }));
      } else if (msg.type === "match.state") {
        render(msg.payload);
      }
    };
    ws.onclose = function () { if (running) stop("Disconnected. Click to play again."); else fallback(); };
    ws.onerror = fallback;
  }

  function stop(message) {
    running = false;
    setStatus(message);
    btn.disabled = false;
  }

  function sendThrow(t) {
    if (!running || myThrow || !ws || ws.readyState !== 1) return;
    myThrow = t;
    ws.send(JSON.stringify({ type: "match.input", payload: { throw: t } }));
    setThrowsDisabled(true, t);
  }

  function renderThrows() {
    if (!throwsEl) return;
    throwsEl.innerHTML = "";
    THROWS.forEach(function (t) {
      var b = document.createElement("button");
      b.className = "bestof3-throw";
      b.dataset.throw = t.key;
      b.innerHTML = '<span class="bestof3-glyph">' + t.glyph + "</span>" + t.label;
      b.onclick = function () { sendThrow(t.key); };
      throwsEl.appendChild(b);
    });
  }

  function setThrowsDisabled(disabled, chosen) {
    if (!throwsEl) return;
    var kids = throwsEl.children;
    for (var i = 0; i < kids.length; i++) {
      kids[i].disabled = disabled;
      kids[i].classList.toggle("chosen", chosen && kids[i].dataset.throw === chosen);
    }
  }

  function render(s) {
    if (!s) return;
    var reveal = s.phase === "reveal" || s.phase === "final";

    if (s.phase !== lastPhase) {
      lastPhase = s.phase;
      if (s.phase === "choosing") { myThrow = null; setThrowsDisabled(false, null); }
      else setThrowsDisabled(true, myThrow);
    }

    if (roundEl) roundEl.textContent = "Round " + s.round + " / " + s.rounds + "  ·  " + s.secs_left + "s";

    if (bannerEl) {
      if (s.phase === "final") bannerEl.textContent = "\u{1F3C6} " + (s.winner === "you" ? "You win the set!" : s.winner + " wins the set");
      else if (s.phase === "reveal") bannerEl.textContent = "Reveal";
      else bannerEl.textContent = "Throw before the timer runs out";
    }

    renderBoard(s.players || [], reveal);
  }

  function renderBoard(players, reveal) {
    if (!boardEl) return;
    players = players.slice().sort(function (a, b) { return b.total - a.total; });
    boardEl.innerHTML = "";
    players.forEach(function (p) {
      var row = document.createElement("div");
      row.className = "bestof3-row" + (p.is_you ? " me" : "");
      var hand = reveal
        ? (p.throw ? GLYPH[p.throw] : "—")
        : (p.locked ? "✅" : "…");
      var gain = reveal && p.round_score > 0 ? ' <span class="bestof3-gain">+' + p.round_score + "</span>" : "";
      row.innerHTML =
        '<span class="bestof3-hand">' + hand + "</span>" +
        '<span class="bestof3-name">' + p.name + "</span>" +
        '<span class="bestof3-total">' + p.total + gain + "</span>";
      boardEl.appendChild(row);
    });
  }

  btn.addEventListener("click", start);
})();
