-module(asobi_site_blog_posts).
-include_lib("arizona/include/arizona_stateless.hrl").

%% Blog post registry. Each post is a map with metadata; the body is a
%% function returning an arizona template so posts can use the same
%% rich HTML helpers as the rest of the site.

-export([all/0, by_slug/1]).

-type post() :: #{
    slug := binary(),
    title := binary(),
    lede := binary(),
    date := binary(),
    tags := [binary()],
    reading_time := binary(),
    body := fun((az:bindings()) -> az:template())
}.

-export_type([post/0]).

-spec all() -> [post()].
all() ->
    Posts = [
        #{
            slug => ~"meet-asobi-indie-multiplayer",
            title => ~"Meet Asobi: the multiplayer backend for indie 2D games",
            lede =>
                ~"""
                Godot, Defold, LÖVE, Phaser, Flame+Flutter. Five engines, one backend. Apache-2, Lua-scripted, self-host or managed. Here's the wedge and why the runtime makes it possible.
                """,
            date => ~"2026-04-28",
            tags => [~"positioning", ~"indie"],
            reading_time => ~"4 min",
            body => fun post_meet_asobi_indie_multiplayer/1
        },
        #{
            slug => ~"why-erlang-for-game-backends",
            title => ~"Why I'm building a game backend in Erlang",
            lede =>
                ~"""
                A game server is a phone switch with better graphics. Here's why the runtime that runs 40% of telecom is the right substrate for multiplayer games — and what that lets Asobi do that nothing else on the market does.
                """,
            date => ~"2026-04-15",
            tags => [~"engineering", ~"manifesto"],
            reading_time => ~"6 min",
            body => fun post_why_erlang/1
        },
        #{
            slug => ~"migrating-from-hathora",
            title => ~"Hathora shuts down May 5. Here's how to move to Asobi.",
            lede =>
                ~"""
                Hathora ends game hosting on 2026-05-05 after its acquisition by an AI company. If you're running a game on it, you have two weeks. We wrote a migration guide, and we'll help you ship before the deadline.
                """,
            date => ~"2026-04-21",
            tags => [~"migration", ~"hathora"],
            reading_time => ~"5 min",
            body => fun post_migrating_from_hathora/1
        }
    ],
    lists:sort(fun(#{date := A}, #{date := B}) -> A >= B end, Posts).

-spec by_slug(binary()) -> {ok, post()} | not_found.
by_slug(Slug) ->
    case lists:search(fun(#{slug := S}) -> S =:= Slug end, all()) of
        {value, Post} -> {ok, Post};
        false -> not_found
    end.

%%----------------------------------------------------------------------
%% Post bodies
%%----------------------------------------------------------------------

-spec post_meet_asobi_indie_multiplayer(az:bindings()) -> az:template().
post_meet_asobi_indie_multiplayer(_Bindings) ->
    ?html(
        {'div', [], [
            {p, [], [
                ~"""
                Indie multiplayer is having a moment. Solo devs and two-person studios are shipping multiplayer games on engines nobody used to market a backend at: Godot, Defold, LÖVE, Phaser, Flame. Asobi is the backend for that wave, and this post is the pitch.
                """
            ]},
            {p, [], [~"The 4-second version:"]},
            {blockquote, [], [
                {p, [], [
                    {strong, [], [~"Asobi is the multiplayer backend for indie 2D games."]},
                    ~" Godot, Defold, LÖVE, Phaser, Flame+Flutter. Apache-2, Lua-scripted, polyglot clients, self-host or managed."
                ]}
            ]},

            {h2, [], [~"What it is"]},
            {p, [], [
                ~"""
                One runtime that handles matches, matchmaker, lobbies, chat, leaderboards, economy, IAP, voting, phases, seasons, and spatial zones. Apache-2. One Docker container plus Postgres. Game logic is Lua (hot-reloadable) or any language that can speak the REST/WebSocket API.
                """
            ]},
            {p, [], [
                ~"""
                Seven client SDKs are live today: Godot, Defold, Unity, Unreal, TypeScript, Dart, and Flame. LÖVE and Phaser land in May — the README has the live status.
                """
            ]},
            {p, [], [
                ~"""
                Three things make it work. Matches run as lightweight processes — microseconds to spawn, ~15KB each — so a single node holds tens of thousands of them at idle cost near zero. Game logic is Lua via a pure-Erlang interpreter, hot-reloadable in flight: push a new script and in-flight matches drain on the old version while new matches bind the new one. Every match is supervised, so a bug in one player's logic can't take down the others. On a single mid-sized node: 83K WebSocket msg/sec at 3,500 concurrent connections, p99 RTT 6.5ms.
                """
            ]},

            {h2, [], [~"Who it's for"]},
            {p, [], [
                ~"""
                Solo devs and small teams shipping 2D multiplayer. Turn-based, party, casual, MMO zones, roguelike, co-op — anything that fits over a WebSocket. If your game is a twitch FPS that needs per-match dedicated UDP servers, Asobi isn't the whole answer; pair it with a UDP relay for physics and let Asobi handle everything else.
                """
            ]},
            {p, [], [
                ~"""
                The five wedge engines aren't a grab-bag. They share a profile: solo-friendly, 2D-capable, indie-first. None of them have a backend that takes them seriously today.
                """
            ]},

            {h2, [], [~"\"Does this work for 3D?\""]},
            {p, [], [
                ~"Yes. The runtime is dimension-agnostic — spatial zones take whatever coordinates you give them, and Unity + Unreal SDKs ship today. The ",
                {em, [], [~"indie 2D"]},
                ~" framing is where we're leading because that's where the underserved gap is. If you're shipping a 3D Godot game or a co-op Unity title and want hot-reloadable Lua matches, Asobi fits — we're just not building the marketing around 3D first."
            ]},

            {h2, [], [~"What's next"]},
            {p, [], [
                ~"""
                LÖVE and Phaser SDKs land in May — the README has the live status. Beyond that: a local dev emulator with a Studio UI is in progress, managed cloud is in private testing, and a content cadence around tutorials for each engine is planned. Specifics will land here as they ship, not before.
                """
            ]},
            {p, [], [
                ~"If indie multiplayer is what you're working on right now, the ",
                {a, [{href, ~"https://discord.gg/vYSfYYyXpu"}], [~"Discord"]},
                ~" is the fastest channel — that's where the day-to-day happens. The ",
                {a, [{href, ~"https://github.com/widgrensit/asobi"}], [~"code is on GitHub"]},
                ~", and ",
                {a, [{href, ~"/cloud"}, az_navigate], [~"asobi.dev/cloud"]},
                ~" is the waitlist for the managed version when it's ready."
            ]},
            {p, [], [
                ~"""
                A backend built for indies, on a runtime built for nine-nines telecom. It's a strange pairing. It's also the reason it works.
                """
            ]}
        ]}
    ).

-spec post_why_erlang(az:bindings()) -> az:template().
post_why_erlang(_Bindings) ->
    ?html(
        {'div', [], [
            {p, [], [
                ~"""
                I've been writing Erlang for over a decade. Most of it in regulated industries — trading, telecom, places where downtime costs real money and the BEAM is taken seriously. Now I'm building a game backend on it. Here's why that's not as strange as it sounds.
                """
            ]},

            {h2, [], [~"A game server is a phone switch"]},
            {p, [], [
                ~"""
                Strip away the pretty pixels and a multiplayer game server is doing the same job as a telecom switch: thousands of long-lived sessions, tiny messages flying in every direction, strict tail-latency budgets, and the same fatal failure mode — if one session crashes, the others must not notice.
                """
            ]},
            {p, [], [
                ~"""
                The BEAM was literally built for this. Ericsson shipped it to run AXD301 switches at nine-nines availability in the late 1990s. Every primitive — lightweight processes, preemptive scheduling, per-process heaps, supervision trees, hot code loading — exists because phone calls are expensive to drop.
                """
            ]},
            {p, [], [
                ~"""
                A player in a multiplayer match has exactly the same lifecycle as a call: connect, do stuff, disconnect. When the match crashes because of a bug in one player's logic, you want the other players' matches unaffected. When you deploy a fix, you want in-flight matches to drain on the old code and new matches to start on the new code. Erlang does both natively.
                """
            ]},

            {h2, [], [~"What that lets Asobi do"]},
            {p, [], [
                ~"""
                Three features fall out of the runtime that I genuinely don't know how to replicate sanely in Node, Go, or Rust:
                """
            ]},

            {h3, [], [~"1. Hot-reload Lua in a live match"]},
            {p, [], [
                ~"Asobi runs game logic in Lua (via ",
                {code, [], [~"luerl"]},
                ~", a pure-Erlang Lua interpreter). When you push a new version of a game script, Asobi hot-loads it. In-flight matches keep running on the old version until they end; new matches bind the new one. No dropped connections. No redeploy window. No ",
                {em, [], [~"\"we'll patch tomorrow at 3 AM\""]},
                ~"."
            ]},
            {p, [], [
                ~"""
                Every non-BEAM backend I've looked at either drops sessions on deploy or requires a blue-green dance that costs you 5x the infrastructure. Erlang gives it to you for free.
                """
            ]},

            {h3, [], [~"2. Lazy zones"]},
            {p, [], [
                ~"""
                An Asobi world is made of zones — rooms, arenas, regions. Each one is a process. When the first player enters a zone, the process is spawned. When the last player leaves, it exits. You pay for zones that have players, not for every zone that might have players. On a single mid-sized VPS you can host tens of thousands of zones at idle cost near zero.
                """
            ]},
            {p, [], [
                ~"""
                Spawning a process in BEAM costs microseconds and a few kilobytes. Spawning a container costs seconds and hundreds of megabytes. Those two numbers are the whole reason the indie pricing math on managed game backends has historically been broken.
                """
            ]},

            {h3, [], [~"3. Crash isolation you don't have to think about"]},
            {p, [], [
                ~"Every match in Asobi is a supervised process. If your game script throws an error, the supervisor restarts the match (or ends it cleanly) and nothing else on the node notices. You don't write ",
                {code, [], [~"try/catch"]},
                ~" around every handler. You don't defensively validate. You write the happy path and let the runtime handle the rest."
            ]},
            {p, [], [
                ~"""
                This is the part that sounds like marketing until you've actually debugged a production Node server that took down 1,000 connections because one unhandled promise rejection propagated.
                """
            ]},

            {h2, [], [~"What it costs"]},
            {p, [], [
                ~"""
                Erlang is not free. The syntax is unusual. The ecosystem is smaller than Node or Go. Hiring is harder. Numeric code is slower (though rarely a bottleneck for game-server work — the CPU-heavy loops live in the client). Deployment tooling is less polished.
                """
            ]},
            {p, [], [
                ~"""
                Asobi pays those costs so you don't have to. The public API is Lua. You write game logic in 50 lines of Lua and Asobi runs it on a telecom-grade substrate. If you want to drop into Erlang for a hot module, you can. If you never want to see Erlang, you don't have to.
                """
            ]},

            {h2, [], [~"Why now"]},
            {p, [], [
                ~"""
                Indie multiplayer is having a moment. Godot, Defold, Flame, and Unity hobby licences are putting real multiplayer ambitions into the hands of solo devs and two-person studios. The existing backend market serves this segment badly: Nakama and Colyseus are great but assume you want to operate a server; Photon is proprietary and billed per CCU; SpacetimeDB is brilliant but reinvents the database. There's a gap in the €9-30/month managed tier for a backend that just works, scales to a modest player base, and lets you iterate at the speed of Lua hot-reload.
                """
            ]},
            {p, [], [
                ~"Asobi is aimed at that gap. Erlang is how we fit the price point."
            ]},

            {h2, [], [~"What's next"]},
            {p, [], [
                ~"""
                This is the first post in an ongoing devlog. Next up: hot-reloading Lua in a live match with actual screenshots, and a deep dive on lazy zones. If you want the TL;DR in video form, I'm starting a YouTube series alongside these posts — subscribe to either and I'll keep the other one in sync.
                """
            ]},
            {p, [], [
                ~"In the meantime: ",
                {a, [{href, ~"https://github.com/widgrensit/asobi"}], [
                    ~"the code is on GitHub"
                ]},
                ~", and the ",
                {a, [{href, ~"https://discord.gg/vYSfYYyXpu"}], [~"Discord"]},
                ~" is the fastest way to ask questions. I'd love to know what multiplayer you're trying to ship."
            ]}
        ]}
    ).

-spec post_migrating_from_hathora(az:bindings()) -> az:template().
post_migrating_from_hathora(_Bindings) ->
    ?html(
        {'div', [], [
            {p, [], [
                ~"On 2026-03-04 Hathora announced it was ",
                {a,
                    [
                        {href,
                            ~"https://www.pcworld.com/article/3105695/ai-is-coming-for-your-online-gaming-servers-next.html"}
                    ],
                    [
                        ~"ending its game-hosting service"
                    ]},
                ~" after being acquired by an AI-inference company. The shutdown date is 2026-05-05. Stormgate, Splitgate 2, and Predecessor are among the casualties. If you're running on ",
                {code, [], [~"hathora.dev"]},
                ~" or ",
                {code, [], [~"hathora.cloud"]},
                ~", you have about two weeks."
            ]},

            {p, [], [
                ~"We've written a ",
                {a,
                    [
                        {href,
                            ~"https://github.com/widgrensit/asobi/blob/main/guides/migrate-from-hathora.md"}
                    ],
                    [
                        ~"full migration guide"
                    ]},
                ~". This post is the short version, the pitch, and an open offer: we will prioritise Hathora-migration help in the ",
                {a, [{href, ~"https://discord.gg/vYSfYYyXpu"}], [~"Discord"]},
                ~" through May."
            ]},

            {h2, [], [~"The short version"]},
            {p, [], [
                ~"Asobi is an open-source, Apache-2, self-hostable multiplayer backend. One container, one Postgres, no Kubernetes. It has the pieces Hathora had (matchmaker, lobbies, rooms, regions) plus the pieces Hathora didn't (hot-reloadable Lua, voting, phases, seasons, spatial zones, Godot/Defold SDKs)."
            ]},
            {p, [], [
                ~"Managed cloud opens later in 2026. For the next fortnight the path is self-host. A small Hetzner box (CX22, €4/mo) comfortably holds thousands of concurrent players. You can run it on your laptop while you port, then move it somewhere real when you're ready."
            ]},

            {h2, [], [~"Concept map"]},
            {p, [], [
                ~"Hathora's nouns line up with ours almost cleanly:"
            ]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Application"]},
                    ~" → asobi deployment (one container per env)."
                ]},
                {li, [], [
                    {strong, [], [~"Room / Process"]},
                    ~" → Match (a BEAM process per match, thousands per container)."
                ]},
                {li, [], [
                    {strong, [], [~"Lobby"]},
                    ~" → Matchmaker ticket + match in \"waiting\" phase."
                ]},
                {li, [], [
                    {strong, [], [~"Matchmaker 2.0"]},
                    ~" → ",
                    {code, [], [~"asobi_matchmaker"]},
                    ~" with pluggable strategies (fill / skill / your own)."
                ]},
                {li, [], [
                    {strong, [], [~"HathoraClient.loginAnonymous"]},
                    ~" → ",
                    {code, [], [~"POST /api/v1/auth/register"]},
                    ~" with a client-generated username+password (no anonymous flag today; the guide has details)."
                ]},
                {li, [], [
                    {strong, [], [~"getConnectionInfo(roomId)"]},
                    ~" → one long-lived WebSocket per player. First frame is ",
                    {code, [], [~"session.connect"]},
                    ~" with the session token; the server pushes ",
                    {code, [], [~"match.matched"]},
                    ~" when matchmaking resolves."
                ]}
            ]},

            {h2, [], [~"Two paths"]},

            {h3, [], [~"A. Keep your existing game server"]},
            {p, [], [
                ~"If you have a lot of C# / Go / Node server code, keep running it in its own container on Hetzner, Fly, or Scaleway. Let Asobi handle auth, matchmaking, lobbies, leaderboards, and persistence. Your server talks to Asobi with an API key. This is the fast path — usually a week of work."
            ]},

            {h3, [], [~"B. Fold the game into Lua"]},
            {p, [], [
                ~"Rewrite your tick/input/state logic as a ",
                {code, [], [~"match.lua"]},
                ~" file. The callbacks are ",
                {code, [], [~"init / join / leave / handle_input / tick / get_state"]},
                ~". For most Hathora games this is a few hundred lines. You get hot-reload for free (edit + save + live matches update), and you delete a container from your ops budget."
            ]},

            {h2, [], [~"Cost comparison"]},
            {p, [], [
                ~"A small-indie Hathora game was typically $200–800/month on process-hours. The same game on Asobi at Hetzner is €5–20/month of infra. That's not a typo. The BEAM gets you tens of thousands of cheap processes per node; Hathora was paying container-per-match overhead."
            ]},

            {h2, [], [~"What Asobi doesn't do"]},
            {p, [], [
                ~"Be honest with yourself before committing:"
            ]},
            {ul, [], [
                {li, [], [
                    ~"No UDP transport. WebSocket/TCP only. If you're a twitch FPS, pair Asobi with a UDP relay for physics and use Asobi for everything else."
                ]},
                {li, [], [
                    ~"No auto-multi-region. Deploy one container per region yourself."
                ]},
                {li, [], [
                    ~"No client-side prediction / rollback primitives yet. On the roadmap."
                ]},
                {li, [], [
                    ~"Pre-1.0 API. Minor breaks possible before 1.0."
                ]}
            ]},

            {h2, [], [~"What to do today"]},
            {ol, [], [
                {li, [], [
                    {code, [], [~"git clone"]},
                    ~" the ",
                    {a, [{href, ~"https://github.com/widgrensit/asobi_lua"}], [~"asobi_lua"]},
                    ~" repo and run ",
                    {code, [], [~"docker compose up"]},
                    ~". Register a player. Confirm it works."
                ]},
                {li, [], [
                    ~"Pick one SDK call in your client (",
                    {code, [], [~"loginAnonymous"]},
                    ~" is the usual first) and port it."
                ]},
                {li, [], [
                    ~"Join the ",
                    {a, [{href, ~"https://discord.gg/vYSfYYyXpu"}], [~"Discord"]},
                    ~" #migrations channel. We'll sanity-check your plan."
                ]},
                {li, [], [
                    ~"Set a cutover date before 2026-05-05."
                ]}
            ]},

            {p, [], [
                ~"We'd rather you land on Asobi than drown in a 72-hour panic next month. Even if you don't migrate to us, ",
                {a,
                    [
                        {href,
                            ~"https://github.com/widgrensit/asobi/blob/main/guides/migrate-from-hathora.md"}
                    ],
                    [~"the full guide"]},
                ~" has enough concept-mapping to help you migrate to any backend. Good luck, and ping us if you need a hand."
            ]}
        ]}
    ).
