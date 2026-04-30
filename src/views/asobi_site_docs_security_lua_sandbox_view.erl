-module(asobi_site_docs_security_lua_sandbox_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-sec-lua-sandbox", title => ~"Lua sandbox — Asobi docs"},
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
                ~" / ",
                {a, [{href, ~"/docs/security"}, az_navigate], [~"Security"]},
                ~" / Lua sandbox"
            ]},
            {h1, [], [~"Lua sandbox model"]},
            {p, [{class, ~"docs-lede"}], [
                ~"asobi_lua runs every Lua script in a hardened Luerl state. Sandbox construction lives in ",
                {code, [], [~"asobi_lua_loader:new/1"]},
                ~" and ",
                {code, [], [~"asobi_lua_loader:init_sandboxed/0"]},
                ~"."
            ]},

            {h2, [], [~"Removed from the global environment"]},
            {p, [], [
                ~"The following standard-library entries are cleared (",
                {code, [], [~"= nil"]},
                ~") so a hostile script cannot reach them:"
            ]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"OS escape hatches: "]},
                    {code, [], [~"os.execute"]},
                    ~", ",
                    {code, [], [~"os.exit"]},
                    ~", ",
                    {code, [], [~"os.getenv"]},
                    ~", ",
                    {code, [], [~"os.remove"]},
                    ~", ",
                    {code, [], [~"os.rename"]},
                    ~", ",
                    {code, [], [~"os.tmpname"]}
                ]},
                {li, [], [
                    {strong, [], [~"Code loading: "]},
                    {code, [], [~"dofile"]},
                    ~", ",
                    {code, [], [~"loadfile"]},
                    ~", ",
                    {code, [], [~"load"]},
                    ~", ",
                    {code, [], [~"loadstring"]}
                ]},
                {li, [], [
                    {strong, [], [~"I/O: "]}, ~"the entire ", {code, [], [~"io"]}, ~" library"
                ]},
                {li, [], [
                    {strong, [], [~"Package machinery: "]},
                    ~"the entire ",
                    {code, [], [~"package"]},
                    ~" library, plus the default ",
                    {code, [], [~"require"]}
                ]},
                {li, [], [
                    {strong, [], [~"Unstructured logging: "]},
                    {code, [], [~"print"]},
                    ~", ",
                    {code, [], [~"eprint"]},
                    ~" \x{2014} Luerl's defaults bypass the structured logger and write straight to BEAM stdout. Scripts that need to log should go through the asobi-side ",
                    {code, [], [~"game.log"]},
                    ~" API."
                ]}
            ]},
            {p, [], [
                {code, [], [~"os.clock"]},
                ~", ",
                {code, [], [~"os.date"]},
                ~", ",
                {code, [], [~"os.difftime"]},
                ~", and ",
                {code, [], [~"os.time"]},
                ~" remain available so games can timestamp."
            ]},

            {h2, [], [~"Replaced"]},
            {ul, [], [
                {li, [], [
                    {strong, [], [{code, [], [~"require/1"]}, ~" "]},
                    ~"is provided by asobi_lua. Names must match ",
                    {code, [], [~"[A-Za-z_][A-Za-z0-9_]*(\\.[A-Za-z_][A-Za-z0-9_]*)*"]},
                    ~" \x{2014} letters, digits, underscores, with ",
                    {code, [], [~"."]},
                    ~" separating segments. Names like ",
                    {code, [], [~"../foo"]},
                    ~", ",
                    {code, [], [~"/etc/passwd"]},
                    ~", ",
                    {code, [], [~"foo/bar"]},
                    ~", ",
                    {code, [], [~"42"]},
                    ~", or ",
                    {code, [], [~"''"]},
                    ~" are rejected. The validator uses the ",
                    {code, [], [~"dollar_endonly"]},
                    ~" regex flag so ",
                    {code, [], [~"require(\"foo\\n\")"]},
                    ~" does not slip through. The resolver joins the validated name to the directory of the loading script and reads the file with ",
                    {code, [], [~"file:read_file/1"]},
                    ~". Symlinks at the resolved path are rejected before reading."
                ]},
                {li, [], [
                    {strong, [], [{code, [], [~"math.random"]}, ~" "]},
                    ~"dispatches to Erlang's ",
                    {code, [], [~"rand:uniform"]},
                    ~". Single-arg form returns an integer in ",
                    {code, [], [~"[1, N]"]},
                    ~"; no-arg form returns a float in ",
                    {code, [], [~"[0, 1)"]},
                    ~". The two-arg ",
                    {code, [], [~"math.random(a, b)"]},
                    ~" form upstream Lua exposes is not supported."
                ]},
                {li, [], [
                    {strong, [], [{code, [], [~"math.sqrt"]}, ~" "]},
                    ~"dispatches to Erlang's ",
                    {code, [], [~"math:sqrt/1"]},
                    ~". Negative input returns ",
                    {code, [], [~"0.0"]},
                    ~" (upstream Lua returns NaN; Erlang would crash)."
                ]}
            ]},

            {h2, [], [~"Per-callback wall-clock limits"]},
            {p, [], [
                ~"Every Lua callback (init, tick, join, leave, handle_input, get_state, vote_requested, vote_resolved, generate_world, phases, spawn_templates, on_phase_started/ended, on_zone_loaded/unloaded, on_world_recovered, terrain_provider, spawn_position, post_tick, zone_tick, bot ",
                {code, [], [~"think"]},
                ~") runs in a child process with a wall-clock budget. A runaway script (",
                {code, [], [~"while true do end"]},
                ~", deep recursion, huge allocation) is killed when its budget elapses; the parent gen_server logs a warning and continues with the previous state. Limits are tuned per callback \x{2014} init/generate_world get more time, per-tick callbacks get less."
            ]},
            {p, [], [
                ~"The same wall-clock wrapper is applied to the initial script body load (",
                {code, [], [~"asobi_lua_loader:new/1"]},
                ~"), the hot-reload path, and the config manifest evaluator. A ",
                {code, [], [~"while true do end"]},
                ~" at the top of ",
                {code, [], [~"match.lua"]},
                ~" therefore can no longer hang application start or the match gen_server."
            ]},

            {h2, [], [~"Cross-script isolation"]},
            {p, [], [
                ~"Each match and each zone gets its own Luerl state. Globals, modules, and the require cache live inside that state \x{2014} there is no shared table reachable from script code that crosses match boundaries."
            ]},

            {h2, [], [~"Atom exhaustion"]},
            {p, [], [
                {code, [], [~"asobi_lua_api"]},
                ~"'s ",
                {code, [], [~"safe_to_atom"]},
                ~" helper and ",
                {code, [], [~"terrain_provider"]},
                ~" decoding both use ",
                {code, [], [~"binary_to_existing_atom/1"]},
                ~" so a Lua-supplied string cannot inflate the global atom table. Additionally, the terrain provider module name is matched against an explicit allowlist (",
                {code, [], [~"asobi_terrain_flat"]},
                ~", ",
                {code, [], [~"asobi_terrain_perlin"]},
                ~" by default; configurable via the ",
                {code, [], [~"asobi_lua, terrain_providers"]},
                ~" env) so a script cannot dispatch into arbitrary loaded modules even if the underlying atom already exists."
            ]},

            {h2, [], [~"Decode depth cap"]},
            {p, [], [
                {code, [], [~"asobi_lua_api"]},
                ~"'s deep-decode helper recurses on Lua-side tables; depth is capped at 64 levels and over-deep subtrees are replaced with the atom ",
                {code, [], [~"too_deep"]},
                ~". A malicious script returning a 100k-deep table from a callback can no longer blow the parent process heap."
            ]},

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/security/lua-trust-model"}, az_navigate], [
                        ~"Lua trust model"
                    ]}
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/security/lua-known-limitations"}, az_navigate], [
                        ~"Lua known limitations"
                    ]}
                ]},
                {li, [], [{a, [{href, ~"/docs/lua/api"}, az_navigate], [~"game.* API reference"]}]}
            ]}
        ]}
    ).
