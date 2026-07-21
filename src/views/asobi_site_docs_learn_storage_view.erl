-module(asobi_site_docs_learn_storage_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-learn-storage", title => ~"Storing data: the storage API - Asobi docs"},
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
                ~" / Learn / Storing data: the storage API"
            ]},
            {h1, [], [~"Storing data: the storage API"]},
            {p, [{class, ~"docs-lede"}], [
                {strong, [], [~"Goal: "]},
                ~"persist a value from your Lua game, restart the server, and read it back - without writing a line of SQL."
            ]},
            {p, [], [
                ~"Your grid dot moves while a match runs, but the moment the server stops that state is gone. This step makes it survive. You will not maintain a database to do it."
            ]},

            {h2, [], [~"The mental model"]},
            {p, [], [
                ~"You do not own a database. You do not write SQL, run migrations, or open a connection. You call a small key-value API from your Lua, and Asobi persists the value for you."
            ]},
            {p, [], [~"There are two scopes:"]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Per-player"]},
                    ~" - a value owned by one player (their best score, their unlocks)."
                ]},
                {li, [], [
                    {strong, [], [~"Shared"]},
                    ~" - one global value the whole game reads and writes (the dot's last resting position, a server-wide counter)."
                ]}
            ]},
            {p, [], [
                ~"That is the whole surface. Four calls, all under ",
                {code, [], [~"game.storage"]},
                ~":"
            ]},
            code(
                ~"lua",
                ~"""
game.storage.set(collection, key, value)              -- write shared
game.storage.get(collection, key)                     -- read shared
game.storage.player_set(player_id, collection, key, value)  -- write per-player
game.storage.player_get(player_id, collection, key)         -- read per-player
"""
            ),
            {p, [], [
                {code, [], [~"collection"]},
                ~" is a namespace you pick (e.g. ",
                {code, [], [~"\"grid\""]},
                ~"); ",
                {code, [], [~"key"]},
                ~" is a string; ",
                {code, [], [~"value"]},
                ~" is any scalar, list, or table. It is stored as JSON, so nested tables are fine. A read of an absent key returns ",
                {code, [], [~"nil"]},
                ~"."
            ]},
            {p, [], [
                ~"There is no per-match scope. A match can call ",
                {code, [], [~"game.storage.set"]},
                ~", but the value it writes is shared/global - it outlives the match. If you want data that dies with the match, keep it in the match ",
                {code, [], [~"state"]},
                ~" table (step 8); if you want it to persist, write it to storage."
            ]},

            {h2, [], [~"Persist the dot"]},
            {p, [], [
                ~"Restore the dot when a match starts, and save it as it moves. In ",
                {code, [], [~"match.lua"]},
                ~":"
            ]},
            code(
                ~"lua",
                ~"""
local W, H = 16, 16

function init(config)
  local saved = game.storage.get("grid", "dot")
  return {
    dot = saved or { x = 0, y = 0 }
  }
end

function handle_input(player_id, input, state)
  local d = state.dot
  d.x = math.max(0, math.min(W - 1, d.x + (input.move_x or 0)))
  d.y = math.max(0, math.min(H - 1, d.y + (input.move_y or 0)))

  local moves = game.storage.player_get(player_id, "grid", "moves") or 0
  game.storage.player_set(player_id, "grid", "moves", moves + 1)

  return state
end

function tick(state)
  game.storage.set("grid", "dot", state.dot)
  return state
end
"""
            ),
            {p, [], [
                ~"The client still only sends intent (",
                {code, [], [~"input.move_x"]},
                ~", ",
                {code, [], [~"input.move_y"]},
                ~" in ",
                {code, [], [~"{-1, 0, 1}"]},
                ~"); the server decides the new position, persists it, and remains the single source of truth. Nothing about this changes between Cloud and self-hosted - the Lua is identical everywhere."
            ]},

            {h2, [], [~"Where the value actually lands"]},
            {p, [], [
                ~"The game logic above is the same on both deployments. Only the database underneath differs, and you configure that once, out of band."
            ]},
            {p, [], [
                {strong, [], [~"Cloud."]},
                ~" Every environment gets its own managed Postgres database, provisioned for you when the environment is created. Connection details are injected into your deployment automatically. You never see a connection string, never run a migration, never touch the database. Deploy your bundle and storage just works."
            ]},
            {p, [], [
                {strong, [], [~"Self-hosted."]},
                ~" You bring your own Postgres (17+) and point Asobi at it. On the ",
                {code, [], [~"asobi_lua"]},
                ~" Docker image this is a handful of ",
                {code, [], [~"ASOBI_*"]},
                ~" env vars:"
            ]},
            code(
                ~"text",
                ~"""
ASOBI_DB_HOST=db
ASOBI_DB_NAME=asobi
ASOBI_DB_USER=postgres
ASOBI_DB_PASSWORD=postgres
"""
            ),
            {p, [], [
                ~"Embedding Asobi as an Erlang dependency instead? The same settings live under the ",
                {code, [], [~"kura"]},
                ~" key in ",
                {code, [], [~"sys.config"]},
                ~". Either way the schema is created and migrations run automatically on startup - you still never hand-write SQL. See the ",
                {a, [{href, ~"/docs/configuration"}, az_navigate], [~"Configuration guide"]},
                ~" for the full key list and both forms."
            ]},

            {h2, [], [~"What storage is not"]},
            {p, [], [
                ~"Two things look like storage but are separate systems - reach for them by name, not through ",
                {code, [], [~"game.storage"]},
                ~":"
            ]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Inventory and items"]},
                    ~" are their own primitive (the economy system: item definitions, per-player item instances, wallets). If you want \"the player owns 3 potions\", that is inventory, not a storage key. See the ",
                    {a, [{href, ~"/docs/economy"}, az_navigate], [~"Economy guide"]},
                    ~"."
                ]},
                {li, [], [
                    {strong, [], [~"Cloud saves"]},
                    ~" are a per-player, slotted save API over REST (",
                    {code, [], [~"GET/PUT /api/v1/saves/:slot"]},
                    ~", up to 10 slots, 256 KB each) - built for client-driven save/load of a game blob, distinct from the server-side ",
                    {code, [], [~"game.storage"]},
                    ~" calls above. See the Storage section of the ",
                    {a, [{href, ~"/docs/protocols/rest"}, az_navigate], [~"REST API guide"]},
                    ~"."
                ]}
            ]},
            {p, [], [
                ~"For persisting arbitrary server-decided progress from Lua - which is what this track needs - ",
                {code, [], [~"game.storage"]},
                ~" is the right tool."
            ]},

            checkpoint([
                {p, [], [
                    ~"Prove the value outlives the process. A Lua edit hot-reloads without dropping state, so you must restart the whole server, not just the script."
                ]},
                {ol, [], [
                    {li, [], [
                        ~"Join a match and move the dot a few times so ",
                        {code, [], [~"tick"]},
                        ~" writes it."
                    ]},
                    {li, [], [
                        ~"Restart the server:",
                        {ul, [], [
                            {li, [], [
                                {strong, [], [~"Self-hosted:"]},
                                ~" restart the container/release (e.g. ",
                                {code, [], [~"docker compose restart"]},
                                ~"). Your Postgres keeps running."
                            ]},
                            {li, [], [
                                {strong, [], [~"Cloud:"]},
                                ~" redeploy the environment. The managed database persists across deploys."
                            ]}
                        ]}
                    ]},
                    {li, [], [
                        ~"Add a temporary read at match start and log it:",
                        code(
                            ~"lua",
                            ~"""
function init(config)
  local saved = game.storage.get("grid", "dot")
  print("restored dot:", saved and saved.x, saved and saved.y)
  return { dot = saved or { x = 0, y = 0 } }
end
"""
                        )
                    ]},
                    {li, [], [
                        ~"Start a fresh match. The log shows the dot's last position from ",
                        {strong, [], [~"before"]},
                        ~" the restart, not ",
                        {code, [], [~"0, 0"]},
                        ~"."
                    ]}
                ]},
                {p, [], [
                    ~"Same experiment for per-player: ",
                    {code, [], [~"print(game.storage.player_get(player_id, \"grid\", \"moves\"))"]},
                    ~" should show the move count carried over."
                ]},
                {p, [], [
                    ~"Remove the temporary ",
                    {code, [], [~"print"]},
                    ~" once you have seen it work."
                ]}
            ]),

            nextstep(
                ~"/docs/learn/match-setup",
                ~"Step 6 - Set up a match + modes",
                ~"How config.lua maps a mode to its script, and single-mode vs multi-mode bundles."
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
