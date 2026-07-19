-module(asobi_site_docs_quickstart_js_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-qs-js", title => ~"JavaScript / TypeScript quickstart — Asobi docs"},
            Bindings
        ),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Quick start - JavaScript / TypeScript"
            ]},
            {h1, [], [~"Quick start - JavaScript / TypeScript"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Connect a browser or Node game to a running Asobi server in about five minutes. ",
                ~"No server yet? Run the ",
                {a, [{href, ~"/docs/quickstart"}, az_navigate], [~"server quickstart"]},
                ~" first - it gives you a backend on localhost:8084 with a ",
                {code, [], [~"default"]},
                ~" match mode, which is what this page connects to."
            ]},

            {h2, [], [~"1. Install"]},
            {p, [], [
                ~"The package is ",
                {code, [], [~"@widgrensit/asobi"]},
                ~". It is not on npm yet, so install it from GitHub (the ",
                {code, [], [~"prepare"]},
                ~" script builds it on install):"
            ]},
            code(~"bash", ~"npm install github:widgrensit/asobi-js"),
            {p, [], [
                ~"It is ",
                {strong, [], [~"ESM-only"]},
                ~" and targets ",
                {strong, [], [~"Node 22+"]},
                ~" (it uses the global ",
                {code, [], [~"WebSocket"]},
                ~" and ",
                {code, [], [~"fetch"]},
                ~"). On Node 18/20, install ",
                {code, [], [~"ws"]},
                ~" and assign it to ",
                {code, [], [~"globalThis.WebSocket"]},
                ~" before importing. Browsers work as-is with any bundler (Vite, esbuild, Webpack)."
            ]},

            {h2, [], [~"2. Authenticate and open the socket"]},
            {p, [], [
                ~"Create the client, get a guest session, then open the realtime socket - it reuses the ",
                ~"stored access token automatically. You generate and persist the ",
                {code, [], [~"device_secret"]},
                ~" yourself (>= 32 random bytes, base64); the same ",
                {code, [], [~"device_id"]},
                ~" + secret resumes the same guest on the next launch."
            ]},
            code(
                ~"javascript",
                ~"""
import { Asobi } from "@widgrensit/asobi";

const asobi = new Asobi({ baseUrl: "http://localhost:8084" });

const session = await asobi.auth.guest({
  device_id: deviceId,       // stable per-device id
  device_secret: deviceSecret // your >= 32-byte base64 secret
});
// session.player_id, session.access_token, session.created

const ws = asobi.websocket();   // derives ws://localhost:8084/ws + token
await ws.connect();             // sends session.connect and authenticates
"""
            ),

            {h2, [], [~"3. Join a match and exchange state"]},
            {p, [], [
                ~"There is no ",
                {code, [], [~"join(mode)"]},
                ~" helper - you queue the matchmaker and the server pushes the match once it forms. ",
                ~"Subscribe before you queue, then send input with the fire-and-forget ",
                {code, [], [~"sendFire"]},
                ~":"
            ]},
            code(
                ~"javascript",
                ~"""
ws.on("match.matched", (p) => console.log("in match", p.match_id));
ws.on("match.state", (s) => render(s.players)); // players keyed by player_id

ws.sendFire("matchmaker.add", { mode: "default" });

// later, each frame or on input:
ws.sendFire("match.input", { data: { move_x: 1, move_y: 0 } });
"""
            ),
            {p, [], [
                {code, [], [~"mode"]},
                ~" must be a mode your server actually defines. The server quickstart ships ",
                {code, [], [~"default"]},
                ~"; a demo backend may serve ",
                {code, [], [~"demo"]},
                ~" instead."
            ]},

            {h2, [], [~"Core API"]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"new Asobi({ baseUrl, accessToken?, onTokens? })"]},
                    ~" - root SDK (REST + realtime)."
                ]},
                {li, [], [
                    {code, [], [~"asobi.auth.guest({ device_id, device_secret })"]},
                    ~" - guest auth; also ",
                    {code, [], [~"register"]},
                    ~", ",
                    {code, [], [~"login"]},
                    ~", ",
                    {code, [], [~"upgradeGuest"]},
                    ~"."
                ]},
                {li, [], [
                    {code, [], [~"asobi.websocket()"]},
                    ~" then ",
                    {code, [], [~"ws.connect()"]},
                    ~" - open and authenticate the realtime socket."
                ]},
                {li, [], [
                    {code, [], [~"ws.on(event, cb)"]},
                    ~" - subscribe to pushed events (returns an unsubscribe fn; ",
                    {code, [], [~"\"*\""]},
                    ~" matches all)."
                ]},
                {li, [], [
                    {code, [], [~"ws.sendFire(type, payload)"]},
                    ~" - fire-and-forget (input); ",
                    {code, [], [~"ws.send(type, payload)"]},
                    ~" - RPC that awaits a reply (10s timeout)."
                ]}
            ]},

            {h2, [], [~"Gotchas"]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Tokens live in memory only. "]},
                    ~"Pass ",
                    {code, [], [~"onTokens"]},
                    ~" to persist them, and store your guest ",
                    {code, [], [~"device_secret"]},
                    ~" yourself - otherwise every launch creates a new account."
                ]},
                {li, [], [
                    {strong, [], [~"Handle auth expiry. "]},
                    ~"On ",
                    {code, [], [~"invalid_token"]},
                    ~" / idle timeout the socket emits ",
                    {code, [], [~"auth_expired"]},
                    ~" and stops reconnecting - re-auth and reconnect."
                ]},
                {li, [], [
                    {strong, [], [~"Use wss in production. "]},
                    ~"A browser on an ",
                    {code, [], [~"https"]},
                    ~" page cannot open ",
                    {code, [], [~"ws://"]},
                    ~" - serve the backend over TLS so the URL becomes ",
                    {code, [], [~"wss://"]},
                    ~"."
                ]}
            ]},

            {h2, [], [~"What's next"]},
            {ul, [], [
                {li, [], [{a, [{href, ~"/js"}, az_navigate], [~"Full JS/TS SDK reference"]}]},
                {li, [], [
                    {a, [{href, ~"/docs/protocols/websocket"}, az_navigate], [
                        ~"WebSocket protocol"
                    ]},
                    ~" - the message types behind ",
                    {code, [], [~"on"]},
                    ~" / ",
                    {code, [], [~"sendFire"]},
                    ~"."
                ]},
                {li, [], [{a, [{href, ~"/docs/authentication"}, az_navigate], [~"Authentication"]}]}
            ]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
