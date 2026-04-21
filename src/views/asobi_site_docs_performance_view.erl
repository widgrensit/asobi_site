-module(asobi_site_docs_performance_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-performance", title => ~"Performance — Asobi docs"},
            Bindings
        ),
        #{}
    }.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Performance"
            ]},
            {h1, [], [~"Performance & benchmarks"]},
            {p, [{class, ~"docs-lede"}], [
                ~"What Asobi handles, how to measure it, and how to tune tick rates, zone sizing, and BEAM knobs when you need more headroom."
            ]},

            {h2, [], [~"Reference benchmarks"]},
            {p, [], [
                ~"Measured on a single 4-core VM (2026-04 runs, ",
                {code, [], [~"asobi_bench"]},
                ~"):"
            ]},
            {pre, [], [
                {code, [], [
                    ~"""
 Scenario                              Players   Rate    CPU     RAM
 ─────────────────────────────────────────────────────────────────────
 Match: 10-player arena, 20 Hz ticks   10        20 Hz   ~3%     ~40 MB
 Match: 100 concurrent arenas          1000      20 Hz   ~35%    ~800 MB
 World: 500 players on 128K x 128K     500       20 Hz   ~55%    ~208 MB
 WebSocket fan-out: chat broadcast     10000     10 Hz   ~25%    ~600 MB
 Matchmaker tick (10K tickets)         10000     1 Hz    ~10%    negligible
"""
                ]}
            ]},
            {p, [], [
                ~"Worst-case p99 tick latency stays under 5 ms in all scenarios. Full methodology + reproducer: ",
                {a, [{href, ~"https://github.com/widgrensit/asobi/tree/main/bench"}], [
                    ~"asobi/bench"
                ]},
                ~"."
            ]},

            {h2, [], [~"Tick budget"]},
            {p, [], [
                ~"Everything in a tick must finish before the next tick fires. Default 20 Hz = 50 ms budget. If ",
                {code, [], [~"zone_tick/2"]},
                ~" takes 60 ms, you miss the next tick; state updates bunch up and become bursty. Keep tick work to <50% of the budget to leave headroom for input spikes."
            ]},

            {h2, [], [~"Tuning ticks"]},
            {ul, [], [
                {li, [], [
                    ~"Lower the tick rate (10\x{2013}15 Hz) if you don't need 20 Hz visual smoothness."
                ]},
                {li, [], [
                    ~"Split heavy per-entity work across frames (round-robin): see the ",
                    {a, [{href, ~"/docs/lua/cookbook"}, az_navigate], [
                        ~"cookbook AI-stepping recipe"
                    ]},
                    ~"."
                ]},
                {li, [], [
                    ~"Move expensive deterministic sims to NIFs if you've profiled them as the bottleneck (rare)."
                ]}
            ]},

            {h2, [], [~"Zone sizing"]},
            {ul, [], [
                {li, [], [
                    ~"Too small: many zones, more subscription churn on movement, higher delta overhead."
                ]},
                {li, [], [
                    ~"Too large: one zone dominates a CPU core; fewer parallelism opportunities."
                ]},
                {li, [], [
                    ~"Rule of thumb: target 10\x{2013}50 entities per zone under peak load, grid cell = 2\x{00D7} max interest radius."
                ]}
            ]},

            {h2, [], [~"Delta compression"]},
            {p, [], [
                ~"Only changed fields ship. If your state map is deep (nested entities, lists of lists), diffs can be expensive to compute. Flatten hot-path state into top-level fields for cheap diffs; keep per-player \x{201C}what did they see last tick\x{201D} in match state so ",
                {code, [], [~"get_state"]},
                ~" short-circuits when nothing changed."
            ]},

            {h2, [], [~"BEAM knobs"]},
            code(
                ~"bash",
                ~"""
# vm.args — baseline for a 16-core host
+sbt db                       # bind schedulers to cores
+S 16:16                      # schedulers = online cores
+A 64                         # async IO threads for file/socket reads
+P 10000000                   # max processes (matches + zones + sessions)
+K true                       # kernel poll (Linux)
+zdbbl 32768                  # distribution buffer, 32 MiB (cluster only)
"""
            ),

            {h2, [], [~"Profiling"]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"recon"]},
                    ~" for live-node inspection (top processes by memory/reductions)."
                ]},
                {li, [], [
                    {code, [], [~"fprof"]},
                    ~" / ",
                    {code, [], [~"eprof"]},
                    ~" for deterministic CPU profiles of specific callbacks."
                ]},
                {li, [], [{code, [], [~"msacc"]}, ~" for scheduler utilization / where time goes."]},
                {li, [], [{code, [], [~"observer_cli"]}, ~" for a continuous dashboard."]}
            ]},

            {h2, [], [~"Lua-specific"]},
            {ul, [], [
                {li, [], [
                    ~"Luerl is interpreted. Lua callbacks run 3\x{2013}10\x{00D7} slower than equivalent Erlang. For a 10 Hz arena this is fine; for 60 Hz physics, write the hot loop in Erlang and call from Lua."
                ]},
                {li, [], [
                    ~"Avoid allocating big tables every tick \x{2014} reuse state. Luerl's GC is per-VM and stops the tick."
                ]},
                {li, [], [
                    ~"The Lua tick has a hard 500ms timeout; keep callbacks under a few milliseconds and split long-running work across ticks with an explicit state cursor."
                ]}
            ]},

            {h2, [], [~"Load testing"]},
            {p, [], [
                ~"The ",
                {code, [], [~"asobi_bench"]},
                ~" repo includes ",
                {code, [], [~"tsung"]},
                ~"-style scripts for WebSocket + REST load. Run against a staging node before major releases."
            ]},

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [{a, [{href, ~"/docs/clustering"}, az_navigate], [~"Clustering"]}]},
                {li, [], [
                    {a, [{href, ~"/docs/world-server"}, az_navigate], [~"World server deep dive"]}
                ]},
                {li, [], [{a, [{href, ~"/docs/configuration"}, az_navigate], [~"Configuration"]}]}
            ]}
        ]}
    ).
code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
