-module(asobi_site_docs_learn_install_sdk_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-learn-install-sdk", title => ~"Install the client SDK - Asobi docs"},
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
                ~" / Learn / Install the SDK"
            ]},
            {h1, [], [~"Install the client SDK"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Add the Asobi SDK for your engine, learn when it speaks REST versus WebSocket, and point it at your server - the app builds and imports the SDK."
            ]},
            {p, [], [
                ~"In step 1 you booted the server bundle. Now you fit the other half: the client SDK your game talks to it with. This step installs the SDK and aims it at a server. You do not connect yet - that is step 3."
            ]},

            {h2, [], [~"How and when the client talks"]},
            {p, [], [~"The SDK uses two transports, and it picks the right one for you."]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"REST (HTTP request/response). "]},
                    ~"One-shot calls where you ask and wait for an answer: register, login, guest sign-in, read a leaderboard, load a cloud save. Used for anything that is not a live game frame."
                ]},
                {li, [], [
                    {strong, [], [~"WebSocket (realtime push). "]},
                    ~"One long-lived connection for the game loop: you send intent (a move), the server decides, and the server pushes state back to every client. Match and world frames only arrive over the WebSocket."
                ]}
            ]},
            {p, [], [
                ~"The rule underneath both: the client sends intent, the server decides, the server broadcasts state. The client never mutates authoritative state directly."
            ]},
            {p, [], [
                ~"REST comes first in every flow (you authenticate over REST to get a token), then you open the WebSocket. Step 3 covers the handshake; the full frame surface is in the ",
                {a, [{href, ~"/docs/protocols/websocket"}, az_navigate], [
                    ~"WebSocket protocol guide"
                ]},
                ~"."
            ]},

            {h2, [], [~"Point the client at your server"]},
            {p, [], [
                ~"This is the ",
                {strong, [], [~"only"]},
                ~" place the client differs between managed cloud and self-hosting. Every SDK call after this - auth, match, world, input, state - is byte-for-byte identical on both. Only the base server URL changes."
            ]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Cloud"]},
                    ~" (",
                    {code, [], [~"console.asobi.dev"]},
                    ~" / ",
                    {code, [], [~"asobi deploy"]},
                    ~"): your environment gets a TLS hostname of the form ",
                    {code, [], [~"{game}-{env}.{tenant}.asobi.dev"]},
                    ~", e.g. ",
                    {code, [], [~"pong-prod.acme.asobi.dev"]},
                    ~", served over HTTPS/WSS on port 443. Copy it from the environment page in the console."
                ]},
                {li, [], [
                    {strong, [], [~"Self-hosted"]},
                    ~": your own release of ",
                    {code, [], [~"asobi"]},
                    ~" + ",
                    {code, [], [~"asobi_lua"]},
                    ~" on your own host, plain HTTP/WS on port 8084 by default, e.g. ",
                    {code, [], [~"localhost:8084"]},
                    ~" in dev. See ",
                    {a, [{href, ~"/docs/self-host"}, az_navigate], [~"self-hosting"]},
                    ~" and ",
                    {a, [{href, ~"/docs/configuration"}, az_navigate], [~"configuration"]},
                    ~" for the ",
                    {code, [], [~"ASOBI_*"]},
                    ~" knobs."
                ]}
            ]},
            {p, [], [
                ~"Cloud means TLS on (",
                {code, [], [~"use_ssl"]},
                ~" / ",
                {code, [], [~"useSsl"]},
                ~" / ",
                {code, [], [~"https"]},
                ~"/",
                {code, [], [~"wss"]},
                ~"); self-host in dev means TLS off. Nothing else moves."
            ]},
            {p, [], [
                ~"The tabs below are in this order: Defold, Godot, Unity, Unreal, Dart/Flame, JavaScript, LOVE."
            ]},

            {p, [], [
                {strong, [], [~"Defold. "]},
                ~"Add both dependencies to ",
                {code, [], [~"game.project"]},
                ~", then Project -> Fetch Libraries. Pin to a tag; ",
                {code, [], [~"main"]},
                ~" is unstable. Register realtime callbacks from a ",
                {code, [], [~".script"]},
                ~" in ",
                {code, [], [~"main.collection"]},
                ~" - Defold invalidates the WS callback when its owning script unloads."
            ]},
            {p, [], [
                {strong, [], [~"Godot. "]},
                ~"Copy ",
                {code, [], [~"addons/asobi/"]},
                ~" into your project (or add as a submodule at a tag), then tick Asobi under Project Settings -> Plugins and reload. The plugin registers an ",
                {code, [], [~"Asobi"]},
                ~" autoload singleton. Point the autoload at your server; ",
                {code, [], [~"host"]},
                ~", ",
                {code, [], [~"port"]},
                ~", ",
                {code, [], [~"use_ssl"]},
                ~" are exported on the client."
            ]},
            {p, [], [
                {strong, [], [~"Unity. "]},
                ~"Install via Window -> Package Manager -> + -> Add package from git URL. Create the client with ",
                {code, [], [~"new AsobiClient(host, port, useSsl)"]},
                ~". Realtime events fire on a background thread - marshal to the main thread before touching ",
                {code, [], [~"UnityEngine.Object"]},
                ~". WebGL is not supported (the SDK uses ",
                {code, [], [~"ClientWebSocket"]},
                ~")."
            ]},
            {p, [], [
                {strong, [], [~"Unreal. "]},
                ~"Clone into your project's ",
                {code, [], [~"Plugins/"]},
                ~" directory, regenerate project files, then enable Asobi SDK under Edit -> Plugins -> Networking. Create the client and set the base URL (a full URL, scheme included)."
            ]},
            {p, [], [
                {strong, [], [~"Dart/Flame. "]},
                ~"Add the package (pure Dart, works with Flutter, Flame, and standalone Dart). Create the client with ",
                {code, [], [~"AsobiClient(host, {port, useSsl})"]},
                ~"."
            ]},
            {p, [], [
                {strong, [], [~"JavaScript. "]},
                ~"Install from GitHub (builds via the package's ",
                {code, [], [~"prepare"]},
                ~" script). Node 22+ for the global ",
                {code, [], [~"WebSocket"]},
                ~"/",
                {code, [], [~"fetch"]},
                ~". asobi-js is a thin transport client: the REST/auth surface and the WebSocket take full URLs, so cloud versus self-host is just the scheme and host."
            ]},
            {p, [], [
                {strong, [], [~"LOVE. "]},
                ~"Drop the ",
                {code, [], [~"asobi/"]},
                ~" directory into your LÖVE project root, alongside ",
                {code, [], [~"main.lua"]},
                ~". Pure Lua, no LuaRocks. For ",
                {code, [], [~"wss://"]},
                ~" (cloud TLS) you need ",
                {code, [], [~"luasec"]},
                ~" on the path - LÖVE does not bundle it. Create the client with ",
                {code, [], [~"asobi.new({host, port, use_ssl})"]},
                ~". ",
                {code, [], [~"client.realtime:update()"]},
                ~" must be called every frame from ",
                {code, [], [~"love.update(dt)"]},
                ~" once you reach the realtime steps, or no callbacks fire."
            ]},

            {p, [], [~"Add the dependency or package for your engine:"]},
            ?stateless(asobi_site_tabbed_code, render, #{
                id => ~"learn-install-sdk-a",
                tabs => [
                    #{
                        label => ~"Defold",
                        lang => ~"text",
                        body =>
                            ~"""
                            [project]
                            dependencies#0 = https://github.com/widgrensit/asobi-defold/archive/refs/tags/v1.2.1.zip
                            dependencies#1 = https://github.com/defold/extension-websocket/archive/refs/tags/4.2.2.zip
                            """
                    },
                    #{
                        label => ~"Godot",
                        lang => ~"bash",
                        body =>
                            ~"""
                            git submodule add -b v0.6.1 https://github.com/widgrensit/asobi-godot.git vendor/asobi-godot
                            ln -s ../vendor/asobi-godot/addons/asobi addons/asobi
                            """
                    },
                    #{
                        label => ~"Unity",
                        lang => ~"text",
                        body =>
                            ~"""
                            https://github.com/widgrensit/asobi-unity.git
                            """
                    },
                    #{
                        label => ~"Unreal",
                        lang => ~"bash",
                        body =>
                            ~"""
                            cd YourProject/Plugins
                            git clone https://github.com/widgrensit/asobi-unreal.git AsobiSDK
                            """
                    },
                    #{
                        label => ~"Dart/Flame",
                        lang => ~"bash",
                        body =>
                            ~"""
                            dart pub add asobi
                            """
                    },
                    #{
                        label => ~"JavaScript",
                        lang => ~"bash",
                        body =>
                            ~"""
                            npm install github:widgrensit/asobi-js
                            """
                    },
                    #{
                        label => ~"LOVE",
                        lang => ~"text",
                        body =>
                            ~"""
                            my_game/
                            ├── main.lua
                            ├── conf.lua
                            └── asobi/
                            """
                    }
                ]
            }),

            {p, [], [
                ~"Then create the client and point it at your server. Only the base URL changes:"
            ]},
            ?stateless(asobi_site_tabbed_code, render, #{
                id => ~"learn-install-sdk-b",
                tabs => [
                    #{
                        label => ~"Defold",
                        lang => ~"lua",
                        body =>
                            ~"""
                            local asobi = require("asobi.client")

                            local client = asobi.create("localhost", 8084)                       -- self-hosted
                            -- local client = asobi.create("pong-prod.acme.asobi.dev", 443, true)  -- cloud (TLS)
                            """
                    },
                    #{
                        label => ~"Godot",
                        lang => ~"gdscript",
                        body =>
                            ~"""
                            func _ready() -> void:
                                Asobi.host = "localhost"     # self-hosted
                                Asobi.port = 8084
                                # Asobi.host = "pong-prod.acme.asobi.dev"  # cloud (TLS)
                                # Asobi.port = 443
                                # Asobi.use_ssl = true
                            """
                    },
                    #{
                        label => ~"Unity",
                        lang => ~"csharp",
                        body =>
                            ~"""
                            using Asobi;

                            var client = new AsobiClient("localhost", port: 8084);                            // self-hosted
                            // var client = new AsobiClient("pong-prod.acme.asobi.dev", port: 443, useSsl: true); // cloud (TLS)
                            """
                    },
                    #{
                        label => ~"Unreal",
                        lang => ~"cpp",
                        body =>
                            ~"""
                            #include "AsobiClient.h"

                            UAsobiClient* Client = NewObject<UAsobiClient>();
                            Client->SetBaseUrl(TEXT("http://localhost:8084"));                 // self-hosted
                            // Client->SetBaseUrl(TEXT("https://pong-prod.acme.asobi.dev"));   // cloud (TLS)
                            """
                    },
                    #{
                        label => ~"Dart/Flame",
                        lang => ~"dart",
                        body =>
                            ~"""
                            import 'package:asobi/asobi.dart';

                            final client = AsobiClient('localhost', port: 8084);                             // self-hosted
                            // final client = AsobiClient('pong-prod.acme.asobi.dev', port: 443, useSsl: true); // cloud (TLS)
                            """
                    },
                    #{
                        label => ~"JavaScript",
                        lang => ~"typescript",
                        body =>
                            ~"""
                            import { Asobi, AsobiWebSocket } from "@widgrensit/asobi";

                            const sdk = new Asobi({ baseUrl: "http://localhost:8084" });                      // self-hosted REST
                            const ws = new AsobiWebSocket({ url: "ws://localhost:8084/ws", token });          // self-hosted WS

                            // Cloud (TLS):
                            // const sdk = new Asobi({ baseUrl: "https://pong-prod.acme.asobi.dev" });
                            // const ws = new AsobiWebSocket({ url: "wss://pong-prod.acme.asobi.dev/ws", token });
                            """
                    },
                    #{
                        label => ~"LOVE",
                        lang => ~"lua",
                        body =>
                            ~"""
                            local asobi = require("asobi")

                            local client = asobi.new({host = "localhost", port = 8084})                                  -- self-hosted
                            -- local client = asobi.new({host = "pong-prod.acme.asobi.dev", port = 443, use_ssl = true})  -- cloud (TLS)
                            """
                    }
                ]
            }),

            checkpoint([
                {p, [], [
                    ~"Build and run your project (or the editor) with the SDK added and the client created:"
                ]},
                {ul, [], [
                    {li, [], [
                        ~"The SDK import resolves - no missing-package or missing-",
                        {code, [], [~"require"]},
                        ~" error."
                    ]},
                    {li, [], [
                        ~"Constructing the client with your base URL compiles/runs and does not throw."
                    ]}
                ]},
                {p, [], [
                    ~"You should reach your first frame (or, for a console target, your first line) with the SDK linked in. If the import fails, re-check the install step for your engine above. No network call happens yet - creating the client does not open a connection."
                ]}
            ]),

            nextstep(
                ~"/docs/learn/connect",
                ~"Step 3 - Connect, and prove it talks",
                ~"Fire session.connect, wait for session.connected, and log connected, player_id=..."
            )
        ]}
    ).

checkpoint(Children) ->
    ?html(
        {'div', [{class, ~"docs-callout docs-callout-success"}], [
            {p, [], [{strong, [], [~"Checkpoint"]}]} | Children
        ]}
    ).

nextstep(Href, Label, Blurb) ->
    ?html(
        {'div', [{class, ~"docs-next"}], [
            {p, [], [
                {strong, [], [~"Next: "]},
                {a, [{href, Href}, az_navigate], [Label]}
            ]},
            {p, [], [Blurb]}
        ]}
    ).
