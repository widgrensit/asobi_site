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
    body := fun(() -> arizona_template:template())
}.

-export_type([post/0]).

-spec all() -> [post()].
all() ->
    Posts = [
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
            body => fun post_why_erlang/0
        }
    ],
    lists:sort(fun(#{date := A}, #{date := B}) -> A >= B end, Posts).

-spec by_slug(binary()) -> {ok, post()} | not_found.
by_slug(Slug) ->
    case [P || #{slug := S} = P <- all(), S =:= Slug] of
        [Post | _] -> {ok, Post};
        [] -> not_found
    end.

%%----------------------------------------------------------------------
%% Post bodies
%%----------------------------------------------------------------------

-spec post_why_erlang() -> arizona_template:template().
post_why_erlang() ->
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
