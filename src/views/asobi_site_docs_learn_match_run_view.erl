-module(asobi_site_docs_learn_match_run_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-learn-match-run", title => ~"Run a match - Asobi docs"},
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
                ~" / Learn / Run a match"
            ]},
            {h1, [], [~"Run a match: the input and state loop"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Goal: close the loop - a click on one client moves your fighter, and every client in the arena round sees it move."
            ]},

            {p, [], [
                ~"This is the payoff. You have two clients in one arena round (step 7). Now wire the loop:"
            ]},
            {ol, [], [
                {li, [], [~"Client sends intent with ", {code, [], [~"send_match_input"]}, ~"."]},
                {li, [], [
                    ~"Server (", {code, [], [~"match.lua"]}, ~") decides and moves your fighter."
                ]},
                {li, [], [
                    ~"Server broadcasts the new state as ", {code, [], [~"match.state"]}, ~"."
                ]},
                {li, [], [~"Every client renders it."]}
            ]},
            {p, [], [
                ~"The client never moves your fighter itself. It asks; the server decides; the server tells everyone. See the ",
                {a, [{href, ~"/docs/protocols/websocket"}, az_navigate], [~"websocket-protocol"]},
                ~" guide for the full ",
                {code, [], [~"match.*"]},
                ~" wire contract."
            ]},

            {h2, [], [~"The server tick (Lua)"]},
            {p, [], [
                ~"This is identical on Cloud and self-hosted - it is your game bundle, and the bundle does not change between deployments. Write it once."
            ]},
            {p, [], [
                ~"Your fighter lives in match state. ",
                {code, [], [~"handle_input"]},
                ~" applies a move intent. ",
                {code, [], [~"get_state"]},
                ~" is the per-player view that the server pushes as ",
                {code, [], [~"match.state"]},
                ~" every tick (matches run at 10 Hz by default)."
            ]},
            code(
                ~"lua",
                ~"""
                guest_auth = true

                local W, H = 16, 16

                function init(config)
                    return { fighter = { x = 8, y = 8 } }
                end

                function join(player_id, state)
                    return state
                end

                function leave(player_id, state)
                    return state
                end

                function handle_input(player_id, input, state)
                    local d = state.fighter
                    d.x = math.max(0, math.min(W - 1, d.x + (input.move_x or 0)))
                    d.y = math.max(0, math.min(H - 1, d.y + (input.move_y or 0)))
                    return state
                end

                function tick(state)
                    return state
                end

                function get_state(player_id, state)
                    return { arena_w = W, arena_h = H, fighter = state.fighter }
                end
                """
            ),
            {p, [], [
                ~"The client sends ",
                {code, [], [~"{ move_x = 1, move_y = 0 }"]},
                ~"; the server clamps it to the arena and moves your fighter. The arena is 16 by 16. Nothing about position is trusted from the client. Callback shapes are documented in the ",
                {a, [{href, ~"/docs/lua/callbacks"}, az_navigate], [~"lua-scripting"]},
                ~" guide."
            ]},
            {p, [], [
                ~"Hot-reload picks up edits to this file between ticks, so you can tweak the movement rule without restarting."
            ]},

            {h2, [], [~"The client (send + receive)"]},
            {p, [], [
                ~"Every SDK does the same two things: register the ",
                {code, [], [~"match.state"]},
                ~" handler, then send input on a click. Register the state handler BEFORE you join - a state push can arrive the instant you are in, and a handler set afterwards misses it."
            ]},
            {p, [], [
                ~"Connect and join were done in steps 3 and 7; only the base server URL differs between Cloud and self-hosted, and you set that once when you construct the client. The calls below are otherwise identical on both."
            ]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Cloud: "]},
                    ~"base URL is your environment URL from console.asobi.dev."
                ]},
                {li, [], [
                    {strong, [], [~"Self-hosted: "]},
                    ~"base URL is your own host on port 8084."
                ]}
            ]},
            {p, [], [
                ~"Send one input per click, mapping the click direction to ",
                {code, [], [~"move_x"]},
                ~" / ",
                {code, [], [~"move_y"]},
                ~" in ",
                {code, [], [~"{-1, 0, 1}"]},
                ~"."
            ]},

            {p, [], [
                {strong, [], [~"Unity: "]},
                {code, [], [~"OnMatchState"]},
                ~" hands you the raw JSON envelope string; parse it yourself. ",
                {code, [], [~"SendMatchInputAsync"]},
                ~" takes a JSON string and is fire-and-forget."
            ]},
            {p, [], [
                {strong, [], [~"Unreal: "]},
                ~"Bind the delegate before ",
                {code, [], [~"JoinMatch"]},
                ~". The handler must be a ",
                {code, [], [~"UFUNCTION"]},
                ~" and receives the raw JSON string."
            ]},
            {p, [], [
                {strong, [], [~"Dart/Flame: "]},
                {code, [], [~"onMatchState"]},
                ~" is a broadcast stream of typed ",
                {code, [], [~"MatchState"]},
                ~" payloads. ",
                {code, [], [~"sendMatchInput"]},
                ~" is fire-and-forget; do not await it."
            ]},
            {p, [], [
                {strong, [], [~"JavaScript: "]},
                ~"The JS client uses raw wire names. Join is an awaited RPC (",
                {code, [], [~"send"]},
                ~"); input is fire-and-forget (",
                {code, [], [~"sendFire"]},
                ~") and must NOT be awaited."
            ]},
            {p, [], [
                {strong, [], [~"LOVE: "]},
                ~"Mapped callback names, and a manual pump: ",
                {code, [], [~"client.realtime:update()"]},
                ~" must run every frame or no callbacks fire."
            ]},

            ?stateless(asobi_site_tabbed_code, render, #{
                id => ~"learn-match-run",
                tabs => [
                    #{
                        label => ~"Defold",
                        lang => ~"lua",
                        body =>
                            ~"""
                            local rt = client.realtime

                            rt:on("match_state", function(state)
                                render(state.fighter)
                            end)

                            rt:join_match(match_id)

                            -- on a click
                            rt:send_match_input({ move_x = 1, move_y = 0 })
                            """
                    },
                    #{
                        label => ~"Godot",
                        lang => ~"gdscript",
                        body =>
                            ~"""
                            Asobi.realtime.match_state.connect(_on_state)
                            Asobi.realtime.join_match(match_id)

                            func _on_state(payload: Dictionary) -> void:
                                render(payload["fighter"])

                            # on a click
                            Asobi.realtime.send_match_input({ "move_x": 1, "move_y": 0 })
                            """
                    },
                    #{
                        label => ~"Unity",
                        lang => ~"csharp",
                        body =>
                            ~"""
                            client.Realtime.OnMatchState += rawJson =>
                            {
                                var state = JsonUtility.FromJson<GridState>(rawJson);
                                Render(state.fighter);
                            };

                            await client.Realtime.JoinMatchAsync(matchId);

                            // on a click
                            await client.Realtime.SendMatchInputAsync("{\"move_x\":1,\"move_y\":0}");
                            """
                    },
                    #{
                        label => ~"Unreal",
                        lang => ~"cpp",
                        body =>
                            ~"""
                            WebSocket->OnMatchState.AddDynamic(this, &UMyClass::HandleMatchState);
                            WebSocket->JoinMatch(MatchId);

                            // UFUNCTION handler
                            void UMyClass::HandleMatchState(const FString& StateJson)
                            {
                                Render(StateJson);
                            }

                            // on a click
                            WebSocket->SendMatchInput(TEXT("{\"move_x\":1,\"move_y\":0}"));
                            """
                    },
                    #{
                        label => ~"Dart/Flame",
                        lang => ~"dart",
                        body =>
                            ~"""
                            client.realtime.onMatchState.stream.listen((MatchState state) {
                              render(state);
                            });

                            await client.realtime.joinMatch(matchId);

                            // on a tap
                            client.realtime.sendMatchInput({'move_x': 1, 'move_y': 0});
                            """
                    },
                    #{
                        label => ~"JavaScript",
                        lang => ~"typescript",
                        body =>
                            ~"""
                            ws.on("match.state", (payload) => {
                              render(payload.fighter);
                            });

                            await ws.send("match.join", { match_id });

                            // on a click
                            ws.sendFire("match.input", { data: { move_x: 1, move_y: 0 } });
                            """
                    },
                    #{
                        label => ~"LÖVE",
                        lang => ~"lua",
                        body =>
                            ~"""
                            client.realtime:on("match_state", function(state)
                                render(state.fighter)
                            end)

                            client.realtime:join_match(match_id)

                            -- on a click
                            client.realtime:send_match_input({ move_x = 1, move_y = 0 })

                            function love.update(dt)
                                client.realtime:update()
                            end
                            """
                    }
                ]
            }),

            checkpoint([
                {p, [], [~"Run two clients joined to the same arena round."]},
                {ol, [], [
                    {li, [], [~"Click a direction on client A."]},
                    {li, [], [
                        ~"Client A sends ",
                        {code, [], [~"send_match_input"]},
                        ~"; the server moves your fighter and broadcasts ",
                        {code, [], [~"match.state"]},
                        ~"."
                    ]},
                    {li, [], [~"Your fighter moves on BOTH client A and client B."]}
                ]},
                {p, [], [
                    ~"If it moves on A but not B, both clients are not in the same arena round - recheck step 7. If it moves on neither, the state handler was registered after join, or (LOVE) the per-frame ",
                    {code, [], [~"update()"]},
                    ~" pump is missing."
                ]}
            ]),

            nextstep(
                ~"/docs/learn/match-end",
                ~"Step 9 - End a match",
                ~"signal _finished with a result table and receive match.finished on every client."
            )
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).

checkpoint(Children) ->
    ?html(
        {'div', [{class, ~"docs-callout docs-callout-success"}], [
            {p, [], [{strong, [], [~"Checkpoint"]}]} | Children
        ]}
    ).

nextstep(Href, Label, Blurb) ->
    ?html(
        {'div', [{class, ~"docs-next"}], [
            {p, [], [
                {strong, [], [~"Next: "]},
                {a, [{href, Href}, az_navigate], [Label]}
            ]},
            {p, [], [Blurb]}
        ]}
    ).
