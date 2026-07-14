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
                ~" / Quick start - Defold"
            ]},
            {h1, [], [~"Quick start - Defold"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Connect a Defold project to a running Asobi server in about five minutes. ",
                ~"Don't have a server yet? Run the ",
                {a, [{href, ~"/docs/quickstart"}, az_navigate], [~"server quickstart"]},
                ~" first - it gives you a backend on localhost:8084 with a ",
                {code, [], [~"default"]},
                ~" match mode, which is what this page connects to."
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
https://github.com/widgrensit/asobi-defold/archive/refs/tags/v1.2.1.zip
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

            {h2, [], [~"2. Where this code lives"]},
            {p, [], [
                ~"Put this on a ",
                {code, [], [~".script"]},
                ~" attached to a game object that lives for the whole app - a script in your ",
                {code, [], [~"main.collection"]},
                ~", ",
                {strong, [], [~"not"]},
                ~" a ",
                {code, [], [~"gui_script"]},
                ~". Defold invalidates the WebSocket callbacks when their owning script is unloaded, so a short-lived script drops your connection. Add ",
                {code, [], [~"main/boot.script"]},
                ~" and assign it to a game object in your main collection. It uses two Defold callbacks:"
            ]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"init(self)"]},
                    ~" - runs once. Authenticate, wire up realtime handlers, and connect here."
                ]},
                {li, [], [
                    {code, [], [~"on_input(self, action_id, action)"]},
                    ~" - runs when a bound input fires. Send match input here."
                ]}
            ]},

            {h2, [], [~"3. The complete boot.script"]},
            {p, [], [
                ~"The whole flow - authenticate, connect, queue, join, receive state, send input - in one script. Note how everything after auth is nested ",
                {strong, [], [~"inside the register callback"]},
                ~": that is what keeps connect from racing ahead of your session."
            ]},
            code(
                ~"lua",
                ~"""
local asobi = require("asobi.client")

function init(self)
    -- Route input to this script's on_input (needs an input binding too).
    msg.post(".", "acquire_input_focus")

    -- Local engine: host, port. Use (host, 443, true) for a hosted env over SSL.
    self.client = asobi.create("localhost", 8084)

    -- Authenticate first. Everything else happens inside this callback,
    -- once you actually have a session. The callback gets (data, err).
    self.client.auth.register(self.client, "player1", "secret123", nil,
        function(data, err)
            if err then print("auth failed: " .. tostring(err.error)) return end

            -- A match was formed. Join it before state starts flowing.
            self.client.realtime:on("match_matched", function(payload)
                self.client.realtime:join_match(payload.match_id)
            end)

            -- The server's authoritative tick. Update your game world here.
            self.client.realtime:on("match_state", function(state)
                -- e.g. move your player game objects from state
            end)

            -- connect() authenticates asynchronously; wait for "connected"
            -- before queuing, or the queue races ahead of the session.
            self.client.realtime:on("connected", function()
                self.client.realtime:add_to_matchmaker("default")
            end)

            self.client.realtime:connect()
        end)
end

function on_input(self, action_id, action)
    -- Fires when a bound action changes. send_match_input is fire-and-forget.
    if action_id == hash("right") and (action.pressed or action.repeated) then
        self.client.realtime:send_match_input({action = "move", x = 1, y = 0})
    end
end
"""
            ),

            {h2, [], [~"4. What each part does, and when"]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Authenticate first (in init). "]},
                    ~"The client is the first argument to every API call. Nest the rest inside the ",
                    {code, [], [~"register"]},
                    ~" callback so it only runs once you have a session. Auth is rate-limited to 5/sec per IP; production builds should use a platform provider (see ",
                    {a, [{href, ~"/docs/security/auth"}, az_navigate], [~"Auth & rate limiting"]},
                    ~")."
                ]},
                {li, [], [
                    {strong, [], [~"Queue only after \"connected\". "]},
                    {code, [], [~"connect()"]},
                    ~" authenticates asynchronously, so wait for the ",
                    {code, [], [~"connected"]},
                    ~" event before ",
                    {code, [], [~"add_to_matchmaker(\"default\")"]},
                    ~". The mode string must match a mode your server registers."
                ]},
                {li, [], [
                    {strong, [], [~"Join on match_matched. "]},
                    ~"Queuing gets you matched; you then ",
                    {code, [], [~"join_match(payload.match_id)"]},
                    ~". Without the join, ",
                    {code, [], [~"match_state"]},
                    ~" never arrives."
                ]},
                {li, [], [
                    {strong, [], [~"Send input from on_input. "]},
                    {code, [], [~"init"]},
                    ~" calls ",
                    {code, [], [~"acquire_input_focus"]},
                    ~" so this script receives input; bind the ",
                    {code, [], [~"right"]},
                    ~" action in ",
                    {strong, [], [~"game.input_binding"]},
                    ~". The next ",
                    {code, [], [~"match_state"]},
                    ~" reflects the server's authoritative response."
                ]}
            ]},

            {h2, [], [~"What's next"]},
            {ul, [], [
                {li, [], [{a, [{href, ~"/defold"}], [~"Full SDK reference"]}]},
                {li, [], [
                    {a, [{href, ~"https://github.com/widgrensit/asobi-defold-demo"}], [
                        ~"asobi-defold-demo"
                    ]},
                    ~" - a working arena demo."
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
