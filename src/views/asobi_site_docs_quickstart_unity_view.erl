-module(asobi_site_docs_quickstart_unity_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-qs-unity", title => ~"Unity quickstart — Asobi docs"},
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
                ~" / Quick start \x{2014} Unity"
            ]},
            {h1, [], [~"Quick start \x{2014} Unity"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Connect a Unity 2021.3+ project to a running Asobi server in about five minutes. ",
                ~"You'll register a player, open a WebSocket, queue for a match, and receive server-authoritative state. ",
                ~"Don't have a server yet? Run the ",
                {a, [{href, ~"/docs/quickstart"}, az_navigate], [~"server quickstart"]},
                ~" first."
            ]},

            {h2, [], [~"1. Install the SDK"]},
            {p, [], [
                ~"In Unity: ",
                {strong, [], [
                    ~"Window \x{2192} Package Manager \x{2192} + \x{2192} Add package from git URL"
                ]},
                ~", paste:"
            ]},
            code(~"text", ~"https://github.com/widgrensit/asobi-unity.git"),
            {p, [], [
                ~"For pinned releases append ",
                {code, [], [~"#v0.1.0"]},
                ~" (or whichever tag you want). Verify the install via ",
                {code, [], [~"Asobi"]},
                ~" appearing under Packages in the Project window."
            ]},

            {h2, [], [~"2. Configure the client"]},
            {p, [], [~"Drop this on a bootstrap MonoBehaviour:"]},
            code(
                ~"csharp",
                ~"""
using Asobi;
using UnityEngine;

public class AsobiBoot : MonoBehaviour
{
    public string Host = "localhost";
    public int    Port = 8080;
    public bool   UseSsl = false;

    public AsobiClient Client { get; private set; }

    void Awake()
    {
        Client = new AsobiClient(Host, Port, useSsl: UseSsl);
        DontDestroyOnLoad(gameObject);
    }
}
"""
            ),

            {h2, [], [~"3. Authenticate"]},
            {p, [], [
                ~"For development, register a player by username/password. Production builds should use a platform provider \x{2014} see ",
                {a, [{href, ~"/docs/security/auth"}, az_navigate], [~"Auth & rate limiting"]},
                ~"."
            ]},
            code(
                ~"csharp",
                ~"""
async void Start()
{
    var auth = await Client.Auth.RegisterAsync("player1", "secret123", "Player One");
    Debug.Log($"Logged in as {Client.PlayerId}");
}
"""
            ),
            {p, [], [
                ~"Auth requests are rate-limited at 5/sec per IP \x{2014} bursting will return ",
                {code, [], [~"429 rate_limited"]},
                ~"."
            ]},

            {h2, [], [~"4. Open the WebSocket and queue"]},
            code(
                ~"csharp",
                ~"""
Client.Realtime.OnConnected += () => Debug.Log("WS connected");
Client.Realtime.OnMatchmakerMatched += data =>
    Debug.Log($"Matched: {data.MatchId} with {data.Players.Length} players");
Client.Realtime.OnMatchState += state =>
    Debug.Log($"Tick {state.Tick}: {state.Players.Count} players");

await Client.Realtime.ConnectAsync();
await Client.Realtime.AddToMatchmakerAsync("arena");
"""
            ),

            {h2, [], [~"5. Send input"]},
            code(
                ~"csharp",
                ~"""
// Movement input — the server runs your game module's handle_input callback.
await Client.Realtime.SendMatchInputAsync(
    "{\"action\":\"move\",\"x\":1,\"y\":0}");
"""
            ),
            {p, [], [
                ~"Input is fire-and-forget. The next ",
                {code, [], [~"OnMatchState"]},
                ~" frame will reflect the server's authoritative response."
            ]},

            {h2, [], [~"What's next"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/unity"}], [~"Full SDK reference"]},
                    ~" \x{2014} every method on every namespace."
                ]},
                {li, [], [
                    {a, [{href, ~"https://github.com/widgrensit/asobi-unity-demo"}], [
                        ~"asobi-unity-demo"
                    ]},
                    ~" \x{2014} a working multiplayer arena shooter."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/lua/api"}, az_navigate], [~"game.* Lua API"]},
                    ~" \x{2014} write the server-side gameplay your client connects to."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/tutorials/hot-reload"}, az_navigate], [
                        ~"Live-edit your game"
                    ]},
                    ~" \x{2014} change ",
                    {code, [], [~"match.lua"]},
                    ~" without reconnecting the client."
                ]}
            ]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
