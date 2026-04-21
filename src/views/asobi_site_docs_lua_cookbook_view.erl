-module(asobi_site_docs_lua_cookbook_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {
        maps:merge(#{id => ~"docs-lua-cookbook", title => ~"Lua cookbook — Asobi docs"}, Bindings),
        #{}
    }.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Lua / Cookbook"
            ]},
            {h1, [], [~"Lua cookbook"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Short, copy-pasteable patterns for common gameplay tasks. Each recipe is self-contained and assumes you already have a Lua game module loaded."
            ]},

            recipe(
                ~"Send to one player vs. everyone",
                ~"""
-- to everyone in the match
game.broadcast("announce", { text = "Match starting!" })

-- to one player
game.send(player_id, { kind = "private_hint", text = "The treasure is north" })

-- to a specific subset (loop + send)
for pid, _ in pairs(state.players) do
    if state.teams[pid] == "red" then
        game.send(pid, { kind = "team_chat", from = from, text = msg })
    end
end
"""
            ),

            recipe(
                ~"Reject an input with an error echo",
                ~"""
function game.handle_input(player_id, input, state)
    if input.action == "buy" and not can_afford(player_id, input.item, state) then
        game.send(player_id, { kind = "error", code = "too_poor", item = input.item })
        return state
    end
    -- happy path
    return apply_buy(player_id, input.item, state)
end
"""
            ),

            recipe(
                ~"Per-player scoped persistence",
                ~"""
-- save on leave, restore on join
function game.join(player_id, state)
    local saved = game.storage.player_get(player_id, "inv", "backpack") or {}
    state.inventories[player_id] = saved
    return state
end

function game.leave(player_id, state)
    game.storage.player_set(player_id,
        "inv", "backpack",
        state.inventories[player_id] or {})
    state.inventories[player_id] = nil
    return state
end
"""
            ),

            recipe(
                ~"Ticking AI without blowing the budget",
                ~"""
-- Only step a fraction of NPCs per tick to spread work.
function game.tick(state)
    state.cursor = (state.cursor or 0) + 1
    local total = #state.npcs
    local batch = math.max(1, math.floor(total / 10))  -- 10% per tick

    for i = 1, batch do
        local idx = ((state.cursor + i - 1) % total) + 1
        step_npc(state.npcs[idx], state)
    end
    return state
end
"""
            ),

            recipe(
                ~"Grant currency and check balance",
                ~"""
-- winner: grant, then submit to the leaderboard
game.economy.grant(winner_id, "gold", 50, "match_win")
game.leaderboard.submit("arena:weekly", winner_id, state.scores[winner_id])

-- check before showing a buy button
local wallet = game.economy.balance(player_id)
local can_buy = (wallet.gold or 0) >= listing.price
game.send(player_id, { kind = "shop", listing = listing, can_buy = can_buy })
"""
            ),

            recipe(
                ~"Atomic shop purchase",
                ~"""
-- Use purchase() rather than manual debit + grant — it's transactional.
function buy_listing(player_id, listing_id)
    local result = game.economy.purchase(player_id, listing_id)
    if result.ok then
        game.send(player_id, { kind = "purchase_ok", listing_id = listing_id })
    else
        game.send(player_id, { kind = "purchase_fail", reason = result.error })
    end
end
"""
            ),

            recipe(
                ~"Spatial: nearest enemies for auto-target",
                ~"""
local targets = game.spatial.nearest(state.enemies, player.x, player.y, 3, {
    type = "hostile",
    sort = "nearest",
})
for _, t in ipairs(targets) do
    deal_damage(t, 10)
end
"""
            ),

            recipe(
                ~"World zone: spawn a boss and announce it",
                ~"""
local boss = game.zone.spawn("dragon", 2048, 512, {
    hp    = 10000,
    phase = "sleeping",
})
game.broadcast("boss_spawned", {
    id = boss.id, x = boss.x, y = boss.y
})
"""
            ),

            recipe(
                ~"Phases: lobby → active → results (world mode only)",
                ~"""
-- NOTE: Lua phases only fire in WORLD mode (large session games).
-- Lua match games should model phases inside tick(state) instead.
function game.phases(_config)
    return {
        { name = "lobby",   duration = 30000 },
        { name = "active",  duration = 300000 },
        { name = "results", duration = 15000 },
    }
end

function game.on_phase_started(name, state)
    if name == "active" then
        state.active_at = os.time()
        game.broadcast("go", {})
    elseif name == "results" then
        game.broadcast("results", { final = state.scores })
    end
    return state
end
"""
            ),

            recipe(
                ~"In-match vote with short-circuit on majority",
                ~"""
-- Offer a boon pick every time a wave clears.
function game.vote_requested(state)
    if state.wave_cleared then
        state.wave_cleared = false
        return {
            template  = "boon",
            method    = "plurality",
            options   = pick_3_boons(),
            window_ms = 20000,
            quorum    = 0.5,  -- fraction (0.0-1.0); resolves when half voted
        }
    end
    return nil
end

function game.vote_resolved(_template, result, state)
    apply_boon(result.winner, state)
    game.broadcast("boon_picked", { boon = result.winner })
    return state
end
"""
            ),

            recipe(
                ~"Reconnect-friendly ephemeral state",
                ~"""
-- Keep minimal authoritative data in state; derive view via get_state.
function game.get_state(player_id, state)
    -- On reconnect the client gets this fresh snapshot.
    return {
        you     = state.players[player_id] or {},
        others  = visible_others(player_id, state),
        phase   = state.current_phase,
        elapsed = state.elapsed,
    }
end
"""
            ),

            recipe(
                ~"Notify winners without blocking the tick",
                ~"""
-- notify_many fans out via the background broadcaster.
game.notify_many(winners, "tournament_win", "You won the bracket!", {
    prize_id = "trophy_gold",
    unlock_at = os.time() + 60,
})
"""
            ),

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/lua/api"}, az_navigate], [~"game.* API reference"]},
                    ~" \x{2014} the full surface these recipes call into."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/lua/callbacks"}, az_navigate], [~"Game module callbacks"]},
                    ~" \x{2014} what ",
                    {em, [], [~"you"]},
                    ~" implement."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/tutorials/tic-tac-toe"}, az_navigate], [
                        ~"Tic-tac-toe tutorial"
                    ]},
                    ~" \x{2014} everything applied to a concrete game."
                ]}
            ]}
        ]}
    ).
recipe(Title, Body) ->
    ?html(
        {'div', [{class, ~"docs-api"}], [
            {h3, [], [Title]},
            {pre, [], [{code, [{class, ~"language-lua"}], [Body]}]}
        ]}
    ).
