-module(asobi_site_docs_quickstart_godot_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-qs-godot", title => ~"Godot quickstart — Asobi docs"},
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
                ~" / Quick start \x{2014} Godot"
            ]},
            {h1, [], [~"Quick start \x{2014} Godot"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Connect a Godot 4.x project to a running Asobi server in about five minutes. ",
                ~"Don't have a server yet? Run the ",
                {a, [{href, ~"/docs/quickstart"}, az_navigate], [~"server quickstart"]},
                ~" first."
            ]},

            {h2, [], [~"1. Install the addon"]},
            {p, [], [
                ~"Clone or copy ",
                {a, [{href, ~"https://github.com/widgrensit/asobi-godot"}], [
                    {code, [], [~"asobi-godot"]}
                ]},
                ~" into ",
                {code, [], [~"addons/asobi/"]},
                ~" inside your project, then enable it via ",
                {strong, [], [~"Project \x{2192} Project Settings \x{2192} Plugins"]},
                ~"."
            ]},

            {h2, [], [~"2. Bootstrap the client"]},
            {p, [], [~"Drop a ", {code, [], [~"Boot.gd"]}, ~" autoload:"]},
            code(
                ~"gdscript",
                ~"""
extends Node

const HOST := "localhost"
const PORT := 8080

var client: AsobiClient

func _ready() -> void:
    client = AsobiClient.new(HOST, PORT, false)  # use_ssl = false
    add_child(client)
"""
            ),

            {h2, [], [~"3. Authenticate"]},
            code(
                ~"gdscript",
                ~"""
func login() -> void:
    var auth = await client.auth.register_async("player1", "secret123", "Player One")
    if auth.error:
        push_error("auth failed: %s" % auth.error)
        return
    print("logged in as %s" % client.player_id)
"""
            ),
            {p, [], [
                ~"Auth requests are rate-limited at 5/sec per IP. Production builds should use a platform provider \x{2014} see ",
                {a, [{href, ~"/docs/security/auth"}, az_navigate], [~"Auth & rate limiting"]},
                ~"."
            ]},

            {h2, [], [~"4. Open the WebSocket and queue"]},
            code(
                ~"gdscript",
                ~"""
client.realtime.connected.connect(func(): print("ws connected"))
client.realtime.matched.connect(func(data): print("matched: %s" % data.match_id))
client.realtime.match_state.connect(func(state):
    print("tick %d, %d players" % [state.tick, state.players.size()]))

await client.realtime.connect_async()
await client.realtime.add_to_matchmaker_async("arena")
"""
            ),

            {h2, [], [~"5. Send input"]},
            code(
                ~"gdscript",
                ~"""
client.realtime.send_match_input_async(
    JSON.stringify({"action": "move", "x": 1, "y": 0}))
"""
            ),
            {p, [], [
                ~"Input is fire-and-forget. The next ",
                {code, [], [~"match_state"]},
                ~" signal will reflect the server's authoritative response."
            ]},

            {h2, [], [~"What's next"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/godot"}], [~"Full SDK reference"]}
                ]},
                {li, [], [
                    {a, [{href, ~"https://github.com/widgrensit/asobi-godot-demo"}], [
                        ~"asobi-godot-demo"
                    ]},
                    ~" \x{2014} a working arena demo."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/lua/api"}, az_navigate], [~"game.* Lua API"]},
                    ~" \x{2014} write the server-side gameplay your client connects to."
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
