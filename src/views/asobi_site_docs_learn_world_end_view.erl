-module(asobi_site_docs_learn_world_end_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-learn-world-end", title => ~"End a world - Asobi docs"},
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
                ~" / Learn / End a world"
            ]},
            {h1, [], [~"End a world"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Goal: end your persistent arena cleanly, on the server's terms, and watch every client receive ",
                {code, [], [~"world.finished"]},
                ~"."
            ]},

            {p, [], [
                ~"An arena round was a short session that finished when the round was over. A persistent arena is always on, so it needs a rule for when it is ",
                {em, [], [~"done"]},
                ~". There are exactly two ways a persistent arena ends, and both are decided by the server."
            ]},
            {ol, [], [
                {li, [], [
                    {strong, [], [~"The game module signals a finish."]},
                    ~" Your ",
                    {code, [], [~"post_tick"]},
                    ~" sets ",
                    {code, [], [~"_finished"]},
                    ~" on the state."
                ]},
                {li, [], [
                    {strong, [], [~"The world empties out."]},
                    ~" The last player leaves and the empty-grace timer expires."
                ]}
            ]},
            {p, [], [
                ~"When either happens the server broadcasts one ",
                {code, [], [~"world.finished"]},
                ~" push to whoever is still connected, then tears the world down. The client never ends a world; it only sends intent and reacts to the broadcast."
            ]},
            {p, [], [
                ~"This is the last step of the arc. By the end of it your persistent arena starts, runs, and stops on its own."
            ]},

            {h2, [], [~"Finish from ", {code, [], [~"post_tick"]}]},
            {p, [], [
                ~"Your persistent arena already advances in ",
                {code, [], [~"post_tick(tick, state)"]},
                ~" (step 12). To end it, set ",
                {code, [], [~"_finished = true"]},
                ~" and attach a ",
                {code, [], [~"_result"]},
                ~" table. The result is arbitrary and is delivered verbatim to clients as JSON."
            ]},
            {p, [], [
                {code, [], [~"post_tick"]},
                ~" is handed the tick number every tick, so the simplest end condition is a fixed-length round: finish once the count is reached. It needs no entity state - just the counter the platform already gives you. World ticks default to 20 Hz, so 3600 ticks is three minutes."
            ]},
            code(
                ~"lua",
                ~"""
                function post_tick(tick, state)
                    if tick >= 3600 then
                        state._finished = true
                        state._result = { reason = "time_up", ticks = tick }
                    end
                    return state
                end
                """
            ),
            {p, [], [
                ~"Once ",
                {code, [], [~"_finished"]},
                ~" is set the world stops ticking and ",
                {code, [], [~"world.finished"]},
                ~" goes out with your ",
                {code, [], [~"_result"]},
                ~" as its ",
                {code, [], [~"result"]},
                ~". Swap the condition for whatever ends your world - a score cap, an objective, one team left standing - keeping the same ",
                {code, [], [~"_finished"]},
                ~"/",
                {code, [], [~"_result"]},
                ~" shape."
            ]},
            {p, [], [
                ~"The Erlang behaviour signals the same thing by returning ",
                {code, [], [~"{finished, Result, State}"]},
                ~" from ",
                {code, [], [~"post_tick/2"]},
                ~"."
            ]},
            {details, [], [
                {summary, [], [~"Erlang tab"]},
                code(
                    ~"erlang",
                    ~"""
                    post_tick(Tick, State) when Tick >= 3600 ->
                        {finished, #{reason => time_up, ticks => Tick}, State};
                    post_tick(_Tick, State) ->
                        {ok, State}.
                    """
                )
            ]},

            {h2, [], [~"Finish when the world empties"]},
            {p, [], [
                ~"You do not have to write any code for the other path. When the last player leaves, the world waits ",
                {code, [], [~"empty_grace_ms"]},
                ~" and then finishes on its own. This is a property of the ",
                {strong, [], [~"mode"]},
                ~", set as a global in ",
                {code, [], [~"world.lua"]},
                ~" alongside ",
                {code, [], [~"game_type = \"world\""]},
                ~"."
            ]},
            code(
                ~"lua",
                ~"""
                game_type = "world"
                empty_grace_ms = 5000
                """
            ),
            {p, [], [
                ~"The default is ",
                {code, [], [~"0"]},
                ~", which means finish the instant the world is empty. A few seconds of grace lets a player rejoin after a flaky connection without the world dying underneath them. Set it once in the mode script; nobody joining or leaving needs to know it exists."
            ]},
            {p, [], [
                ~"This grace value is game logic, so it lives in the same Lua global on cloud and self-hosted alike - there is nothing to configure per environment. The full mode option table (including ",
                {code, [], [~"empty_grace_ms"]},
                ~", ",
                {code, [], [~"zone_idle_timeout"]},
                ~", and ",
                {code, [], [~"snapshot_interval"]},
                ~") is in the ",
                {a, [{href, ~"/docs/world-server"}, az_navigate], [~"world-server"]},
                ~" reference."
            ]},

            {h2, [], [~"The client just listens"]},
            {p, [], [
                ~"Ending is entirely server-side, so there is no new client call to send. The one thing each client must do is register a ",
                {code, [], [~"world.finished"]},
                ~" handler so it can react - show a result screen, return to a lobby, disconnect. Register it before joining, the same rule as every other world push. The ",
                {code, [], [~"world.finished"]},
                ~" handler is the same SDK pattern you used for ",
                {code, [], [~"world.tick"]},
                ~" in ",
                {a, [{href, ~"/docs/learn/world-run"}, az_navigate], [~"Run a world"]},
                ~"."
            ]},
            {p, [], [~"The payload is:"]},
            code(
                ~"json",
                ~"""
                {"type": "world.finished", "payload": {"world_id": "...", "result": {"reason": "time_up", "ticks": 3600}}}
                """
            ),
            {p, [], [
                {code, [], [~"result"]},
                ~" is exactly the ",
                {code, [], [~"_result"]},
                ~" table you set in ",
                {code, [], [~"post_tick"]},
                ~". When the world ended by empty-grace instead, ",
                {code, [], [~"result"]},
                ~" is whatever the server sends for that path - do not rely on your own fields being present. Handle a ",
                {code, [], [~"world.finished"]},
                ~" with an empty result too."
            ]},
            {p, [], [
                ~"Registering the handler is identical across every SDK apart from the base server URL, so it is written once here rather than in per-SDK tabs. The event name and payload shape are the same everywhere; see the ",
                {a, [{href, ~"/docs/protocols/websocket"}, az_navigate], [~"websocket-protocol"]},
                ~" reference for the wire format."
            ]},

            checkpoint([
                {p, [], [~"Prove both endings."]},
                {p, [], [
                    {strong, [], [~"The ", {code, [], [~"post_tick"]}, ~" finish:"]}
                ]},
                {ol, [], [
                    {li, [], [
                        ~"Boot the server (",
                        {code, [], [~"asobi dev"]},
                        ~" locally, or your deployed environment)."
                    ]},
                    {li, [], [
                        ~"Join the arena from a client with a ",
                        {code, [], [~"world.finished"]},
                        ~" handler registered."
                    ]},
                    {li, [], [
                        ~"Let the world run to the tick limit (lower the constant to end it sooner)."
                    ]},
                    {li, [], [
                        ~"The client logs ",
                        {code, [], [~"world.finished"]},
                        ~" with ",
                        {code, [], [~"result.reason = \"time_up\""]},
                        ~"."
                    ]}
                ]},
                {p, [], [
                    {strong, [], [~"The empty-grace finish:"]}
                ]},
                {ol, [], [
                    {li, [], [
                        ~"Set ",
                        {code, [], [~"empty_grace_ms = 3000"]},
                        ~" in ",
                        {code, [], [~"world.lua"]},
                        ~" and rejoin."
                    ]},
                    {li, [], [
                        ~"Leave the world (",
                        {code, [], [~"world.leave"]},
                        ~", or just disconnect)."
                    ]},
                    {li, [], [
                        ~"After three seconds the world finishes; a second client still connected receives ",
                        {code, [], [~"world.finished"]},
                        ~"."
                    ]},
                    {li, [], [
                        ~"Re-run ",
                        {code, [], [~"world.list"]},
                        ~" - the world is gone."
                    ]}
                ]},
                {p, [], [
                    ~"If both endings fire and the world disappears from the list, the persistent arena ends cleanly. That is the whole loop: create, join, run, end. You have a working arena backend."
                ]}
            ]),

            nextstep(
                ~"/docs/learn/where-next",
                ~"Where next",
                ~"You have built a backend end to end - identity, storage, matches, and worlds. Everything left off the linear path (chat, voting, matchmaking, IAP, presence, notifications) hands you to the reference guides."
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
