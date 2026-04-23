-module(asobi_site_docs_seasons_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {maps:merge(#{id => ~"docs-seasons", title => ~"Seasons"}, Bindings), #{}}.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Seasons"
            ]},
            {h1, [], [~"Seasons"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Seasons wrap the long-lived lifecycles that span many matches: weekly ",
                ~"competitive ladders, monthly events, recurring leaderboard resets, battle passes. ",
                ~"A season carries its own config, ranked state, and rewards, so match code can ",
                ~"ask \"which season are we in?\" and branch on it."
            ]},

            {h2, [], [~"The mental model"]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Config-driven. "]},
                    ~"You insert season rows into ",
                    {code, [], [~"seasons"]},
                    ~" (",
                    {code, [], [~"name"]},
                    ~", ",
                    {code, [], [~"starts_at"]},
                    ~", ",
                    {code, [], [~"ends_at"]},
                    ~", ",
                    {code, [], [~"config"]},
                    ~", ",
                    {code, [], [~"rewards"]},
                    ~"). The season manager flips their ",
                    {code, [], [~"status"]},
                    ~" (",
                    {code, [], [~"upcoming"]},
                    ~" \x{2192} ",
                    {code, [], [~"active"]},
                    ~" \x{2192} ",
                    {code, [], [~"ended"]},
                    ~") at the right wall-clock times."
                ]},
                {li, [], [
                    {strong, [], [~"Only one active. "]},
                    ~"At most one season is active at a time. Transitions are atomic \x{2014} ",
                    ~"there's no in-between."
                ]},
                {li, [], [
                    {strong, [], [~"Match code queries. "]},
                    ~"Your match module doesn't subscribe to lifecycle events \x{2014} it ",
                    ~"reads ",
                    {code, [], [~"asobi_season:current/0"]},
                    ~" (or ",
                    {code, [], [~"config/1"]},
                    ~") at the points where it matters."
                ]}
            ]},

            {h2, [], [~"Query the current season"]},
            {h3, [], [~"Erlang"]},
            code(
                ~"erlang",
                ~"""
case asobi_season:current() of
    {ok, #{name := Name, config := Config}} ->
        Multiplier = maps:get(~"xp_multiplier", Config, 1.0),
        apply_xp(Player, Base * Multiplier);
    {error, no_active_season} ->
        apply_xp(Player, Base)
end.

%% Sugar for reading one config key
Multiplier = asobi_season:config(~"xp_multiplier").
"""
            ),

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Lua note. "]},
                    ~"The current asobi_lua ",
                    {code, [], [~"game.*"]},
                    ~" surface doesn't expose seasons yet. From Lua, read per-season values ",
                    ~"through ",
                    {code, [], [~"game.storage.get"]},
                    ~" using a key the Erlang side writes at season start (e.g. ",
                    {code, [], [~"\"season:xp_multiplier\""]},
                    ~"). A ",
                    {code, [], [~"game.season"]},
                    ~" bridge is tracked for a future release."
                ]}
            ]},

            {h2, [], [~"Schedule upcoming seasons"]},
            {p, [], [
                ~"Seasons are ordinary ",
                {code, [], [~"kura"]},
                ~" records. Insert them ahead of time \x{2014} the season manager wakes up, ",
                ~"promotes ",
                {code, [], [~"upcoming"]},
                ~" \x{2192} ",
                {code, [], [~"active"]},
                ~" at ",
                {code, [], [~"starts_at"]},
                ~", demotes ",
                {code, [], [~"active"]},
                ~" \x{2192} ",
                {code, [], [~"ended"]},
                ~" at ",
                {code, [], [~"ends_at"]},
                ~"."
            ]},
            code(
                ~"erlang",
                ~"""
Now = erlang:system_time(millisecond),
WeekMs = 7 * 24 * 60 * 60 * 1000,
asobi_repo:insert(#{
    name => ~"Spring 2026",
    starts_at => Now,
    ends_at => Now + 4 * WeekMs,
    status => ~"upcoming",
    config => #{xp_multiplier => 1.5, map_pool => [~"greenfield", ~"atoll"]},
    rewards => #{top_1_percent => #{badge => ~"champion_spring_26"}}
}, asobi_season).
"""
            ),

            {h2, [], [~"Inspecting history and upcoming"]},
            code(
                ~"erlang",
                ~"""
asobi_season:upcoming().       %% -> [#{...}, ...]  (ordered by starts_at asc)
asobi_season:history().        %% -> [#{...}, ...]  (last 20 ended, desc)
asobi_season:time_remaining(). %% -> ms until current season ends
"""
            ),

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Why not just use phases? "]},
                    ~"Phases are in-match scaffolding \x{2014} lobby, combat, results. Seasons ",
                    ~"are cross-match state that persists after any individual match ends. Use ",
                    {a, [{href, ~"/docs/phases"}, az_navigate], [~"phases"]},
                    ~" for the structure of a single session; use seasons for the rules that ",
                    ~"apply across many sessions."
                ]}
            ]},

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/leaderboards"}, az_navigate], [
                        ~"Leaderboards & tournaments"
                    ]},
                    ~" \x{2014} per-season leaderboards and tournament brackets."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/phases"}, az_navigate], [~"Phases & timers"]},
                    ~" \x{2014} in-match lifecycle."
                ]}
            ]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
