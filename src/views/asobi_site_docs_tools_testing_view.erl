-module(asobi_site_docs_tools_testing_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-tools-testing", title => ~"Testing — Asobi docs"},
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
                ~" / Testing"
            ]},
            {h1, [], [~"Testing a client against Asobi"]},
            {p, [{class, ~"docs-lede"}], [
                ~"If you're building or maintaining a client - an SDK, a custom integration, a bot - the ",
                {strong, [], [~"asobi-test-harness"]},
                ~" gives you a fixed, known-good backend to test the wire protocol against, so protocol ",
                ~"drift breaks exactly one test in one place."
            ]},

            {h2, [], [~"What it is"]},
            {p, [], [
                ~"A minimal, deterministic Asobi backend for CI: a Docker Compose stack (Postgres plus ",
                {code, [], [~"ghcr.io/widgrensit/asobi_lua:latest"]},
                ~") running two tiny Lua fixtures - a ",
                {code, [], [~"smoke"]},
                ~" match mode and a ",
                {code, [], [~"smoke_world"]},
                ~" world mode. Every client SDK runs the same canonical scenarios against it, so there is ",
                ~"one source of truth for how a correct client behaves."
            ]},

            {h2, [], [~"Run it"]},
            code(
                ~"bash",
                ~"""
git clone https://github.com/widgrensit/asobi-test-harness
cd asobi-test-harness
docker compose up -d               # backend on http://localhost:8080

# point your SDK's smoke test at it, then tear down
ASOBI_URL=http://localhost:8080 ./smoke_tests/run.sh
docker compose down -v
"""
            ),
            {p, [], [
                ~"Client smoke tests read the backend URL from ",
                {code, [], [~"ASOBI_URL"]},
                ~" (default ",
                {code, [], [~"http://localhost:8080"]},
                ~"), run the scenarios in ",
                {code, [], [~"scenarios/canonical.md"]},
                ~" in order, and exit non-zero on the first mismatch - the reference implementation is ",
                {code, [], [~"asobi-js/smoke_tests/"]},
                ~"."
            ]},

            {h2, [], [~"What the scenarios assert"]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Connect + auth: "]},
                    ~"register over REST, open the WS, ",
                    {code, [], [~"session.connect {token}"]},
                    ~" -> ",
                    {code, [], [~"session.connected"]},
                    ~", and the connected ",
                    {code, [], [~"player_id"]},
                    ~" matches the REST one."
                ]},
                {li, [], [
                    {strong, [], [~"Matchmaking: "]},
                    ~"two clients ",
                    {code, [], [~"matchmaker.add {mode:\"smoke\"}"]},
                    ~" both reach ",
                    {code, [], [~"match.matched"]},
                    ~" with the same ",
                    {code, [], [~"match_id"]},
                    ~" (and it's ",
                    {code, [], [~"match.matched"]},
                    ~", not ",
                    {code, [], [~"match.joined"]},
                    ~")."
                ]},
                {li, [], [
                    {strong, [], [~"Input -> state: "]},
                    ~"a ",
                    {code, [], [~"match.input"]},
                    ~" produces a ",
                    {code, [], [~"match.state"]},
                    ~" reflecting the move."
                ]},
                {li, [], [
                    {strong, [], [~"World fanout: "]},
                    ~"join a world, send ",
                    {code, [], [~"world.input"]},
                    ~", and every subscribed client sees the ",
                    {code, [], [~"world.tick"]},
                    ~" deltas (the add/update/remove ops)."
                ]}
            ]},

            {h2, [], [~"Server-side fanout suite"]},
            {p, [], [
                ~"The repo also ships an Erlang PropEr/Common Test suite (",
                {code, [], [~"cd multiplayer_ct && rebar3 ct"]},
                ~") that drives N concurrent fake clients into one world and asserts every player's move ",
                ~"reaches every other subscribed client - catching \"applied server-side but never ",
                ~"broadcast\" regressions. It brings the harness up and down itself."
            ]},

            {h2, [], [~"What's next"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/protocols/websocket"}, az_navigate], [
                        ~"WebSocket protocol"
                    ]},
                    ~" - the messages the scenarios exercise."
                ]},
                {li, [], [{a, [{href, ~"/docs/protocols/rest"}, az_navigate], [~"REST API"]}]},
                {li, [], [
                    {a, [{href, ~"/docs/tools/dev"}, az_navigate], [~"asobi dev"]},
                    ~" - a local backend for interactive testing."
                ]}
            ]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
