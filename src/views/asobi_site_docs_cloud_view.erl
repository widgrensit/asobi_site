-module(asobi_site_docs_cloud_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(#{id => ~"docs-cloud", title => ~"Cloud — Asobi docs"}, Bindings),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Cloud"
            ]},
            {h1, [], [~"Cloud hosting"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Managed Asobi is live at ",
                {a, [{href, ~"https://console.asobi.dev"}], [~"console.asobi.dev"]},
                ~". This walkthrough takes you from nothing to a running game: install the ",
                {code, [], [~"asobi"]},
                ~" CLI, log in, create an environment, deploy your Lua, and point your client at it. ",
                ~"EU-hosted, and the core is open source, so you can self-host any time."
            ]},

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Before you start. "]},
                    ~"You need a game's server-side Lua (at minimum a ",
                    {code, [], [~"match.lua"]},
                    ~") and a browser signed in to ",
                    {a, [{href, ~"https://console.asobi.dev"}], [~"console.asobi.dev"]},
                    ~". No Lua yet? Follow the ",
                    {a, [{href, ~"/docs/lua/callbacks"}, az_navigate], [~"server Lua guide"]},
                    ~" to write your first match module, then come back here to ship it."
                ]}
            ]},

            {h2, [], [~"1. Install the CLI"]},
            {p, [], [
                ~"The ",
                {code, [], [~"asobi"]},
                ~" CLI is a single Go binary. Build it from source (Go 1.26+):"
            ]},
            code(
                ~"bash",
                ~"""
git clone https://github.com/widgrensit/asobi-cli
cd asobi-cli
go build -o bin/asobi ./cmd/asobi
ln -s $(pwd)/bin/asobi ~/bin/asobi
"""
            ),
            {p, [], [
                ~"Check it is on your path:"
            ]},
            code(
                ~"bash",
                ~"""
asobi health
"""
            ),

            {h2, [], [~"2. Log in"]},
            {p, [], [
                ~"Authenticate the CLI against the control plane. This uses a browser device-code flow, so no passwords or keys are typed into the terminal:"
            ]},
            code(
                ~"bash",
                ~"""
asobi login
"""
            ),
            {p, [], [
                ~"It opens the approval page at ",
                {code, [], [~"console.asobi.dev/dashboard/cli/login"]},
                ~", where you are already signed in. Approve the session there and pick your tenant, game, and environment. ",
                ~"The CLI stores its credentials in ",
                {code, [], [~"~/.asobi/credentials.json"]},
                ~" (owner-only permissions) and you are ready to go."
            ]},
            {p, [], [
                ~"Confirm the session any time with:"
            ]},
            code(
                ~"bash",
                ~"""
asobi whoami
"""
            ),

            {h2, [], [~"3. Create an environment"]},
            {p, [], [
                ~"An environment is your own isolated engine with its own database. Create one named ",
                {code, [], [~"prod"]},
                ~":"
            ]},
            code(
                ~"bash",
                ~"""
asobi create prod
"""
            ),
            {p, [], [
                ~"Pick a size with ",
                {code, [], [~"--size"]},
                ~" (",
                {code, [], [~"xs"]},
                ~", ",
                {code, [], [~"s"]},
                ~", ",
                {code, [], [~"m"]},
                ~", or ",
                {code, [], [~"l"]},
                ~") if you want more headroom than the default:"
            ]},
            code(
                ~"bash",
                ~"""
asobi create prod --size s
"""
            ),

            {h2, [], [~"4. Deploy your Lua"]},
            {p, [], [
                ~"Point the CLI at the directory holding your ",
                {code, [], [~".lua"]},
                ~" files and deploy them to the environment. The directory argument defaults to the current directory:"
            ]},
            code(
                ~"bash",
                ~"""
asobi deploy prod game/
"""
            ),
            {p, [], [
                ~"The CLI zips your Lua, uploads it, and returns a generation number and a ",
                {code, [], [~"sha256"]},
                ~". The running engine hot-reloads the new code into the live game: no restart, no dropped connections. Edit a file, run ",
                {code, [], [~"asobi deploy prod game/"]},
                ~" again, and the next match picks up the change while in-flight matches finish on the old code."
            ]},
            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Closing the loop. "]},
                    ~"For the callbacks that make up a ",
                    {code, [], [~"match.lua"]},
                    ~" (",
                    {code, [], [~"init"]},
                    ~", ",
                    {code, [], [~"join"]},
                    ~", ",
                    {code, [], [~"handle_input"]},
                    ~", ",
                    {code, [], [~"tick"]},
                    ~"), see the ",
                    {a, [{href, ~"/docs/lua/callbacks"}, az_navigate], [~"server Lua guide"]},
                    ~" and the ",
                    {a, [{href, ~"/docs/lua/api"}, az_navigate], [~"game.* API reference"]},
                    ~"."
                ]}
            ]},

            {h2, [], [~"5. Manage your environments"]},
            {p, [], [
                ~"List everything you have, with each environment's status and endpoint:"
            ]},
            code(
                ~"bash",
                ~"""
asobi envs
"""
            ),
            {p, [], [
                ~"Start, stop, and delete them as you go:"
            ]},
            code(
                ~"bash",
                ~"""
asobi start prod
asobi stop prod
asobi delete prod
"""
            ),
            {p, [], [
                {code, [], [~"asobi config show"]},
                ~" prints the CLI's current context, and ",
                {code, [], [~"asobi health"]},
                ~" checks the engine is reachable."
            ]},

            {h2, [], [~"6. Connect your client"]},
            {p, [], [
                ~"Once an environment is started it has a public endpoint of the form ",
                {code, [], [~"<game-slug>-<env-name>.<tenant-slug>.asobi.dev"]},
                ~", for example ",
                {code, [], [~"pong-prod.acme.asobi.dev"]},
                ~". Copy the actual Endpoint shown in the dashboard or in ",
                {code, [], [~"asobi envs"]},
                ~" rather than assembling it by hand."
            ]},
            {p, [], [
                ~"Your client SDK connects straight to that endpoint over a secure WebSocket on port 443. In Defold:"
            ]},
            code(
                ~"lua",
                ~"""
local asobi = require("asobi.client")
self.client = asobi.create("pong-prod.acme.asobi.dev", 443, true)
"""
            ),
            {p, [], [
                ~"Swap in your own endpoint. The ",
                {a, [{href, ~"/docs/quickstart/defold"}, az_navigate], [~"Defold quickstart"]},
                ~" has the full client code: authenticate, join the matchmaker, and render the server's authoritative state."
            ]},

            {h2, [], [~"How it works"]},
            {p, [], [
                ~"The CLI talks to the Asobi control plane at ",
                {a, [{href, ~"https://console.asobi.dev"}], [~"console.asobi.dev"]},
                ~". Each environment is your own single-tenant engine with its own database, isolated from every other tenant."
            ]},
            {p, [], [
                {code, [], [~"asobi deploy"]},
                ~" uploads a new generation of your Lua to the control plane, which pushes it to your engine. The engine hot-reloads it into the running game on the BEAM, so a deploy never restarts the server or drops a connected player."
            ]},
            {p, [], [
                ~"Your client SDK connects directly to the environment's endpoint over WebSocket; game traffic does not go through the control plane. Asobi is single-node by design: one environment is one engine, kept simple and predictable."
            ]},

            {'div', [{class, ~"docs-callout docs-callout-success"}], [
                {p, [], [
                    {strong, [], [~"That's the loop. "]},
                    ~"Write Lua, ",
                    {code, [], [~"asobi deploy"]},
                    ~", and your client connects to a live, hot-reloadable game with no infrastructure to run yourself."
                ]}
            ]},

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/lua/callbacks"}, az_navigate], [~"Server Lua guide"]},
                    ~" - write the match callbacks you deploy."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/quickstart/defold"}, az_navigate], [~"Defold quickstart"]},
                    ~" - the full client side of the loop."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/self-host"}, az_navigate], [~"Self-host"]},
                    ~" - run the same engine on your own infrastructure."
                ]}
            ]},

            {'div', [{class, ~"docs-cta-row"}], [
                {a, [{href, ~"https://console.asobi.dev"}, {class, ~"btn btn-primary"}], [
                    ~"Open the console \x{2192}"
                ]},
                {a, [{href, ~"/docs/self-host"}, {class, ~"btn btn-secondary"}, az_navigate], [
                    ~"Or self-host"
                ]}
            ]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
