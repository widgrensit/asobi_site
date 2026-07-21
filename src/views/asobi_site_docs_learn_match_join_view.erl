-module(asobi_site_docs_learn_match_join_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-learn-match-join", title => ~"Connect to a match - Asobi docs"},
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
                ~" / Learn / Connect to a match"
            ]},
            {h1, [], [~"Connect to a match"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Get two clients into the same match, so the next step has somewhere to move the dot."
            ]},

            {p, [], [
                ~"In ",
                {a, [{href, ~"/docs/learn/match-setup"}, az_navigate], [~"step 6"]},
                ~" you gave your grid a mode and confirmed a match can be created. A match is an ephemeral session. A client does not own it: the client sends the intent to join, the server binds the match to that session, and from then on the server routes that client's input and broadcasts state to it."
            ]},
            {p, [], [~"There are two ways a client ends up in a match."]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Direct join. "]},
                    ~"The client already holds a ",
                    {code, [], [~"match_id"]},
                    ~" (from browsing joinable matches, an invite, or a shared code) and asks to join it."
                ]},
                {li, [], [
                    {strong, [], [~"Matchmaker-formed. "]},
                    ~"The client enqueues for a mode, the server pairs it with others, creates the match, and places every paired client into it. No explicit join follows: the server pushes a \"matched\" event carrying the shared ",
                    {code, [], [~"match_id"]},
                    ~", and state starts flowing."
                ]}
            ]},
            {p, [], [
                ~"Both reach your game's ",
                {code, [], [~"join"]},
                ~" callback (step 6). This page is client-side; the game logic does not change."
            ]},

            {h2, [], [~"The one rule: register the state handler before you join"]},
            {p, [], [
                ~"The server can start pushing ",
                {code, [], [~"match.state"]},
                ~" (and, on the matchmaker path, the matched event) the instant you are in the match. If you register your receive handler ",
                {em, [], [~"after"]},
                ~" joining, you race the server and drop the first frames. Register first, join second, every SDK."
            ]},

            {h2, [], [~"Cloud vs self-hosted: identical here"]},
            {p, [], [
                ~"Every call below is the same whether you deploy to Asobi Cloud or self-host. The only difference is the base server URL you configured when you built the client back in ",
                {a, [{href, ~"/docs/learn/install-sdk"}, az_navigate], [~"step 2"]},
                ~": a ",
                {code, [], [~"console.asobi.dev"]},
                ~" environment URL for cloud, your own ",
                {code, [], [~"host:8084"]},
                ~" for self-hosted. Joining is WebSocket-only by design; there is no REST join. The wire reference is ",
                {a, [{href, ~"/docs/protocols/websocket"}, az_navigate], [
                    ~"WebSocket protocol -> Matches"
                ]},
                ~"; the per-language mapping is ",
                {a, [{href, ~"/docs/protocols/websocket"}, az_navigate], [~"Realtime API"]},
                ~". For the matchmaker itself see ",
                {a, [{href, ~"/docs/matchmaking"}, az_navigate], [~"Matchmaking"]},
                ~"."
            ]},
            {p, [], [
                ~"Assume you have already connected and authenticated (steps 3-4). ",
                {code, [], [~"mode"]},
                ~" is the grid mode from step 6."
            ]},

            {p, [], [
                {strong, [], [~"Defold. "]},
                {code, [], [~"rt = client.realtime"]},
                ~". Callbacks register with ",
                {code, [], [~"rt:on(event, fn)"]},
                ~", using the SDK's mapped event names. Register before joining. Install/auth: ",
                {code, [], [~"asobi-defold"]},
                ~" README."
            ]},
            {p, [], [
                {strong, [], [~"Godot. "]},
                ~"Realtime is the ",
                {code, [], [~"Asobi.realtime"]},
                ~" autoload; you receive on Godot signals. Wire the signals before connecting or enqueuing. Install/auth: ",
                {code, [], [~"asobi-godot"]},
                ~" README."
            ]},
            {p, [], [
                {strong, [], [~"Unity. "]},
                ~"Subscribe to the C# events with ",
                {code, [], [~"+="]},
                ~"; handlers receive the raw JSON envelope string and you parse it yourself. Subscribe before you await the join. The matched member is ",
                {code, [], [~"OnMatchmakerMatched"]},
                ~" (it carries the wire ",
                {code, [], [~"match.matched"]},
                ~"). Install/auth: ",
                {code, [], [~"asobi-unity"]},
                ~" README."
            ]},
            {p, [], [
                {strong, [], [~"Unreal. "]},
                ~"Bind the dynamic multicast delegates on ",
                {code, [], [~"UAsobiWebSocket"]},
                ~"; each handler must be a ",
                {code, [], [~"UFUNCTION"]},
                ~" and receives a raw JSON string. Bind before joining. Handler signature: ",
                {code, [], [~"void OnState(const FString& StateJson)"]},
                ~". Direct joins surface on ",
                {code, [], [~"OnMatchJoined"]},
                ~"; a matchmade placement surfaces on ",
                {code, [], [~"OnMatchMatched"]},
                ~". Bind whichever path you use. Install/auth: ",
                {code, [], [~"asobi-unreal"]},
                ~" README."
            ]},
            {p, [], [
                {strong, [], [~"Dart/Flame. "]},
                ~"Realtime exposes broadcast streams; listen with ",
                {code, [], [~".stream.listen(...)"]},
                ~". Payloads are typed. Attach the listeners before you join. Install/auth: ",
                {code, [], [~"asobi-dart"]},
                ~" README."
            ]},
            {p, [], [
                {strong, [], [~"JavaScript. "]},
                ~"The transport is ",
                {code, [], [~"asobi.websocket({token})"]},
                ~"; there is no ",
                {code, [], [~"client.realtime"]},
                ~". Events use raw wire names (dots). ",
                {code, [], [~"send"]},
                ~" is an awaited RPC; ",
                {code, [], [~"sendFire"]},
                ~" is fire-and-forget. Register the handler before joining. Install/auth: ",
                {code, [], [~"asobi-js"]},
                ~" README."
            ]},
            {p, [], [
                {strong, [], [~"LOVE. "]},
                {code, [], [~"client.realtime"]},
                ~", colon syntax, mapped event names. Register with ",
                {code, [], [~":on(event, fn)"]},
                ~" before joining. LOVE has a manual pump: call ",
                {code, [], [~"client.realtime:update()"]},
                ~" every frame from ",
                {code, [], [~"love.update(dt)"]},
                ~" or no callbacks fire. Install/auth: ",
                {code, [], [~"asobi-love2d"]},
                ~" README."
            ]},

            ?stateless(asobi_site_tabbed_code, render, #{
                id => ~"learn-match-join",
                tabs => [
                    #{
                        label => ~"Defold",
                        lang => ~"lua",
                        body =>
                            ~"""
                        rt:on("match_state", function(state) end)
                        rt:on("match_matched", function(payload) end)

                        rt:join_match(match_id)          -- direct join

                        rt:add_to_matchmaker(mode)       -- matchmaker path; match_matched fires with the match_id
                        """
                    },
                    #{
                        label => ~"Godot",
                        lang => ~"gdscript",
                        body =>
                            ~"""
                        Asobi.realtime.match_state.connect(_on_state)
                        Asobi.realtime.match_matched.connect(_on_matched)

                        Asobi.realtime.join_match(match_id)          # direct join

                        Asobi.realtime.add_to_matchmaker(mode)       # matchmaker path

                        func _on_state(payload: Dictionary) -> void: pass
                        func _on_matched(payload: Dictionary) -> void: pass
                        """
                    },
                    #{
                        label => ~"Unity",
                        lang => ~"csharp",
                        body =>
                            ~"""
                        client.Realtime.OnMatchState += rawJson => { /* parse */ };
                        client.Realtime.OnMatchmakerMatched += rawJson => { /* parse */ };

                        await client.Realtime.JoinMatchAsync(matchId);            // direct join

                        await client.Realtime.AddToMatchmakerAsync(mode);         // matchmaker path
                        """
                    },
                    #{
                        label => ~"Unreal",
                        lang => ~"cpp",
                        body =>
                            ~"""
                        WebSocket->OnMatchState.AddDynamic(this, &UMyClass::OnState);
                        WebSocket->OnMatchMatched.AddDynamic(this, &UMyClass::OnMatched);

                        WebSocket->JoinMatch(MatchId);                            // direct join

                        // matchmaker path: enqueue via UAsobiMatchmaker, then OnMatchMatched fires
                        Matchmaker->Add(Mode, Party, OnResponse);
                        """
                    },
                    #{
                        label => ~"Dart/Flame",
                        lang => ~"dart",
                        body =>
                            ~"""
                        client.realtime.onMatchState.stream.listen((MatchState state) {});
                        client.realtime.onMatchmakerMatched.stream.listen((MatchmakerMatch m) {});

                        await client.realtime.joinMatch(matchId);                 // direct join

                        await client.realtime.addToMatchmaker(mode: mode);        // matchmaker path
                        """
                    },
                    #{
                        label => ~"JavaScript",
                        lang => ~"typescript",
                        body =>
                            ~"""
                        ws.on("match.state", (payload) => {});
                        ws.on("match.matched", (payload) => {});

                        const reply = await ws.send("match.join", { match_id });   // direct join, awaited

                        await ws.send("matchmaker.add", { mode });                 // matchmaker path
                        """
                    },
                    #{
                        label => ~"LOVE",
                        lang => ~"lua",
                        body =>
                            ~"""
                        client.realtime:on("match_state", function(state) end)
                        client.realtime:on("match_matched", function(payload) end)

                        client.realtime:join_match(match_id)          -- direct join

                        client.realtime:add_to_matchmaker(mode)       -- matchmaker path

                        function love.update(dt)
                          client.realtime:update()
                        end
                        """
                    }
                ]
            }),

            checkpoint([
                {p, [], [
                    ~"Run two clients against the same server. In each, register the matched handler, then enqueue both for the grid mode:"
                ]},
                {ul, [], [
                    {li, [], [~"client A: ", {code, [], [~"add_to_matchmaker(mode)"]}]},
                    {li, [], [~"client B: ", {code, [], [~"add_to_matchmaker(mode)"]}]}
                ]},
                {p, [], [
                    ~"The server pairs them, creates one match, and pushes the matched event to both. Log the ",
                    {code, [], [~"match_id"]},
                    ~" from each. You have connected to a match when ",
                    {strong, [], [~"both clients print the same "]},
                    {code, [], [~"match_id"]},
                    ~" and each starts receiving ",
                    {code, [], [~"match_state"]},
                    ~". If only one logs, or the ids differ, you registered the handler after enqueuing: move it before."
                ]}
            ]),

            nextstep(
                ~"/docs/learn/match-run",
                ~"Step 8 - Run a match",
                ~"Send an input from one client, the server moves the dot, and the new match.state renders on both."
            )
        ]}
    ).

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
