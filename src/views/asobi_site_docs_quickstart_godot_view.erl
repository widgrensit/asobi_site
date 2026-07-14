-module(asobi_site_docs_quickstart_godot_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-qs-godot", title => ~"Godot quickstart — Asobi docs"},
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
                ~" / Quick start - Godot"
            ]},
            {h1, [], [~"Quick start - Godot"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Connect a Godot 4.x project to a running Asobi server in about five minutes. ",
                ~"Don't have a server yet? Run the ",
                {a, [{href, ~"/docs/quickstart"}, az_navigate], [~"server quickstart"]},
                ~" first - it gives you a backend on localhost:8084 with a ",
                {code, [], [~"default"]},
                ~" match mode, which is what this page connects to."
            ]},

            {h2, [], [~"1. Install the addon"]},
            {p, [], [
                ~"Clone or copy ",
                {a, [{href, ~"https://github.com/widgrensit/asobi-godot"}], [
                    {code, [], [~"asobi-godot"]}
                ]},
                ~" into ",
                {code, [], [~"addons/asobi/"]},
                ~", then enable it via ",
                {strong, [], [~"Project \x{2192} Project Settings \x{2192} Plugins"]},
                ~". The plugin registers an ",
                {code, [], [~"Asobi"]},
                ~" autoload for you, so you use ",
                {code, [], [~"Asobi"]},
                ~" directly from any script - you do not create a client node yourself."
            ]},

            {h2, [], [~"2. Where this code lives"]},
            {p, [], [
                ~"Put the code below on a ",
                {strong, [], [~"script attached to a node in your main scene"]},
                ~" (or your own autoload). Asobi is driven by two Godot lifecycle callbacks:"
            ]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"_ready()"]},
                    ~" - runs once when the node enters the tree. Authenticate, wire up signals, and connect here."
                ]},
                {li, [], [
                    {code, [], [~"_process(delta)"]},
                    ~" - runs every frame. Read input and send it here."
                ]}
            ]},
            {p, [], [
                ~"Realtime events arrive as Godot ",
                {strong, [], [~"signals"]},
                ~" (",
                {code, [], [~"match_matched"]},
                ~", ",
                {code, [], [~"match_state"]},
                ~", ...), each carrying a ",
                {code, [], [~"Dictionary"]},
                ~" payload. You connect them to your own handler functions."
            ]},

            {h2, [], [~"3. The complete client"]},
            {p, [], [
                ~"This is the whole flow - authenticate, connect, queue, join, receive state, send input - in one script. Each part is explained below."
            ]},
            code(
                ~"gdscript",
                ~"""
extends Node

func _ready() -> void:
    # Point the autoload at your server (matches the server quickstart).
    Asobi.host = "localhost"
    Asobi.port = 8084

    # 1. Authenticate. await the result before doing anything else - the
    #    WebSocket connects with this session.
    var resp := await Asobi.auth.register("player1", "secret123", "Player One")
    if resp.has("error"):
        push_error("auth failed: %s" % resp.error)
        return

    # 2. Wire up the signals you care about BEFORE connecting, so you don't
    #    miss the first events.
    Asobi.realtime.match_matched.connect(_on_matched)
    Asobi.realtime.match_state.connect(_on_state)

    # 3. Open the WebSocket, then queue for a match. "default" is the mode
    #    your server's match.lua registers.
    Asobi.realtime.connect_to_server()
    Asobi.realtime.add_to_matchmaker("default")

func _on_matched(payload: Dictionary) -> void:
    # The matchmaker found a match. You must join it before state flows.
    Asobi.realtime.join_match(payload["match_id"])

func _on_state(payload: Dictionary) -> void:
    # The server's authoritative tick. Update your game world from here.
    var players: Dictionary = payload.get("players", {})
    print("tick %s, %d players" % [payload.get("tick", 0), players.size()])

func _process(_delta: float) -> void:
    # Send input every frame a key is held. send_match_input takes a
    # Dictionary - no JSON encoding.
    if Input.is_action_pressed("ui_right"):
        Asobi.realtime.send_match_input({"action": "move", "x": 1, "y": 0})
"""
            ),

            {h2, [], [~"4. What each part does, and when"]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Authenticate first (in _ready). "]},
                    ~"The WebSocket authenticates with your session, so ",
                    {code, [], [~"await"]},
                    ~" the ",
                    {code, [], [~"register"]},
                    ~" (or ",
                    {code, [], [~"login"]},
                    ~") call and check ",
                    {code, [], [~"resp.has(\"error\")"]},
                    ~" before you connect. Auth is rate-limited to 5/sec per IP; production builds should use a platform provider (see ",
                    {a, [{href, ~"/docs/security/auth"}, az_navigate], [~"Auth & rate limiting"]},
                    ~")."
                ]},
                {li, [], [
                    {strong, [], [~"Connect signals before connect_to_server (in _ready). "]},
                    ~"Connect your handlers to ",
                    {code, [], [~"match_matched"]},
                    ~" and ",
                    {code, [], [~"match_state"]},
                    ~" first, then call ",
                    {code, [], [~"connect_to_server()"]},
                    ~" and ",
                    {code, [], [~"add_to_matchmaker(\"default\")"]},
                    ~". The mode string must match a mode your server registers."
                ]},
                {li, [], [
                    {strong, [], [~"Join on match_matched. "]},
                    ~"Queuing gets you matched; you then have to ",
                    {code, [], [~"join_match(payload[\"match_id\"])"]},
                    ~". Without the join, ",
                    {code, [], [~"match_state"]},
                    ~" never arrives - you sit idle after matching."
                ]},
                {li, [], [
                    {strong, [], [~"Send input from _process. "]},
                    ~"Poll ",
                    {code, [], [~"Input"]},
                    ~" and call ",
                    {code, [], [~"send_match_input(dict)"]},
                    ~" once per frame. It is fire-and-forget: the next ",
                    {code, [], [~"match_state"]},
                    ~" reflects the server's authoritative response."
                ]}
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
                    ~" - a working arena demo (login/lobby/arena scenes, bots, ",
                    {code, [], [~"_process"]},
                    ~" input)."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/lua/api"}, az_navigate], [~"game.* Lua API"]},
                    ~" - write the server-side gameplay your client connects to."
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
