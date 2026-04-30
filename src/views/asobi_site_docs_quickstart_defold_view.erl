-module(asobi_site_docs_quickstart_defold_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-qs-defold", title => ~"Defold quickstart — Asobi docs"},
            Bindings
        ),
        #{}
    }.

-spec render(az:bindings()) -> az:template().
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
                ~" and add:"
            ]},
            code(
                ~"text", ~"https://github.com/widgrensit/asobi-defold/archive/refs/heads/main.zip"
            ),
            {p, [], [
                ~"Then ",
                {strong, [], [~"Project \x{2192} Fetch Libraries"]},
                ~". The SDK shows up as ",
                {code, [], [~"asobi"]},
                ~" in your project tree."
            ]},

            {h2, [], [~"2. Bootstrap"]},
            {p, [], [
                ~"Add a bootstrap script (",
                {code, [], [~"main/boot.script"]},
                ~") and assign it to a game object in your main collection:"
            ]},
            code(
                ~"lua",
                ~"""
local asobi = require("asobi.client")

local HOST = "localhost"
local PORT = 8080

function init(self)
    self.client = asobi.new(HOST, PORT, false)  -- use_ssl = false
end
"""
            ),

            {h2, [], [~"3. Authenticate"]},
            code(
                ~"lua",
                ~"""
self.client.auth.register("player1", "secret123", "Player One", function(err, result)
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
            code(
                ~"lua",
                ~"""
self.client.realtime.on_connected(function()
    print("ws connected")
    self.client.realtime.add_to_matchmaker("arena")
end)

self.client.realtime.on_matched(function(data)
    print("matched: " .. data.match_id)
end)

self.client.realtime.on_match_state(function(state)
    -- update game world from server tick
end)

self.client.realtime.connect()
"""
            ),

            {h2, [], [~"5. Send input"]},
            code(
                ~"lua",
                ~"""
self.client.realtime.send_match_input(json.encode({
    action = "move", x = 1, y = 0
}))
"""
            ),
            {p, [], [
                ~"Input is fire-and-forget. The next ",
                {code, [], [~"on_match_state"]},
                ~" callback will reflect the server's authoritative response."
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
