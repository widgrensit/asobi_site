// Live in-browser "Live Patch" demo. Connects a guest to the showcase backend
// named in .livepatch-play[data-backend], joins the mode in [data-mode], and
// renders a party trivia game. The point of the demo: while you play, the
// server's scoring rule is hot-reloaded (see asobi_livepatch_lua/patch.sh) and
// the running match re-scores WITHOUT reconnecting. match.state carries the live
// rule name, so we flash the moment it changes. Vanilla JS, no build step.
(function () {
  "use strict";

  var root = document.querySelector(".livepatch-play");
  var btn = document.getElementById("livepatch-btn");
  var statusEl = document.getElementById("livepatch-status");
  var gameEl = document.getElementById("livepatch-game");
  if (!btn || !gameEl) return;

  var fallbackEl = document.getElementById("livepatch-fallback");
  var ruleEl = document.getElementById("livepatch-rule");
  var flashEl = document.getElementById("livepatch-flash");
  var questionEl = document.getElementById("livepatch-question");
  var optionsEl = document.getElementById("livepatch-options");
  var scoresEl = document.getElementById("livepatch-scores");
  var codeEl = document.getElementById("livepatch-code");

  var host = (root && root.dataset && root.dataset.backend) || "play.asobi.dev";
  var mode = (root && root.dataset && root.dataset.mode) || "livepatch";
  var API = "https://" + host;
  var WS = "wss://" + host + "/ws";

  // The demo's fixed rule set, keyed by the name match.lua broadcasts. Shown in
  // the code panel so you can read the rule that's currently live.
  var RULES = {
    "Flat 100": "score = function(is_correct, secs_left, streak)\n  if is_correct then return 100 end\n  return 0\nend",
    "Speed bonus": "score = function(is_correct, secs_left, streak)\n  if is_correct then return 50 + secs_left * 10 end\n  return 0\nend",
    "Streak multiplier": "score = function(is_correct, secs_left, streak)\n  if is_correct then return 100 * streak end\n  return 0\nend"
  };

  var ws = null, me = null, matchId = null, running = false, done = false, matchTimer = null;
  var lastRule = null, lastQi = null, answered = false;

  function setStatus(s) { if (statusEl) statusEl.textContent = s; }

  // Shown when the hosted showcase backend isn't reachable yet: point people at
  // the self-host path instead of leaving a dead button.
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
    // If nothing connects us to a match in time, the host probably isn't up.
    matchTimer = setTimeout(fallback, 9000);
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
        setStatus("Finding a match…");
        ws.send(JSON.stringify({ type: "matchmaker.add", payload: { mode: mode } }));
      } else if (msg.type === "match.matched") {
        if (matchTimer) { clearTimeout(matchTimer); matchTimer = null; }
        matchId = msg.payload.match_id;
        running = true;
        gameEl.style.display = "block";
        setStatus("You're in. Answer the question — then watch the scoring rule get patched live.");
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

  function answer(i) {
    if (!running || answered || !ws || ws.readyState !== 1) return;
    answered = true;
    ws.send(JSON.stringify({ type: "match.input", payload: { answer: i } }));
    var kids = optionsEl.children;
    for (var k = 0; k < kids.length; k++) {
      kids[k].disabled = true;
      if (k === i - 1) kids[k].classList.add("chosen");
    }
  }

  function render(s) {
    if (!s) return;

    // The load-bearing moment: the live scoring rule changed under a running
    // match. Flash it and swap the code panel - the WebSocket never reconnected.
    if (s.rule !== lastRule) {
      lastRule = s.rule;
      if (ruleEl) ruleEl.textContent = "Scoring rule: " + s.rule;
      if (codeEl) codeEl.textContent = RULES[s.rule] || "";
      if (flashEl) {
        flashEl.textContent = "Patched live — nobody reconnected";
        flashEl.classList.add("show");
        setTimeout(function () { flashEl.classList.remove("show"); }, 2200);
      }
    }

    if (s.qi !== lastQi) {
      lastQi = s.qi;
      answered = false;
      renderQuestion(s);
    }

    if (s.phase === "reveal") markReveal(s.answer);
    renderScores(s.scores);
  }

  function renderQuestion(s) {
    if (questionEl) questionEl.textContent = s.question || "";
    if (!optionsEl) return;
    optionsEl.innerHTML = "";
    var opts = s.options || [];
    for (var i = 0; i < opts.length; i++) {
      (function (idx) {
        var b = document.createElement("button");
        b.className = "livepatch-option";
        b.textContent = opts[idx];
        b.onclick = function () { answer(idx + 1); };
        optionsEl.appendChild(b);
      })(i);
    }
  }

  function markReveal(correct) {
    if (!optionsEl || !correct) return;
    var kids = optionsEl.children;
    for (var k = 0; k < kids.length; k++) {
      kids[k].disabled = true;
      if (k === correct - 1) kids[k].classList.add("correct");
    }
  }

  function renderScores(scores) {
    if (!scoresEl || !scores) return;
    var rows = [];
    for (var id in scores) {
      if (!Object.prototype.hasOwnProperty.call(scores, id)) continue;
      rows.push({ id: id, score: scores[id].score || 0, streak: scores[id].streak || 0 });
    }
    rows.sort(function (a, b) { return b.score - a.score; });
    scoresEl.innerHTML = "";
    for (var r = 0; r < rows.length; r++) {
      var row = document.createElement("div");
      row.className = "livepatch-score" + (rows[r].id === me ? " me" : "");
      var who = rows[r].id === me ? "you" : rows[r].id.replace(/^guest_/, "");
      row.textContent = who + "  ·  " + rows[r].score + (rows[r].streak > 1 ? "  (×" + rows[r].streak + ")" : "");
      scoresEl.appendChild(row);
    }
  }

  btn.addEventListener("click", start);
})();
