-module(asobi_site_docs_glossary_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {maps:merge(#{id => ~"docs-glossary", title => ~"Project glossary"}, Bindings), #{}}.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {h1, [], [~"Project glossary"]},
            {p, [{class, ~"docs-lede"}], [
                ~"You'll see several \"asobi\" names in docs, repos, and the Discord. ",
                ~"Here's what each one is and when to reach for it. Read this ",
                ~"page first if you're new \x{2014} the names look ",
                ~"interchangeable and aren't."
            ]},

            {h2, [], [~"The open-source pieces"]},
            {'dl', [{class, ~"docs-glossary"}], [
                {dt, [], [
                    {a, [{href, ~"https://github.com/widgrensit/asobi"}], [~"asobi"]}
                ]},
                {dd, [], [
                    ~"The public Erlang library on ",
                    {a, [{href, ~"https://hex.pm/packages/asobi"}], [~"Hex"]},
                    ~". Depend on it in ",
                    {code, [], [~"rebar.config"]},
                    ~" if you're writing your backend in Erlang/OTP and want match, ",
                    ~"matchmaking, world-server, voting, economy, and the rest as ",
                    ~"composable OTP behaviours. The library underneath everything."
                ]},

                {dt, [], [
                    {a, [{href, ~"https://github.com/widgrensit/asobi_lua"}], [~"asobi_lua"]}
                ]},
                {dd, [], [
                    ~"The batteries-included runtime that wraps ",
                    {code, [], [~"asobi"]},
                    ~" with a ",
                    {a, [{href, ~"https://github.com/rvirding/luerl"}], [~"Luerl"]},
                    ~" VM so you can write game logic in Lua without knowing ",
                    ~"Erlang. Ships as ",
                    {code, [], [~"ghcr.io/widgrensit/asobi_lua"]},
                    ~". Most people start here."
                ]},

                {dt, [], [~"asobi_arena_lua"]},
                {dd, [], [
                    ~"The flagship end-to-end Lua example. Read it to see a full ",
                    ~"game, not a snippet."
                ]}
            ]},

            {h2, [], [~"Client SDKs"]},
            {p, [], [
                ~"One per engine, all talking to asobi over WebSocket + REST: ",
                {a, [{href, ~"/godot"}, az_navigate], [~"Godot"]},
                ~", ",
                {a, [{href, ~"/defold"}, az_navigate], [~"Defold"]},
                ~", ",
                {a, [{href, ~"/unity"}, az_navigate], [~"Unity"]},
                ~", ",
                {a, [{href, ~"/unreal"}, az_navigate], [~"Unreal"]},
                ~", ",
                {a, [{href, ~"/js"}, az_navigate], [~"JS/TS"]},
                ~", ",
                {a, [{href, ~"/dart"}, az_navigate], [~"Dart/Flutter"]},
                ~", and ",
                {a, [{href, ~"/lua"}, az_navigate], [~"asobi_lua"]},
                ~" itself for server-side scripting."
            ]},

            {h2, [], [~"The commercial layer"]},
            {p, [], [
                {strong, [], [~"asobi.dev Cloud "]},
                ~"is the managed hosting layer, opening later in 2026. Same binary ",
                ~"you can self-host today, with opinionated ops and flat ",
                ~"per-container pricing. Join the waitlist at ",
                {a, [{href, ~"/cloud"}, az_navigate], [~"asobi.dev/cloud"]},
                ~". If we disappear, the open-source pieces above are enough ",
                ~"to run your game forever \x{2014} see ",
                {a, [{href, ~"https://github.com/widgrensit/asobi/blob/main/guides/exit.md"}], [
                    ~"exit.md"
                ]},
                ~" for the runbook."
            ]},

            {h2, [], [~"Which one do I start with?"]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"\"I want to write Lua.\" "]},
                    ~"\x{2192} ",
                    {code, [], [~"asobi_lua"]},
                    ~". Pull the Docker image, write ",
                    {code, [], [~"match.lua"]},
                    ~", ",
                    {code, [], [~"docker compose up"]},
                    ~"."
                ]},
                {li, [], [
                    {strong, [], [~"\"I want to write Erlang.\" "]},
                    ~"\x{2192} ",
                    {code, [], [~"asobi"]},
                    ~". Add it to ",
                    {code, [], [~"rebar.config"]},
                    ~", implement the ",
                    {code, [], [~"asobi_match"]},
                    ~" behaviour."
                ]},
                {li, [], [
                    {strong, [], [~"\"I want both.\" "]},
                    ~"\x{2192} ",
                    {code, [], [~"asobi_lua"]},
                    ~" hosts your Lua code and is itself built on the ",
                    {code, [], [~"asobi"]},
                    ~" library. You can drop into an Erlang behaviour for a hot ",
                    ~"loop without leaving the process."
                ]},
                {li, [], [
                    {strong, [], [~"\"I just want hosting.\" "]},
                    ~"\x{2192} self-host ",
                    {code, [], [~"asobi_lua"]},
                    ~" today, or join the ",
                    {a, [{href, ~"/cloud"}, az_navigate], [~"cloud waitlist"]},
                    ~"."
                ]}
            ]},

            {h2, [], [~"Concepts, not projects"]},
            {p, [], [
                ~"These are vocabulary, not repositories. You'll see them throughout ",
                ~"the docs:"
            ]},
            {'dl', [{class, ~"docs-glossary"}], [
                {dt, [], [~"Match"]},
                {dd, [], [
                    ~"A short-lived gameplay session. 2 to N players, finite ",
                    ~"duration, result persisted. Runs as a ",
                    {code, [], [~"gen_server"]},
                    ~" under a supervisor."
                ]},

                {dt, [], [~"World"]},
                {dd, [], [
                    ~"A long-lived persistent environment. Players come and go, ",
                    ~"state persists across disconnects. Think MMO zone, town, ",
                    ~"dungeon."
                ]},

                {dt, [], [~"Zone"]},
                {dd, [], [
                    ~"A spatial partition inside a world. Used for sharding large ",
                    ~"worlds into loadable chunks."
                ]},

                {dt, [], [~"Session"]},
                {dd, [], [
                    ~"A player's authenticated connection. Survives reconnection ",
                    ~"with a session token."
                ]},

                {dt, [], [~"Tenant"]},
                {dd, [], [
                    ~"A studio or account in the managed cloud. You don't see ",
                    ~"this when self-hosting."
                ]},

                {dt, [], [~"Game"]},
                {dd, [], [
                    ~"The product you're shipping. One game may have many match ",
                    ~"modes, worlds, and tenants."
                ]}
            ]},
            {p, [], [
                ~"When two words compete (e.g. ",
                {em, [], [~"match"]},
                ~" vs ",
                {em, [], [~"room"]},
                ~", ",
                {em, [], [~"world"]},
                ~" vs ",
                {em, [], [~"realm"]},
                ~"), asobi uses the first one."
            ]}
        ]}
    ).
