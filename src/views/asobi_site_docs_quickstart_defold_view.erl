-module(asobi_site_docs_quickstart_defold_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-qs-defold", title => ~"Defold quickstart — Asobi docs"},
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
                ~" / Quick start \x{2014} Defold"
            ]},
            {h1, [], [~"Quick start \x{2014} Defold"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Connect a Defold project to a running Asobi server in about five minutes. ",
                ~"Don't have a server yet? Run the ",
                {a, [{href, ~"/docs/quickstart"}, az_navigate], [~"server quickstart"]},
                ~" first."
            ]},

            {h2, [], [~"1. Add the SDK as a library dependency"]},
            {p, [], [
                ~"Open ",
                {strong, [], [~"game.project \x{2192} Project \x{2192} Dependencies"]},
                ~" and add both the SDK (pinned to a release tag) and the WebSocket extension it needs:"
            ]},
            code(
                ~"text",
                ~"""
https://github.com/widgrensit/asobi-defold/archive/refs/tags/v1.1.0.zip
https://github.com/defold/extension-websocket/archive/refs/tags/4.2.2.zip
"""
            ),
            {p, [], [
                ~"Pin to a tag - ",
                {code, [], [~"main"]},
                ~" is unstable. Then ",
                {strong, [], [~"Project \x{2192} Fetch Libraries"]},
                ~". The SDK shows up as ",
                {code, [], [~"asobi"]},
                ~" in your project tree."
            ]},

            {h2, [], [~"2. Bootstrap"]},
            {p, [], [
                ~"Register WebSocket callbacks from a ",
                {code, [], [~".script"]},
                ~" that lives for the whole app (a script in ",
                {code, [], [~"main.collection"]},
                ~"), not a ",
                {code, [], [~"gui_script"]},
                ~". Add ",
                {code, [], [~"main/boot.script"]},
                ~" and assign it to a game object in your main collection:"
            ]},
            code(
                ~"lua",
                ~"""
local asobi = require("asobi.client")

function init(self)
    -- Local engine: host, port, use_ssl = false
    self.client = asobi.create("localhost", 8084, false)
end
"""
            ),
            {p, [], [
                {strong, [], [~"Connect to your hosted environment. "]},
                ~"Deployed on ",
                {a, [{href, ~"https://console.asobi.dev"}], [~"console.asobi.dev"]},
                ~"? Point the client at your environment over SSL on port 443:"
            ]},
            code(
                ~"lua", ~"self.client = asobi.create(\"<env>.asobi.dev\", 443, true)"
            ),

            {h2, [], [~"3. Authenticate"]},
            {p, [], [
                ~"The client is the first argument to every API call. ",
                ~"The callback receives ",
                {code, [], [~"(data, err)"]},
                ~":"
            ]},
            code(
                ~"lua",
                ~"""
self.client.auth.register(self.client, "player1", "secret123", nil,
    function(data, err)
        if err then
            print("auth failed: " .. err)
            return
        end
        print("logged in as " .. self.client.player_id)
    end)
"""
            ),
            {p, [], [
                ~"Auth requests are rate-limited at 5/sec per IP. Production builds should use a platform provider \x{2014} see ",
                {a, [{href, ~"/docs/security/auth"}, az_navigate], [~"Auth & rate limiting"]},
                ~"."
            ]},

            {h2, [], [~"4. Open the WebSocket and queue"]},
            {p, [], [
                ~"Realtime is a colon-style event emitter. Register handlers with ",
                {code, [], [~"realtime:on(event, cb)"]},
                ~", then connect:"
            ]},
            code(
                ~"lua",
                ~"""
self.client.realtime:on("connected", function()
    print("ws connected")
    self.client.realtime:add_to_matchmaker("arena")
end)

self.client.realtime:on("match_matched", function(payload)
    self.client.realtime:join_match(payload.match_id)
end)

self.client.realtime:on("match_state", function(state)
    -- update game world from the server's authoritative tick
end)

self.client.realtime:connect()
"""
            ),

            {h2, [], [~"5. Send input"]},
            code(
                ~"lua",
                ~"""
self.client.realtime:send_match_input({action = "move", x = 1, y = 0})
"""
            ),
            {p, [], [
                ~"Input is fire-and-forget. The next ",
                {code, [], [~"match_state"]},
                ~" event will reflect the server's authoritative response."
            ]},

            {h2, [], [~"What's next"]},
            {ul, [], [
                {li, [], [{a, [{href, ~"/defold"}], [~"Full SDK reference"]}]},
                {li, [], [
                    {a, [{href, ~"https://github.com/widgrensit/asobi-defold-demo"}], [
                        ~"asobi-defold-demo"
                    ]},
                    ~" \x{2014} a working arena demo."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/lua/api"}, az_navigate], [~"game.* Lua API"]}
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/tutorials/hot-reload"}, az_navigate], [
                        ~"Live-edit your game"
                    ]}
                ]}
            ]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
