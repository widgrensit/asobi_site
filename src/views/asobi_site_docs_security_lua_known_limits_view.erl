-module(asobi_site_docs_security_lua_known_limits_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-sec-lua-known", title => ~"Lua known limitations — Asobi docs"},
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
                ~" / Lua known limitations"
            ]},
            {h1, [], [~"Lua known limitations"]},
            {p, [{class, ~"docs-lede"}], [
                ~"The asobi_lua sandbox closes a deliberate set of attack surfaces (see ",
                {a, [{href, ~"/docs/security/lua-sandbox"}, az_navigate], [~"sandbox model"]},
                ~"). The list below is the complement: properties the sandbox does ",
                {strong, [], [~"not"]},
                ~" enforce. Operators who care about any of these should plan their deployment accordingly."
            ]},

            {h2, [], [~"Resource bounds"]},

            {h3, [], [~"No reduction limit / hard CPU cap"]},
            {p, [], [
                ~"The wall-clock timeout is the only resource bound today. A script can soak its full per-callback budget every tick without being throttled. Luerl upstream does not currently expose a \"reduction limit\" or \"process-bound state\" knob; a future hardening pass may add a soft budget on the Luerl scheduler."
            ]},

            {h3, [], [~"No per-script heap cap"]},
            {p, [], [
                ~"Lua tables grow inside the BEAM process heap. A pathological script that allocates 100 MB of tables and drops them every tick will pressure the OS memory allocator. The decode depth cap (64 levels) bounds recursion at the bridge boundary, but does not bound table size."
            ]},

            {h3, [], [~"Per-callback state copy cost is linear"]},
            {p, [], [
                ~"Each timeout-wrapped callback spawns a child process that takes a full copy of the Luerl state (",
                {code, [], [~"spawn(fun() -> call(..., St) end)"]},
                ~"). Cost is linear in script-side allocation. A script that intentionally builds large stable tables forces every later callback to pay the copy. Watch for unexplained per-tick latency growth on long-lived matches."
            ]},

            {h2, [], [~"Deployment hygiene"]},

            {h3, [], [~"The container release tree is writable"]},
            {p, [], [
                ~"The shipped Dockerfile runs as the non-root ",
                {code, [], [~"asobi"]},
                ~" user but does not declare ",
                {code, [], [~"--read-only"]},
                ~". The README example mounts ",
                {code, [], [~"/app/game"]},
                ~" ",
                {code, [], [~":ro"]},
                ~"; that mode is the operator's responsibility, not the runtime's. We recommend ",
                {code, [], [~"docker run --read-only --tmpfs /tmp"]},
                ~" and chowning only ",
                {code, [], [~"/app/game"]},
                ~" to the runtime user."
            ]},

            {h3, [], [~"Symlinks under the game dir"]},
            {p, [], [
                {code, [], [~"require"]},
                ~" rejects symlinks at resolve time, so a misplaced symlink under ",
                {code, [], [~"<base>/foo.lua"]},
                ~" no longer slips through. This is defense in depth: keep the game dir mounted read-only and the build pipeline should not produce symlinks in the first place."
            ]},

            {h2, [], [~"Behavioural"]},

            {h3, [], [~"Mid-callback rollback is best-effort"]},
            {p, [], [
                ~"If a callback is killed by its wall-clock timeout after it has already issued a side-effecting ",
                {code, [], [~"game.*"]},
                ~" API call (e.g. ",
                {code, [], [~"game.economy.debit"]},
                ~"), the side effect persists. The Lua-side state reverts to the prior tick but the asobi-side ledger does not. Treat economy / leaderboard / storage mutations as ",
                {strong, [], [~"best-effort committed"]},
                ~". For high-stakes flows, checkpoint state before/after the API call so the next tick reconciles, or wrap mutations in a transactional helper tagged with the call's ref."
            ]},

            {h3, [], [
                ~"Bot ", {code, [], [~"think/2"]}, ~" errors fall back to the built-in default AI"
            ]},
            {p, [], [
                ~"A rate-limited ",
                {code, [], [~"logger:warning"]},
                ~" is emitted (one line per bot per minute) when the fallback fires so persistently-broken scripts are visible. Operators who rely on bot scripts should still monitor behaviour externally; a silent fallback bot will keep playing the match without ever calling your custom AI."
            ]},

            {h2, [], [~"Logging"]},

            {h3, [], [{code, [], [~"require_failed"]}, ~" error payload is truncated"]},
            {p, [], [
                ~"When ",
                {code, [], [~"luerl:do/2"]},
                ~" rejects a ",
                {code, [], [~"require"]},
                ~"'d file (non-Lua content, syntactically invalid Lua), the compiler error list is truncated to the first three entries before propagating. This prevents a binary file mistakenly placed under the game dir from dumping arbitrary bytes into the structured log pipeline."
            ]}
        ]}
    ).
