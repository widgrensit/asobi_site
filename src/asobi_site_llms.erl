%% Content for /llms.txt (https://llmstxt.org, spec v2).
%%
%% The audience is a coding agent a developer has pointed at asobi.dev while
%% writing a game against it, not a search crawler: Google documents that it
%% ignores this file, and no lab documents reading one.
%%
%% Two rules keep it worth serving:
%%   1. Descriptions are hand-written. Every peer file that auto-extracts a
%%      first sentence ships visible garbage ("Documentation for Welcome to
%%      Clanforge"), and a description that distinguishes nothing is worse
%%      than none because the agent pays tokens for it either way.
%%   2. Coverage is enforced, not remembered. Every routed path is either
%%      indexed below or named in exclusions/0, and asobi_site_router_SUITE
%%      fails the build otherwise. A stale index is worse than no index: an
%%      agent trusts it as a complete map and stops looking.
-module(asobi_site_llms).

-export([summary/0, notes/0, sections/0, exclusions/0]).

-type entry() :: {Path :: binary(), Title :: binary(), Description :: binary()}.

-export_type([entry/0]).

-spec summary() -> [binary()].
summary() ->
    [
        ~"asobi is an open-source multiplayer game backend on Erlang/OTP: authoritative matches",
        ~"and persistent worlds, matchmaking, guest and account auth, chat, economy and",
        ~"leaderboards, with client SDKs for Unity, Unreal, Godot, Defold, LOVE, Flame, Dart and",
        ~"JavaScript. Game logic is written in Lua and hot-reloads into a running match without",
        ~"disconnecting players. Self-host it, or use the managed cloud."
    ].

%% The highest-leverage part of the file. These are the mistakes an agent
%% makes about asobi when it reasons from other game backends instead of
%% reading, and each one costs a developer a debugging session.
-spec notes() -> [binary()].
notes() ->
    [
        ~"Game logic is authored in Lua. Erlang is the secondary path, needed only when embedding asobi as an OTP library; do not write Erlang callbacks unless asked.",
        ~"Self-hosting needs the asobi server image and Postgres. It needs no account, no API key and no cloud signup. Asobi Cloud is separate and optional.",
        ~"One mode lives in match.lua. Several modes are declared in the config.lua manifest, never in match.lua.",
        ~"Matches are per-session and end; worlds are persistent and zone-partitioned. Choosing the wrong one is the most common design mistake.",
        ~"The server is authoritative. Clients send input and render state; they never own it.",
        ~"Do not state a version from memory. asobi tags a release on every merge to main: https://github.com/widgrensit/asobi/releases"
    ].

-spec sections() -> [{binary(), [entry()]}].
sections() ->
    [
        {~"Start here", [
            {
                ~"/docs",
                ~"Documentation home",
                ~"What asobi is, and the two ways to get a game running."
            },
            {
                ~"/docs/quickstart",
                ~"Quick start (self-host)",
                ~"A tiny Lua game, a running server and a connected client in under five minutes, with no signup or keys."
            },
            {
                ~"/docs/cloud",
                ~"Quick start (cloud)",
                ~"Eight steps from installing the CLI to a deployed environment on console.asobi.dev."
            },
            {
                ~"/docs/concepts",
                ~"Core concepts",
                ~"The primitives, shown in Lua: games and modes, matches, worlds and zones, matchmaking, voting, phases, chat, economy, reconnection, hot reload."
            },
            {
                ~"/docs/architecture",
                ~"Architecture",
                ~"One Erlang/OTP release holds the backend, the Lua runtime and the operator console. Supervision tree, session and match lifecycles, the RPC seam."
            },
            {
                ~"/docs/glossary",
                ~"Glossary",
                ~"Which repo is which, and what asobi means as a node, as a Hex library, and next to the commercial layer."
            }
        ]},
        {~"Learn: build your first backend (in order)", [
            {
                ~"/docs/learn/orientation",
                ~"Step 0. What you are building",
                ~"The destination: the movement core of a top-down arena, the two pieces you write, and why the server owns state."
            },
            {
                ~"/docs/learn/bundle",
                ~"Step 1. Your backend bundle",
                ~"What you actually ship to asobi. Scaffold the bundle and boot it on your own machine."
            },
            {
                ~"/docs/learn/install-sdk",
                ~"Step 2. Install the client SDK",
                ~"Add the SDK for your engine and learn when it speaks REST and when it speaks WebSocket."
            },
            {
                ~"/docs/learn/connect",
                ~"Step 3. Connect",
                ~"Open the realtime socket and prove the server accepted the handshake, and nothing else."
            },
            {
                ~"/docs/learn/identity",
                ~"Step 4. Guest versus account",
                ~"Give a player identity with no sign-up form, and make it survive a restart."
            },
            {
                ~"/docs/learn/storage",
                ~"Step 5. Storing data",
                ~"Persist a value from Lua and read it back after a restart, without writing SQL."
            },
            {
                ~"/docs/learn/match-setup",
                ~"Step 6. Set up a match",
                ~"Declare a mode in match.lua, or several in the config.lua manifest, so a client has something to join."
            },
            {
                ~"/docs/learn/match-join",
                ~"Step 7. Connect to a match",
                ~"Get two clients into one session. Register the state handler before joining, or you miss the first frame."
            },
            {
                ~"/docs/learn/match-run",
                ~"Step 8. Run a match",
                ~"Close the input-to-state loop so one client's click moves the fighter on every client."
            },
            {
                ~"/docs/learn/match-end",
                ~"Step 9. End a match",
                ~"Decide server-side that a round is over, compute a result and deliver it to both clients."
            },
            {
                ~"/docs/learn/world-create",
                ~"Step 10. Create a world",
                ~"Register a persistent space, and the test for when a world beats a per-session match."
            },
            {
                ~"/docs/learn/world-join",
                ~"Step 11. Connect to a world",
                ~"Join a world and receive its initial snapshot."
            },
            {
                ~"/docs/learn/world-run",
                ~"Step 12. Run a world",
                ~"Per-tick deltas streamed to every subscriber as fighters move."
            },
            {
                ~"/docs/learn/world-end",
                ~"Step 13. End a world",
                ~"Finish from post_tick or when the space empties; every client receives world.finished."
            },
            {
                ~"/docs/learn/where-next",
                ~"Where next",
                ~"Which reference page covers each thing the guided track deliberately skipped."
            }
        ]},
        {~"Engine quickstarts", [
            {
                ~"/docs/quickstart/unity",
                ~"Unity",
                ~"C#, Unity 2021.3 and later, installed as a package. Complete client against a localhost backend."
            },
            {
                ~"/docs/quickstart/unreal",
                ~"Unreal",
                ~"C++ runtime plugin AsobiSDK, Unreal 5.4 and later. Every call is also BlueprintCallable."
            },
            {
                ~"/docs/quickstart/godot",
                ~"Godot",
                ~"GDScript, Godot 4.x, installed as an editor addon."
            },
            {
                ~"/docs/quickstart/defold",
                ~"Defold",
                ~"Pure Lua library dependency, no native extensions. Complete boot.script."
            },
            {
                ~"/docs/quickstart/love2d",
                ~"LOVE",
                ~"Vendor the Lua SDK, connect in love.load and pump it in love.update."
            },
            {
                ~"/docs/quickstart/flame",
                ~"Flame",
                ~"The flame_asobi binding. Hold one shared client and drive components from server state."
            },
            {
                ~"/docs/quickstart/dart",
                ~"Dart and Flutter",
                ~"Plain Dart and Flutter apps. Async/await calls with stream-based realtime events."
            },
            {
                ~"/docs/quickstart/js",
                ~"JavaScript and TypeScript",
                ~"Browser and Node 22 and later. Event-emitter socket API with auto-reconnect."
            }
        ]},
        {~"Writing game logic in Lua", [
            {
                ~"/docs/lua/api",
                ~"game.* API reference",
                ~"The game global the runtime exposes to every script: messaging, identity, chat, storage, economy, leaderboards, spatial queries, zones, terrain."
            },
            {
                ~"/docs/lua/callbacks",
                ~"Game module callbacks",
                ~"init, join, leave, handle_input, tick and get_state, and exactly when the runtime calls each. Maps 1:1 to the asobi_match behaviour."
            },
            {
                ~"/docs/lua/cookbook",
                ~"Lua cookbook",
                ~"Short self-contained recipes for common gameplay tasks, each assuming a Lua game module is already loaded."
            },
            {
                ~"/docs/lua/bots",
                ~"Bots",
                ~"Server-side players that fill a queue and take the same handle_input path a human does. No fake clients, no network hop."
            },
            {
                ~"/docs/tutorials/hot-reload",
                ~"Live-edit a running match",
                ~"Swap match.lua while a match is running. Players stay connected, scores stay intact, the next tick runs the new code."
            },
            {
                ~"/docs/tutorials/tic-tac-toe",
                ~"Tic-tac-toe tutorial",
                ~"A complete two-player game end to end: state, inputs, win detection, broadcasting and reconnect."
            },
            {
                ~"/docs/samples",
                ~"Samples",
                ~"Runnable games, two commands each, with their backends bundled. Self-hosting them is free and needs no account."
            }
        ]},
        {~"Build", [
            {
                ~"/docs/matchmaking",
                ~"Matchmaking",
                ~"Ticket submission, per-mode strategy modules, formation failure, backfill, and playing with friends."
            },
            {
                ~"/docs/lobbies",
                ~"Lobbies",
                ~"There is no Lobby type. A lobby is a state: pick a waiting match or a world used as a hub, and wire it up."
            },
            {
                ~"/docs/world-server",
                ~"World server",
                ~"Shared continuous space split into zone processes: interest-based broadcast, spawn templates, snapshots, subscriptions."
            },
            {
                ~"/docs/large-worlds",
                ~"Large worlds",
                ~"Big tile maps: on-demand zone creation above grid_size 100, zone lifecycle callbacks and serving terrain."
            },
            {
                ~"/docs/phases",
                ~"Phases and seasons",
                ~"Lobby to play to results inside one session, and seasons with checkpoints spanning many."
            },
            {
                ~"/docs/voting",
                ~"Voting",
                ~"In-session group decisions: window types, spectator and async ballots, templates, and majority-tyranny mitigations."
            },
            {
                ~"/docs/economy",
                ~"Economy and IAP",
                ~"Wallets, transactions, item definitions, the store catalogue and player inventory, with error codes."
            },
            {
                ~"/docs/leaderboards",
                ~"Leaderboards and tournaments",
                ~"Scoring modes and time windows; tournaments add seasonal resets, brackets and prize distribution."
            },
            {
                ~"/docs/authentication",
                ~"Authentication",
                ~"Password, OIDC social, Steam, and guest accounts upgradable in place. Refresh, rotation, logout and WebSocket auth."
            }
        ]},
        {~"Reference", [
            {
                ~"/docs/protocols/rest",
                ~"REST API",
                ~"Every /api/v1 endpoint with request and response shapes, across sixteen resource groups."
            },
            {
                ~"/docs/protocols/websocket",
                ~"WebSocket protocol",
                ~"One socket at /ws, the JSON envelope, and every frame the server sends or accepts."
            },
            {
                ~"/docs/configuration",
                ~"Configuration",
                ~"Both surfaces: environment variables for the image, and sys.config for the Hex package."
            },
            {
                ~"/docs/errors",
                ~"Errors and status codes",
                ~"Stable reason atoms per endpoint, the HTTP class each maps to, and WebSocket frame errors."
            },
            {
                ~"/docs/erlang/api",
                ~"Erlang API (advanced)",
                ~"Only for embedding asobi as an OTP library with no Lua. The rest of the docs are Lua-first."
            },
            {
                ~"/docs/extensions",
                ~"Extensions",
                ~"Add an OTP application that contributes RPC handlers, HTTP routes, operator actions and Lua bindings."
            },
            {
                ~"/docs/changelog",
                ~"Changelog and versioning",
                ~"Every merge to main is tagged and published, so releases are small, frequent and reversible."
            }
        ]},
        {~"Tooling", [
            {
                ~"/docs/tools/cli",
                ~"asobi CLI",
                ~"One static binary that scaffolds a game, runs a local backend and deploys bundles to managed environments."
            },
            {
                ~"/docs/tools/dev",
                ~"asobi dev (live loop)",
                ~"A full backend plus Lua hot reload from one command, with no credentials."
            },
            {
                ~"/docs/tools/testing",
                ~"Test harness",
                ~"A fixed known-good backend for SDK and bot authors, so wire-protocol drift breaks one test in one place."
            },
            {
                ~"/docs/tools/multiple-players",
                ~"Testing with multiple players",
                ~"Two clients on one machine sign in as the same player unless you do this. Read it before debugging matchmaking."
            }
        ]},
        {~"Operate", [
            {
                ~"/docs/self-host",
                ~"Self-host",
                ~"Docker Compose, a single server, or Kubernetes, plus backups, rate limits and upgrades."
            },
            {
                ~"/docs/console",
                ~"Operator console",
                ~"The console at /console and the ops API at /api/v1/ops, both on the port the game already uses."
            },
            {
                ~"/docs/observability",
                ~"Observability",
                ~"Telemetry events and JSON logs. There is deliberately no metrics endpoint, dashboard or alerting rule."
            },
            {
                ~"/docs/clustering",
                ~"Clustering",
                ~"Several nodes over BEAM distribution and pg. The scaling unit is a world, not a node."
            },
            {
                ~"/docs/performance",
                ~"Performance tuning",
                ~"Tick budget, zone sizing, delta compression, BEAM knobs, profiling and load testing."
            },
            {
                ~"/docs/benchmarks",
                ~"Benchmarks",
                ~"Measured single-node WebSocket and REST throughput, with the bottlenecks named."
            }
        ]},
        {~"Security", [
            {
                ~"/docs/security",
                ~"Security overview",
                ~"Reading order for the security pages, and how to report a vulnerability."
            },
            {
                ~"/docs/security/threat-model",
                ~"Threat model",
                ~"Trust boundaries on a single node: Erlang distribution, public ETS, and what the supervisors tolerate."
            },
            {
                ~"/docs/security/auth",
                ~"Auth and rate limiting",
                ~"Bearer sessions, StoreKit 2 JWS, Steam tickets, guest device verifiers, and per-request bounds."
            },
            {
                ~"/docs/security/known-limitations",
                ~"Known limitations",
                ~"What the runtime does not enforce, and where that responsibility lands instead."
            },
            {
                ~"/docs/security/lua-sandbox",
                ~"Lua sandbox",
                ~"What the hardened Luerl state removes and replaces, per-callback budgets, and the decode depth cap."
            },
            {
                ~"/docs/security/lua-trust-model",
                ~"Lua trust model",
                ~"Scripts at /app/game are trusted like the binary. The sandbox is not a boundary against an attacker who writes them."
            },
            {
                ~"/docs/security/lua-known-limitations",
                ~"Lua known limitations",
                ~"Resource bounds, deployment hygiene and logging gaps in the Lua sandbox."
            },
            {
                ~"/docs/best-practices",
                ~"Best practices",
                ~"Keep the server authoritative, fail closed, deploy by hot reload, shard at the application level."
            }
        ]},
        {~"Migrating from another backend", [
            {
                ~"/docs/migrate/nakama",
                ~"From Nakama",
                ~"Concept map and port order, including the reasons not to move if self-hosted Nakama already works."
            },
            {
                ~"/docs/migrate/hathora",
                ~"From Hathora",
                ~"Hathora ended game hosting on 2026-05-05. A running deployment today, then the full port in outline."
            },
            {
                ~"/docs/migrate/playfab",
                ~"From PlayFab",
                ~"For studios through the v2 migration, or watching the Azure bill climb as the product thins out."
            },
            {
                ~"/docs/comparison",
                ~"How asobi compares",
                ~"Feature matrix and runtime characteristics, including when to choose something else."
            },
            {
                ~"/docs/exit",
                ~"If asobi disappears",
                ~"Runbook for keeping a game alive if the company stops. What is covered, and what is not."
            },
            {
                ~"/docs/faq",
                ~"FAQ",
                ~"Seven questions, including which SDK to pick and whether to self-host or use managed cloud."
            }
        ]},
        {~"Optional", [
            {
                ~"/cloud",
                ~"Asobi Cloud",
                ~"Managed hosting in the EU, invite-only, with the open-source core as the exit path."
            },
            {~"/showcase", ~"Showcase", ~"Projects you can clone and run against a real backend."},
            {
                ~"/blog",
                ~"Blog",
                ~"Engineering notes and devlogs. RSS at https://asobi.dev/blog/rss.xml"
            },
            {~"/brand", ~"Brand assets", ~"Logos and splash screens, and what not to do with them."}
        ]}
    ].

%% Routed paths deliberately absent from llms.txt, each with the reason.
%% asobi_site_router_SUITE asserts this list plus sections/0 covers every
%% route, so a new page cannot be added without a decision being recorded.
-spec exclusions() -> [binary()].
exclusions() ->
    [
        %% The H1 and summary already say what the landing page says.
        ~"/",
        %% Marketing pages the docs supersede. Duplicate titles cost an agent
        %% a fetch to discover it already had the better page.
        ~"/demo",
        ~"/migrate-from-hathora",
        ~"/unreal",
        ~"/unity",
        ~"/godot",
        ~"/defold",
        ~"/dart",
        ~"/js",
        ~"/lua",
        %% Legal. Nothing an agent should reason from when writing game code.
        ~"/terms",
        ~"/cloud-terms",
        ~"/privacy",
        ~"/dpa",
        ~"/refunds",
        %% Not pages.
        ~"/heartbeat",
        ~"/blog/rss.xml",
        ~"/blog/:slug",
        ~"/docs/erlang/getting-started",
        ~"/llms.txt",
        ~"/robots.txt",
        ~"/sitemap.xml"
    ].
