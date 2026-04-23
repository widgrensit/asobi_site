-module(asobi_site_docs_phases_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {maps:merge(#{id => ~"docs-phases", title => ~"Phases & timers"}, Bindings), #{}}.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Phases & timers"
            ]},
            {h1, [], [~"Phases & timers"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Most games have structure: a lobby phase, a combat phase, a results phase. ",
                ~"Each phase can end on a timer, on a condition, or when the previous one finishes. ",
                ~"asobi's phase engine lets you declare that structure as data and let the engine ",
                ~"drive state transitions for you."
            ]},

            {h2, [], [~"The mental model"]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Phase "]},
                    ~"\x{2014} a named span of a match or world. Duration, start condition, ",
                    ~"end condition, optional timers."
                ]},
                {li, [], [
                    {strong, [], [~"Timer "]},
                    ~"\x{2014} pure state that ticks. Four primitives: countdown, conditional, ",
                    ~"cycle, scheduled. Can fire warnings and expiry events."
                ]},
                {li, [], [
                    {strong, [], [~"Phase engine "]},
                    ~"\x{2014} pure function. Your server calls ",
                    {code, [], [~"asobi_phase:tick/2"]},
                    ~" each game tick; it returns a list of events (",
                    {code, [], [~"phase_started"]},
                    ~", ",
                    {code, [], [~"phase_ended"]},
                    ~", ",
                    {code, [], [~"timer_expired"]},
                    ~", etc.) and the updated phase state."
                ]}
            ]},

            {h2, [], [~"Declare phases"]},
            {p, [], [
                ~"Each phase is a map with a name and optional start/end conditions. ",
                ~"The engine walks them in order."
            ]},

            {h3, [], [~"Erlang"]},
            code(
                ~"erlang",
                ~"""
Phases = [
    #{name => ~"lobby",   start => prev_ended,        duration => 30_000},
    #{name => ~"combat",  start => {players, 2},      duration => 300_000},
    #{name => ~"results", start => prev_ended,        duration => 15_000}
].

State0 = asobi_phase:init(Phases).

%% each tick
{Events, State1} = asobi_phase:tick(TickMs, State0),
handle_phase_events(Events).
"""
            ),

            {h3, [], [~"Lua"]},
            {p, [], [
                ~"Return the list from ",
                {code, [], [~"phases(config)"]},
                ~"; the asobi_lua runtime wires it up for you. Implement ",
                {code, [], [~"on_phase_started"]},
                ~" / ",
                {code, [], [~"on_phase_ended"]},
                ~" to react."
            ]},
            code(
                ~"lua",
                ~"""
function phases(config)
    return {
        { name = "lobby",   start = "prev_ended", duration = 30000  },
        { name = "combat",  start = "all_ready",  duration = 300000 },
        { name = "results", start = "prev_ended", duration = 15000  },
    }
end

function on_phase_started(phase_name, state)
    if phase_name == "combat" then
        state.started_at = os.time()
        game.broadcast("combat_started", {})
    end
    return state
end

function on_phase_ended(phase_name, state)
    if phase_name == "combat" then
        state.winner = compute_winner(state)
    end
    return state
end
"""
            ),

            {h2, [], [~"Start conditions"]},
            {p, [], [
                ~"A phase starts as soon as its start condition matches. Without one it ",
                ~"starts when the previous phase ends (",
                {code, [], [~"prev_ended"]},
                ~")."
            ]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"prev_ended"]},
                    ~" \x{2014} right after the previous phase finishes (default)."
                ]},
                {li, [], [
                    {code, [], [~"{players, N}"]},
                    ~" \x{2014} when at least N players have joined."
                ]},
                {li, [], [
                    {code, [], [~"{players_ratio, 0.5}"]},
                    ~" \x{2014} when at least half of ",
                    {code, [], [~"max_players"]},
                    ~" have joined."
                ]},
                {li, [], [
                    {code, [], [~"all_ready"]},
                    ~" \x{2014} when every joined player has sent a ready signal."
                ]},
                {li, [], [
                    {code, [], [~"{event, Atom}"]},
                    ~" \x{2014} when your code calls ",
                    {code, [], [~"asobi_phase:notify(State, Atom)"]},
                    ~"."
                ]},
                {li, [], [
                    {code, [], [~"{timer, Ms}"]},
                    ~" \x{2014} after a wait period (in ms) from the previous phase ending."
                ]}
            ]},

            {h2, [], [~"Events"]},
            {p, [], [
                {code, [], [~"asobi_phase:tick/2"]},
                ~" returns a list of events the owning server should react to:"
            ]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"{phase_started, Name}"]},
                    ~" \x{2014} fire on_phase_started (Lua) or run your transition code."
                ]},
                {li, [], [
                    {code, [], [~"{phase_ended, Name}"]},
                    ~" \x{2014} fire on_phase_ended; persist results, tally score."
                ]},
                {li, [], [
                    {code, [], [~"{all_phases_complete}"]},
                    ~" \x{2014} the engine has nothing left; end the match."
                ]},
                {li, [], [
                    ~"Any timer events from timers attached to the current phase (see below)."
                ]}
            ]},

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Pause & resume. "]},
                    {code, [], [~"asobi_phase:pause/1"]},
                    ~" and ",
                    {code, [], [~"resume/1"]},
                    ~" freeze the whole engine (including all active timers) \x{2014} useful ",
                    ~"for host migration, server reconnection drills, or pause menus in turn-based ",
                    ~"games."
                ]}
            ]},

            {h2, [], [~"Timers"]},
            {p, [], [
                ~"Timers are pure state that ",
                {strong, [], [~"the phase engine ticks for you"]},
                ~" when you attach them to a phase. You can also construct and tick them yourself ",
                ~"with ",
                {code, [], [~"asobi_timer"]},
                ~" if you need one outside the phase engine \x{2014} say, a global ",
                ~"queue timeout."
            ]},

            {h3, [], [~"countdown"]},
            {p, [], [
                ~"Fixed duration, optional warnings, optionally pauses if no players. The workhorse."
            ]},
            code(
                ~"erlang",
                ~"""
asobi_timer:countdown(#{
    id => ~"join_window",
    duration => 20_000,
    warnings => [10_000, 5_000, 3_000],   %% fire timer_warning at each
    on_expire => close_lobby,
    pause_on_empty => true
}).
"""
            ),

            {h3, [], [~"conditional"]},
            {p, [], [
                ~"Starts when a condition is met, with a fallback timeout so it can't hang forever. ",
                ~"Good for \"start combat when all players ready OR after 30s, whichever first.\""
            ]},
            code(
                ~"erlang",
                ~"""
asobi_timer:conditional(#{
    id => ~"ready_up",
    start_condition => all_ready,
    duration => 60_000,
    fallback_timeout => 30_000,
    on_expire => start_combat
}).
"""
            ),

            {h3, [], [~"cycle"]},
            {p, [], [
                ~"Rotates through a list of sub-phases with individual durations. Day/night ",
                ~"cycles, pattern rotations, traffic-light timers."
            ]},
            code(
                ~"erlang",
                ~"""
asobi_timer:cycle(#{
    id => ~"day_night",
    phases => [
        #{name => ~"day",   duration => 300_000},
        #{name => ~"night", duration => 120_000}
    ],
    repeat => true
}).
"""
            ),

            {h3, [], [~"scheduled"]},
            {p, [], [
                ~"Fires at a specific wall-clock time. For seasonal rollovers, daily resets, ",
                ~"double-XP windows."
            ]},
            code(
                ~"erlang",
                ~"""
asobi_timer:scheduled(#{
    id => ~"daily_reset",
    fire_at => erlang:system_time(millisecond) + 86_400_000  %% 24h from now
}).
"""
            ),

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/erlang/api"}, az_navigate], [~"Erlang API reference"]},
                    ~" \x{2014} full specs for ",
                    {code, [], [~"asobi_phase"]},
                    ~" and ",
                    {code, [], [~"asobi_timer"]},
                    ~"."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/lua/callbacks"}, az_navigate], [~"Lua callbacks"]},
                    ~" \x{2014} the ",
                    {code, [], [~"phases"]},
                    ~" / ",
                    {code, [], [~"on_phase_started"]},
                    ~" / ",
                    {code, [], [~"on_phase_ended"]},
                    ~" contract in Lua."
                ]}
            ]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
