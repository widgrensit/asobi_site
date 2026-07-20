-module(asobi_site_docs_tools_dev_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-tools-dev", title => ~"asobi dev (live loop) — Asobi docs"},
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
                ~" / asobi dev"
            ]},
            {h1, [], [~"asobi dev - the live loop"]},
            {p, [{class, ~"docs-lede"}], [
                ~"One command brings up a full local backend and hot-reloads your Lua as you edit it - ",
                ~"no account, no credentials, no restart. This is the fastest inner loop for writing a game."
            ]},

            {h2, [], [~"Run it"]},
            code(
                ~"bash",
                ~"""
cd mygame          # a dir with a lua/ (or game/) folder of .lua files
asobi dev          # backend on http://localhost:8084, WS at /ws
"""
            ),
            {p, [], [
                ~"It resolves the Lua directory from ",
                {code, [], [~"--dir"]},
                ~", else ",
                {code, [], [~"lua/"]},
                ~", else ",
                {code, [], [~"game/"]},
                ~". Edit any ",
                {code, [], [~".lua"]},
                ~" file and the running engine reloads it in place - in-flight matches finish on the ",
                ~"old code, new matches use the new code. Ctrl+C stops the stack."
            ]},

            {h2, [], [~"What it does under the hood"]},
            {p, [], [
                {code, [], [~"asobi dev"]},
                ~" writes a managed Compose file to ",
                {code, [], [~".asobi/dev-compose.yml"]},
                ~" (regenerated each run) and runs it in the foreground. That stack is ",
                {code, [], [~"postgres:16"]},
                ~" plus ",
                {code, [], [~"ghcr.io/widgrensit/asobi_lua:latest"]},
                ~", with your Lua directory mounted read-only at ",
                {code, [], [~"/app/game"]},
                ~". The container - not the CLI - watches that volume and hot-reloads. It needs Docker ",
                ~"with Compose v2 running; there is no login or control-plane involvement."
            ]},

            {h2, [], [~"Flags"]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"--port N"]},
                    ~" - host + container port (default ",
                    {code, [], [~"8084"]},
                    ~")."
                ]},
                {li, [], [{code, [], [~"--dir <lua>"]}, ~" - explicit path to your Lua directory."]}
            ]},

            {h2, [], [~"What's next"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/tools/cli"}, az_navigate], [~"asobi CLI"]},
                    ~" - scaffold, then deploy what you built here."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/tutorials/hot-reload"}, az_navigate], [
                        ~"Live-edit your game (hot reload)"
                    ]}
                ]},
                {li, [], [{a, [{href, ~"/docs/lua/api"}, az_navigate], [~"game.* Lua API"]}]}
            ]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
