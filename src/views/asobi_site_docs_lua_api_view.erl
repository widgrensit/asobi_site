-module(asobi_site_docs_lua_api_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"docs-lua-api", title => ~"Lua API — Asobi docs"}, Bindings), #{}}.

-spec render(map()) -> term().
render(_Bindings) ->
    Content = ?html({'div', [], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}], [~"Docs"]},
            ~" / Lua / ",
            {code, [], [~"game.*"]},
            ~" API"
        ]},
        {h1, [], [~"Lua API reference"]},
        {p, [{class, ~"docs-lede"}], [
            ~"The ",
            {code, [], [~"game"]},
            ~" global is available in every Lua module loaded by Asobi. ",
            ~"It gives your scripts controlled access to the engine runtime \x{2014} broadcasting, persistence, leaderboards, spatial queries, and more."
        ]},

        {'div', [{class, ~"docs-callout"}], [
            {p, [], [
                {strong, [], [~"Sandbox: "]},
                ~"Lua scripts run in a Luerl sandbox. They cannot open files, start processes, or call system APIs. ",
                ~"Everything the runtime needs to expose goes through ",
                {code, [], [~"game.*"]},
                ~"."
            ]}
        ]},

        %% ---- Messaging ----
        {h2, [], [~"Messaging"]},

        api(~"game.broadcast(event, payload)",
            ~"Broadcast an event to every subscribed player in the current match or zone.",
            ~"lua",
            ~"""
game.broadcast("round_over", { winner = "p_alice", duration = 42 })
"""),

        api(~"game.send(player_id, message)",
            ~"Send a message to a specific player.",
            ~"lua",
            ~"""
game.send(player_id, { kind = "damage", amount = 12, from = attacker_id })
"""),

        %% ---- Identity ----
        {h2, [], [~"Identity"]},

        api(~"game.id()",
            ~"Generate a new UUIDv7 (time-ordered, collision-resistant).",
            ~"lua",
            ~"""
local match_id = game.id()
"""),

        %% ---- Chat ----
        {h2, [], [~"Chat"]},

        api(~"game.chat.send(channel_id, sender_id, content)",
            ~"Send a chat message on a channel. The channel must exist; create channels via the game mode config or world lobby.",
            ~"lua",
            ~"""
game.chat.send("world:main", player_id, "gg")
"""),

        %% ---- Notifications ----
        {h2, [], [~"Notifications"]},

        api(~"game.notify(player_id, type, subject, data)",
            ~"Send a notification to one player. Persisted until read.",
            ~"lua",
            ~"""
game.notify(winner_id, "match_ended", "You won!", { prize_id = "trophy_bronze" })
"""),

        api(~"game.notify_many(player_ids, type, subject, data)",
            ~"Same as above, fan-out to multiple players. Uses the background notification broadcaster so it does not block the match tick.",
            ~"lua",
            ~"""
game.notify_many(tournament_players, "bracket_advance", "Round 2 starting", {
  match_at = os.time() + 300
})
"""),

        %% ---- Storage ----
        {h2, [], [~"Storage"]},

        api(~"game.storage.get(collection, key)",
            ~"Read an arbitrary JSON-serialisable value. Returns nil if missing.",
            ~"lua",
            ~"""
local highscore = game.storage.get("highscores", "global") or 0
"""),

        api(~"game.storage.set(collection, key, value)",
            ~"Write a value. Durable, atomic per-call.",
            ~"lua",
            ~"""
game.storage.set("highscores", "global", new_score)
"""),

        api(~"game.storage.player_get(player_id, collection, key) / player_set(...)",
            ~"Per-player scoped storage. Collection namespace is separate from the shared game.storage.get/set.",
            ~"lua",
            ~"""
game.storage.player_set(player_id, "inventory", "backpack", items)
local pack = game.storage.player_get(player_id, "inventory", "backpack")
"""),

        %% ---- Economy ----
        {h2, [], [~"Economy"]},

        api(~"game.economy.balance(player_id)",
            ~"Return the full wallet as { currency_id = amount, ... }.",
            ~"lua",
            ~"""
local wallet = game.economy.balance(player_id)
if (wallet.gold or 0) >= 100 then
  -- can afford
end
"""),

        api(~"game.economy.grant(player_id, currency, amount, reason)",
            ~"Add currency to a player's wallet. The reason is logged in the ledger for audit.",
            ~"lua",
            ~"""
game.economy.grant(winner_id, "gold", 50, "match_win")
"""),

        api(~"game.economy.debit(player_id, currency, amount, reason)",
            ~"Subtract currency. Returns { ok = true } or { ok = false, error = \"insufficient_funds\" }.",
            ~"lua",
            ~"""
local result = game.economy.debit(player_id, "gold", 100, "shop_buy:sword")
if result.ok then
  give_item(player_id, "sword")
end
"""),

        api(~"game.economy.purchase(player_id, listing_id)",
            ~"Atomic purchase from a store listing. Handles price check, debit, and inventory grant.",
            ~"lua",
            ~"""
game.economy.purchase(player_id, "shop:starter_pack")
"""),

        %% ---- Leaderboards ----
        {h2, [], [~"Leaderboards"]},

        api(~"game.leaderboard.submit(board_id, player_id, score)",
            ~"Submit a score. Monotonic boards keep the best score; cumulative boards add to the total.",
            ~"lua",
            ~"""
game.leaderboard.submit("arena:weekly", player_id, kills)
"""),

        api(~"game.leaderboard.top(board_id, count)",
            ~"Return the top N entries as { {player_id, score, rank}, ... }.",
            ~"lua",
            ~"""
for _, entry in ipairs(game.leaderboard.top("arena:weekly", 10)) do
  print(entry.rank, entry.player_id, entry.score)
end
"""),

        api(~"game.leaderboard.rank(board_id, player_id)",
            ~"Return a specific player's current rank.",
            ~"lua",
            ~"""
local my_rank = game.leaderboard.rank("arena:weekly", player_id)
"""),

        api(~"game.leaderboard.around(board_id, player_id, count)",
            ~"Return the N entries surrounding a specific player (useful for \x{201C}you are here\x{201D} displays).",
            ~"lua",
            ~"""
local neighbors = game.leaderboard.around("arena:weekly", player_id, 5)
"""),

        %% ---- Spatial ----
        {h2, [], [~"Spatial queries"]},

        api(~"game.spatial.query_radius(x, y, radius)",
            ~"Zone-based: find entities within a radius. Only valid in world-server (zone) context.",
            ~"lua",
            ~"""
local nearby = game.spatial.query_radius(player.x, player.y, 50)
for _, ent in ipairs(nearby) do
  -- ent = { id, x, y }
end
"""),

        api(~"game.spatial.query_radius(entities, x, y, radius, opts?)",
            ~"In-memory: query a Lua entity table directly. Accepts options: type filter, sort, max_results, custom filter.",
            ~"lua",
            ~"""
local close = game.spatial.query_radius(entities, 0, 0, 100, {
  type = "npc",
  sort = "nearest",
  max_results = 5
})
"""),

        api(~"game.spatial.query_rect(x1, y1, x2, y2)",
            ~"Zone-based rectangular query.",
            ~"lua",
            ~""),

        api(~"game.spatial.nearest(entities, x, y, n, opts?)",
            ~"Return the N nearest entities, sorted by distance.",
            ~"lua",
            ~""),

        api(~"game.spatial.distance(entity_a, entity_b)",
            ~"Euclidean distance between two entities.",
            ~"lua",
            ~""),

        api(~"game.spatial.in_range(entity_a, entity_b, range)",
            ~"Boolean: whether two entities are within `range` units of each other.",
            ~"lua",
            ~""),

        %% ---- Zone ----
        {h2, [], [~"Zones (world server only)"]},

        api(~"game.zone.spawn(template_id, x, y, overrides?)",
            ~"Spawn an entity from a template at (x, y). Overrides merge onto the template.",
            ~"lua",
            ~"""
local goblin = game.zone.spawn("goblin_warrior", 100, 200, { hp = 150 })
"""),

        api(~"game.zone.despawn(entity_id)",
            ~"Remove an entity from the zone.",
            ~"lua",
            ~""),

        %% ---- Terrain ----
        {h2, [], [~"Terrain"]},

        api(~"game.terrain.get_chunk(cx, cy)",
            ~"Fetch compressed chunk bytes for the given chunk coordinates. Chunks are served automatically on zone entry \x{2014} use this only if you need the data server-side.",
            ~"lua",
            ~""),

        api(~"game.terrain.preload(coords_list)",
            ~"Async preload chunks into the terrain cache. Useful ahead of a known player destination.",
            ~"lua",
            ~""),

        {h2, [], [~"Where next?"]},
        {ul, [], [
            {li, [], [{a, [{href, ~"/docs/lua/callbacks"}], [~"Game module callbacks"]}, ~" \x{2014} the functions ",
                {em, [], [~"you"]}, ~" implement (init, tick, join, leave, etc.)"]},
            {li, [], [{a, [{href, ~"/docs/lua/cookbook"}], [~"Cookbook"]}, ~" \x{2014} short patterns for common tasks."]},
            {li, [], [{a, [{href, ~"/docs/tutorials/tic-tac-toe"}], [~"Tic-tac-toe tutorial"]}, ~" \x{2014} see the API in context."]}
        ]}
    ]}),
    asobi_site_docs_shell:render(~"/docs/lua/api", Content).

api(Signature, Desc, Lang, Example) ->
    ?html({'div', [{class, ~"docs-api"}], [
        {h3, [], [{code, [], [Signature]}]},
        {p, [], [Desc]},
        example(Lang, Example)
    ]}).

example(_Lang, <<>>) -> [];
example(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
