-module(asobi_site_docs_tools_cli_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-tools-cli", title => ~"asobi CLI — Asobi docs"},
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
                ~" / asobi CLI"
            ]},
            {h1, [], [~"asobi CLI"]},
            {p, [{class, ~"docs-lede"}], [
                ~"A single static binary (",
                {code, [], [~"asobi"]},
                ~") that scaffolds a game, runs a local backend, and deploys Lua bundles to managed ",
                ~"environments. Running your own server? You only need ",
                {a, [{href, ~"/docs/tools/dev"}, az_navigate], [{code, [], [~"asobi dev"]}]},
                ~" and ",
                {code, [], [~"asobi config"]},
                ~"."
            ]},

            {h2, [], [~"Install"]},
            code(
                ~"bash",
                ~"""
# Linux / macOS
curl -fsSL https://raw.githubusercontent.com/widgrensit/asobi-cli/main/install.sh | sh

# Windows (PowerShell)
irm https://raw.githubusercontent.com/widgrensit/asobi-cli/main/install.ps1 | iex

# or: winget install widgrensit.asobi
"""
            ),
            {p, [], [
                ~"The installer drops the binary in ",
                {code, [], [~"~/.local/bin"]},
                ~" (or ",
                {code, [], [~"%LOCALAPPDATA%\\asobi\\bin"]},
                ~"). ",
                {code, [], [~"asobi upgrade"]},
                ~" self-updates to the latest release."
            ]},

            {h2, [], [~"From zero to deployed"]},
            code(
                ~"bash",
                ~"""
asobi init mygame          # scaffold lua/match.lua + README
cd mygame
asobi dev                  # local Docker backend on http://localhost:8084 (no account)
# edit lua/*.lua - the container hot-reloads, no restart

asobi login                # browser device-code auth to console.asobi.dev
asobi use <game>           # pick the active game (list them: asobi games)
asobi create prod          # create an environment (default size xs)
asobi deploy prod lua      # zip + deploy the lua/ dir to env "prod"
asobi health               # verify the engine
"""
            ),
            {p, [], [
                {code, [], [~"init --template"]},
                ~" takes a genre starter (",
                {code, [], [~"arena"]},
                ~", ",
                {code, [], [~"chat"]},
                ~", ",
                {code, [], [~"turn-based"]},
                ~", ",
                {code, [], [~"world"]},
                ~") or a full demo (",
                {code, [], [~"defold"]},
                ~", ",
                {code, [], [~"godot"]},
                ~", ",
                {code, [], [~"unity"]},
                ~", ",
                {code, [], [~"backend"]},
                ~")."
            ]},

            {h2, [], [~"Commands"]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"init [dir] [--template <name>]"]}, ~" - scaffold a starter."
                ]},
                {li, [], [
                    {code, [], [~"dev [--port N] [--dir <lua>]"]},
                    ~" - local Docker backend, hot-reload."
                ]},
                {li, [], [
                    {code, [], [~"login"]},
                    ~" / ",
                    {code, [], [~"logout"]},
                    ~" / ",
                    {code, [], [~"whoami"]},
                    ~" - device-code auth to the dashboard."
                ]},
                {li, [], [
                    {code, [], [~"games"]},
                    ~" / ",
                    {code, [], [~"use <slug>"]},
                    ~" - list and select the active game."
                ]},
                {li, [], [
                    {code, [], [~"create <name> [--size xs|s|m|l]"]},
                    ~" / ",
                    {code, [], [~"deploy <name> [dir]"]},
                    ~" - create and deploy environments."
                ]},
                {li, [], [
                    {code, [], [~"start"]},
                    ~" / ",
                    {code, [], [~"stop"]},
                    ~" / ",
                    {code, [], [~"resize --size <s>"]},
                    ~" / ",
                    {code, [], [~"delete"]},
                    ~" - manage an environment."
                ]},
                {li, [], [
                    {code, [], [~"envs"]},
                    ~" / ",
                    {code, [], [~"env list [--json]"]},
                    ~" - human table / scriptable list. ",
                    {code, [], [~"health [env]"]},
                    ~" - engine check."
                ]},
                {li, [], [
                    {code, [], [~"config set|show"]},
                    ~" - self-host: ",
                    {code, [], [~"config set url <engine>"]},
                    ~" and ",
                    {code, [], [~"config set api_key ak_..."]},
                    ~"."
                ]}
            ]},

            {h2, [], [~"Auth &amp; config"]},
            {p, [], [
                ~"Two paths. ",
                {strong, [], [~"Managed:"]},
                ~" ",
                {code, [], [~"asobi login"]},
                ~" runs an ECDH-encrypted browser device-code flow against ",
                {code, [], [~"console.asobi.dev"]},
                ~" and stores tokens in ",
                {code, [], [~"~/.asobi/credentials.json"]},
                ~" (mode 0600). ",
                {strong, [], [~"Self-host:"]},
                ~" skip login and set an ",
                {code, [], [~"ak_"]},
                ~" engine key with ",
                {code, [], [~"asobi config set"]},
                ~" (stored in ",
                {code, [], [~"~/.asobi/config.json"]},
                ~"). ",
                {code, [], [~"ASOBI_ACCESS_TOKEN"]},
                ~" overrides the stored token for CI."
            ]},

            {h2, [], [~"What's next"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/tools/dev"}, az_navigate], [~"asobi dev (live loop)"]}
                ]},
                {li, [], [{a, [{href, ~"/docs/cloud"}, az_navigate], [~"Deploy to managed cloud"]}]},
                {li, [], [{a, [{href, ~"/docs/self-host"}, az_navigate], [~"Self-host"]}]}
            ]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
