// Live in-browser Asobi arena demo. Connects a guest player to the backend
// named in the .arena-play [data-backend] attribute (set from asobi_site's
// demo_backend_host config; in prod this points at an asobi_saas-provisioned
// env running the arena sample), renders match state on a canvas, and streams
// input. Vanilla JS, no build step. Wire protocol: register ->
// session.connect -> matchmaker.add -> match.state / match.input.
(function () {
  "use strict";
  var ARENA_W = 800, ARENA_H = 600;

  var root = document.querySelector(".arena-play");
  var btn = document.getElementById("arena-play-btn");
  var canvas = document.getElementById("arena-canvas");
  var statusEl = document.getElementById("arena-status");
  if (!btn || !canvas) return;

  var host = (root && root.dataset && root.dataset.backend) || "play.asobi.dev";
  var API = "https://" + host;
  var WS = "wss://" + host + "/ws";
  var ctx = canvas.getContext("2d");

  var ws = null, me = null, state = null, running = false, inputTimer = null;
  var keys = { up: false, down: false, left: false, right: false };
  var mouse = { x: ARENA_W / 2, y: ARENA_H / 2, down: false };

  function setStatus(s) { if (statusEl) statusEl.textContent = s; }

  function start() {
    btn.disabled = true;
    setStatus("Connecting…");
    var uname = "guest_" + Math.random().toString(36).slice(2, 10);
    var pass = Math.random().toString(36).slice(2) + "Aa1!";
    fetch(API + "/api/v1/auth/register", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ username: uname, password: pass })
    })
      .then(function (r) { return r.json(); })
      .then(function (d) { connect(d.session_token || d.access_token); })
      .catch(function () { setStatus("Couldn't reach the demo server — try again."); btn.disabled = false; });
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
        ws.send(JSON.stringify({ type: "matchmaker.add", payload: { mode: "arena" } }));
      } else if (msg.type === "match.matched") {
        running = true;
        canvas.style.display = "block";
        setStatus("You're in. WASD to move, mouse to aim, click to shoot.");
        requestAnimationFrame(loop);
        if (!inputTimer) inputTimer = setInterval(sendInput, 50);
      } else if (msg.type === "match.state") {
        state = msg.payload;
      }
    };
    ws.onclose = function () { stop("Disconnected. Click to play again."); };
    ws.onerror = function () { setStatus("Connection error."); };
  }

  function stop(message) {
    running = false;
    if (inputTimer) { clearInterval(inputTimer); inputTimer = null; }
    setStatus(message);
    btn.disabled = false;
  }

  function sendInput() {
    if (!running || !ws || ws.readyState !== 1) return;
    ws.send(JSON.stringify({
      type: "match.input",
      payload: {
        up: keys.up, down: keys.down, left: keys.left, right: keys.right,
        shoot: mouse.down, aim_x: Math.round(mouse.x), aim_y: Math.round(mouse.y)
      }
    }));
  }

  function loop() {
    if (!running) return;
    render();
    requestAnimationFrame(loop);
  }

  function render() {
    var sx = canvas.width / ARENA_W, sy = canvas.height / ARENA_H;
    ctx.fillStyle = "#0d1f3c";
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    if (!state) return;

    var projectiles = state.projectiles || [];
    ctx.fillStyle = "#e38b1f";
    for (var i = 0; i < projectiles.length; i++) {
      var pr = projectiles[i];
      ctx.beginPath();
      ctx.arc(pr.x * sx, pr.y * sy, 3, 0, Math.PI * 2);
      ctx.fill();
    }

    var players = state.players || {};
    for (var id in players) {
      if (!Object.prototype.hasOwnProperty.call(players, id)) continue;
      var p = players[id];
      var cx = p.x * sx, cy = p.y * sy;
      ctx.fillStyle = id === me ? "#4ae183" : (id.indexOf("bot_") === 0 ? "#ffb4ab" : "#91cdff");
      ctx.beginPath();
      ctx.arc(cx, cy, 12, 0, Math.PI * 2);
      ctx.fill();
      var w = 26, hp = (p.hp || 0) / (p.max_hp || 100);
      ctx.fillStyle = "rgba(0,0,0,0.5)";
      ctx.fillRect(cx - w / 2, cy - 20, w, 4);
      ctx.fillStyle = "#4ae183";
      ctx.fillRect(cx - w / 2, cy - 20, w * Math.max(0, Math.min(1, hp)), 4);
    }

    ctx.fillStyle = "#e0e1f5";
    ctx.font = "14px monospace";
    var t = Math.max(0, Math.round((state.time_remaining || 0) / 1000));
    ctx.fillText("Round " + (state.round || 1) + "  ·  " + (state.phase || "") + "  ·  " + t + "s", 10, 20);
  }

  var keymap = {
    KeyW: "up", KeyS: "down", KeyA: "left", KeyD: "right",
    ArrowUp: "up", ArrowDown: "down", ArrowLeft: "left", ArrowRight: "right"
  };
  window.addEventListener("keydown", function (e) {
    if (keymap[e.code]) { keys[keymap[e.code]] = true; if (running) e.preventDefault(); }
  });
  window.addEventListener("keyup", function (e) {
    if (keymap[e.code]) keys[keymap[e.code]] = false;
  });
  canvas.addEventListener("mousemove", function (e) {
    var r = canvas.getBoundingClientRect();
    mouse.x = (e.clientX - r.left) / r.width * ARENA_W;
    mouse.y = (e.clientY - r.top) / r.height * ARENA_H;
  });
  canvas.addEventListener("mousedown", function () { mouse.down = true; });
  window.addEventListener("mouseup", function () { mouse.down = false; });
  canvas.addEventListener("contextmenu", function (e) { e.preventDefault(); });
  btn.addEventListener("click", start);
})();
