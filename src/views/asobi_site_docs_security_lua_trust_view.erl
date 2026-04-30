-module(asobi_site_docs_security_lua_trust_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-sec-lua-trust", title => ~"Lua trust model — Asobi docs"},
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
                ~" / Lua trust model"
            ]},
            {h1, [], [~"Lua trust model"]},
            {p, [{class, ~"docs-lede"}], [
                ~"asobi_lua treats the mounted ",
                {code, [], [~"/app/game"]},
                ~" Lua scripts as ",
                {strong, [], [~"trusted"]},
                ~" in the same sense your ",
                {code, [], [~"/app/bin/asobi_lua"]},
                ~" binary is trusted: you control what files end up there. The sandbox protects against incidental scripting bugs (infinite loops, missed nil checks, atom exhaustion via untrusted player input) and makes it harder for a compromised dependency or ",
                {code, [], [~"require"]},
                ~"'d module to escape. It is not a defence against a deliberate, all-Erlang-aware adversary with the ability to write ",
                {code, [], [~"/app/game/match.lua"]},
                ~"."
            ]},

            {h2, [], [~"Verified negative results"]},
            {p, [], [
                ~"These are properties prior security audits looked at and confirmed hold. Documented here so future readers don't re-derive them."
            ]},

            {h3, [], [
                {code, [], [~"setmetatable(_G, ...)"]},
                ~" and ",
                {code, [], [~"setmetatable(os, ...)"]},
                ~" are still allowed"
            ]},
            {p, [], [
                ~"The strip pass calls ",
                {code, [], [~"set_table_keys"]},
                ~" with ",
                {code, [], [~"nil"]},
                ~", which Luerl's ",
                {code, [], [~"set_table_key_key/4"]},
                ~" erases the entry from the underlying ttdict \x{2014} the key becomes truly absent, not \"set to nil\". A subsequent ",
                {code, [], [~"__index"]},
                ~" metatable on ",
                {code, [], [~"os"]},
                ~" (or ",
                {code, [], [~"_G"]},
                ~") would intercept lookups for the absent keys. However, ",
                {code, [], [~"__index"]},
                ~" can only return values that exist in the script's reach, and the actual Erlang function references for ",
                {code, [], [~"os.execute"]},
                ~", ",
                {code, [], [~"os.exit"]},
                ~", etc. are stored exclusively inside the os table dict that was just erased. Once erased there is no Lua-reachable path to those function references \x{2014} they are not stored elsewhere in the Luerl state. So metatable manipulation cannot recover stripped functions."
            ]},

            {h3, [], [
                {code, [], [~"_ASOBI_LOADED"]},
                ~" is reachable via ",
                {code, [], [~"_G._ASOBI_LOADED"]}
            ]},
            {p, [], [
                ~"The require cache is installed as a global, fully visible to Lua. A script can iterate it, mutate it, delete entries. There's no privilege boundary inside a single Luerl state, so this is by design and acceptable. Cross-match isolation comes from each match having its own state; a script that clobbers its own cache only DoSes itself. The internal ",
                {code, [], [~"lookup_loaded"]},
                ~" helper in ",
                {code, [], [~"asobi_lua_loader"]},
                ~" handles a clobbered cache cleanly rather than crashing with ",
                {code, [], [~"case_clause"]},
                ~"."
            ]},

            {h3, [], [~"Atom-table inflation via ", {code, [], [~"terrain_provider"]}]},
            {p, [], [
                ~"A Lua script that returns ",
                {code, [], [~"{ module = \"<some_atom>\", ... }"]},
                ~" from ",
                {code, [], [~"terrain_provider/1"]},
                ~" cannot inflate the atom table \x{2014} the bridge uses ",
                {code, [], [~"binary_to_existing_atom/1"]},
                ~". As of the F-* hardening pass the bridge also requires the target module to be on an explicit allowlist (",
                {code, [], [~"asobi_terrain_flat"]},
                ~", ",
                {code, [], [~"asobi_terrain_perlin"]},
                ~" by default; configurable via ",
                {code, [], [~"application:get_env(asobi_lua, terrain_providers, ...)"]},
                ~") so a script that names an unrelated loaded module (",
                {code, [], [~"gen_server"]},
                ~", ",
                {code, [], [~"rpc"]},
                ~", etc.) is rejected with a ",
                {code, [], [~"terrain_provider_not_allowed"]},
                ~" warning."
            ]}
        ]}
    ).
