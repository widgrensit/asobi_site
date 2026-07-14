-module(asobi_site_docs_quickstart_unity_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-qs-unity", title => ~"Unity quickstart — Asobi docs"},
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
                ~" / Quick start - Unity"
            ]},
            {h1, [], [~"Quick start - Unity"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Connect a Unity 2021.3+ project to a running Asobi server in about five minutes. ",
                ~"Don't have a server yet? Run the ",
                {a, [{href, ~"/docs/quickstart"}, az_navigate], [~"server quickstart"]},
                ~" first - it gives you a backend on localhost:8084 with a ",
                {code, [], [~"default"]},
                ~" match mode, which is what this page connects to."
            ]},

            {h2, [], [~"1. Install the SDK"]},
            {p, [], [
                ~"In Unity: ",
                {strong, [], [
                    ~"Window \x{2192} Package Manager \x{2192} + \x{2192} Add package from git URL"
                ]},
                ~", paste ",
                {code, [], [~"https://github.com/widgrensit/asobi-unity.git"]},
                ~" (append ",
                {code, [], [~"#v0.1.0"]},
                ~" or a later tag to pin). ",
                {code, [], [~"Asobi"]},
                ~" then appears under Packages in the Project window."
            ]},

            {h2, [], [~"2. Where this code lives"]},
            {p, [], [
                ~"Everything below goes on one ",
                {strong, [], [~"MonoBehaviour"]},
                ~" in your scene, split across Unity's lifecycle methods:"
            ]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"Start()"]},
                    ~" - authenticate, subscribe to events, connect, and queue (in that order)."
                ]},
                {li, [], [
                    {code, [], [~"Update()"]},
                    ~" - read input and send it, once per frame."
                ]},
                {li, [], [
                    {code, [], [~"OnDestroy()"]},
                    ~" - unsubscribe, so handlers don't leak across scene reloads."
                ]}
            ]},
            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Threading. "]},
                    ~"Realtime events fire on a ",
                    {strong, [], [~"background thread"]},
                    ~". Logging is fine, but the moment a handler touches a ",
                    {code, [], [~"UnityEngine.Object"]},
                    ~" (a ",
                    {code, [], [~"Transform"]},
                    ~", ",
                    {code, [], [~"GameObject"]},
                    ~", ...) you must marshal to the main thread first, or Unity throws \"can only be called from the main thread\". Copy the ",
                    {code, [], [~"UnityMainThread"]},
                    ~" helper from the ",
                    {a, [{href, ~"https://github.com/widgrensit/asobi-unity-demo"}], [~"demo"]},
                    ~" and wrap those calls in ",
                    {code, [], [~"UnityMainThread.Enqueue(() => ...)"]},
                    ~"."
                ]}
            ]},

            {h2, [], [~"3. The complete client"]},
            {p, [], [
                ~"Realtime events deliver the ",
                {strong, [], [~"raw WebSocket JSON"]},
                ~" as a string - parse the fields you need with ",
                {code, [], [~"JsonUtility"]},
                ~" (simple shapes) or Newtonsoft (nested). The whole flow:"
            ]},
            code(
                ~"csharp",
                ~"""
using System;
using Asobi;
using UnityEngine;

public class AsobiClientBehaviour : MonoBehaviour
{
    public string Host = "localhost";
    public int    Port = 8084;

    private AsobiClient _client;

    // Events are raw JSON; pull out just the fields you need.
    [Serializable] private struct Matched { public string match_id; }

    private async void Start()
    {
        _client = new AsobiClient(Host, port: Port);

        // 1. Authenticate. await it before connecting - the WebSocket uses
        //    this session. (Production: use a platform provider.)
        await _client.Auth.RegisterAsync("player1", "secret123", "Player One");

        // 2. Subscribe BEFORE connecting so you don't miss early events.
        _client.Realtime.OnMatchmakerMatched += OnMatched;
        _client.Realtime.OnMatchState        += OnState;

        // 3. Open the WebSocket, then queue. "default" is the mode your
        //    server's match.lua registers.
        await _client.Realtime.ConnectAsync();
        await _client.Matchmaker.AddAsync("default");
    }

    private async void OnMatched(string rawJson)
    {
        // Queuing matched you; join before state flows.
        var m = JsonUtility.FromJson<Matched>(rawJson);
        await _client.Realtime.JoinMatchAsync(m.match_id);
    }

    private void OnState(string rawJson)
    {
        // Server's authoritative tick. Touching a Transform/GameObject here?
        // Wrap it in UnityMainThread.Enqueue(...) first.
        Debug.Log($"state: {rawJson}");
    }

    private void Update()
    {
        // Send input each frame a key is held. Fire-and-forget.
        if (Input.GetKey(KeyCode.RightArrow))
            _ = _client.Realtime.SendMatchInputAsync("{\"action\":\"move\",\"x\":1,\"y\":0}");
    }

    private void OnDestroy()
    {
        if (_client == null) return;
        _client.Realtime.OnMatchmakerMatched -= OnMatched;
        _client.Realtime.OnMatchState        -= OnState;
    }
}
"""
            ),

            {h2, [], [~"4. What each part does, and when"]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Authenticate first (in Start). "]},
                    ~"The WebSocket authenticates with your session, so ",
                    {code, [], [~"await"]},
                    ~" ",
                    {code, [], [~"RegisterAsync"]},
                    ~" before you connect. Auth is rate-limited to 5/sec per IP - bursting returns ",
                    {code, [], [~"429 rate_limited"]},
                    ~". See ",
                    {a, [{href, ~"/docs/security/auth"}, az_navigate], [~"Auth & rate limiting"]},
                    ~"."
                ]},
                {li, [], [
                    {strong, [], [~"Subscribe before Connect/Add (in Start). "]},
                    ~"Add your ",
                    {code, [], [~"+="]},
                    ~" handlers, then ",
                    {code, [], [~"ConnectAsync()"]},
                    ~" and ",
                    {code, [], [~"Matchmaker.AddAsync(\"default\")"]},
                    ~". The sequential ",
                    {code, [], [~"await"]},
                    ~"s make the ordering explicit."
                ]},
                {li, [], [
                    {strong, [], [~"Join on OnMatchmakerMatched. "]},
                    ~"Parse ",
                    {code, [], [~"match_id"]},
                    ~" from the raw JSON and call ",
                    {code, [], [~"JoinMatchAsync"]},
                    ~". Without the join, ",
                    {code, [], [~"OnMatchState"]},
                    ~" never fires."
                ]},
                {li, [], [
                    {strong, [], [~"Send input from Update. "]},
                    ~"Gather ",
                    {code, [], [~"Input"]},
                    ~" and call ",
                    {code, [], [~"SendMatchInputAsync"]},
                    ~". It is fire-and-forget; the next ",
                    {code, [], [~"OnMatchState"]},
                    ~" reflects the server's response."
                ]},
                {li, [], [
                    {strong, [], [~"Unsubscribe in OnDestroy. "]},
                    ~"The ",
                    {code, [], [~"-="]},
                    ~" pairs stop handler leaks when the scene reloads."
                ]}
            ]},
            {p, [], [
                {strong, [], [~"WebGL is not supported"]},
                ~" - the underlying ",
                {code, [], [~"ClientWebSocket"]},
                ~" is unavailable on the WebGL runtime. Standalone, Android, and iOS (Mono or IL2CPP) all work."
            ]},

            {h2, [], [~"What's next"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/unity"}], [~"Full SDK reference"]},
                    ~" - every method on every namespace."
                ]},
                {li, [], [
                    {a, [{href, ~"https://github.com/widgrensit/asobi-unity-demo"}], [
                        ~"asobi-unity-demo"
                    ]},
                    ~" - a working arena shooter (main-thread marshaling, input in ",
                    {code, [], [~"Update"]},
                    ~", subscribe/unsubscribe)."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/lua/api"}, az_navigate], [~"game.* Lua API"]},
                    ~" - write the server-side gameplay your client connects to."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/tutorials/hot-reload"}, az_navigate], [
                        ~"Live-edit your game"
                    ]}
                ]}
            ]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
