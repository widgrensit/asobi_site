-module(asobi_site_docs_learn_connect_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-learn-connect", title => ~"Connect - Asobi docs"},
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
                ~" / Learn / Connect"
            ]},
            {h1, [], [~"Step 3 - Connect, and prove it talks"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Goal: open the realtime socket and confirm the server accepted it, and nothing else."
            ]},
            {p, [], [
                ~"This is the confidence anchor. Before you register anything, match anyone, or move your fighter, you want one fact on your screen: the socket is up and the server knows who you are. That is the whole job of this step."
            ]},

            {h2, [], [~"The handshake"]},
            {p, [], [
                ~"The realtime channel is one WebSocket. The first frame your client sends is ",
                {code, [], [~"session.connect"]},
                ~" carrying your access token. The server replies with ",
                {code, [], [~"session.connected"]},
                ~" carrying your ",
                {code, [], [~"player_id"]},
                ~". That round trip is the proof. See the ",
                {a, [{href, ~"/docs/protocols/websocket"}, az_navigate], [
                    ~"WebSocket protocol guide"
                ]},
                ~" for the full frame surface."
            ]},
            {p, [], [
                ~"Every SDK does this handshake for you inside its connect call. Your job is to register a handler for ",
                {code, [], [~"session.connected"]},
                ~" first, then call connect, then read the ",
                {code, [], [~"player_id"]},
                ~" off the confirmation."
            ]},
            {p, [], [
                ~"You send intent, the server decides. Here the intent is \"let me in\", and ",
                {code, [], [~"session.connected"]},
                ~" is the server deciding yes."
            ]},

            {h2, [], [~"One thing differs: the base URL"]},
            {p, [], [
                ~"The only difference between managed cloud and self-hosting on this step is the URL you point the client at. The calls below are identical either way."
            ]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Cloud"]},
                    ~": use your environment's URL from the console at ",
                    {code, [], [~"console.asobi.dev"]},
                    ~" (a ",
                    {code, [], [~"wss://"]},
                    ~" address the platform issued when you deployed). The token comes from signing in against that same environment."
                ]},
                {li, [], [
                    {strong, [], [~"Self-hosted"]},
                    ~": your own release listens on port ",
                    {code, [], [~"8084"]},
                    ~" at ",
                    {code, [], [~"/ws"]},
                    ~", so ",
                    {code, [], [~"ws://<your-host>:8084/ws"]},
                    ~" (or ",
                    {code, [], [~"wss://"]},
                    ~" behind TLS). Default port and endpoint are in the ",
                    {a, [{href, ~"/docs/configuration"}, az_navigate], [~"configuration guide"]},
                    ~"."
                ]}
            ]},
            {p, [], [
                ~"Point the SDK at the right base URL and the rest of this page is the same on both."
            ]},

            {h2, [], [~"You need a token first"]},
            {p, [], [
                ~"Connect authenticates the socket, so the SDK must already be holding an access token. Do any auth call before connecting; the SDK stores the token on the client for you. For now a throwaway ",
                {code, [], [~"login"]},
                ~" or ",
                {code, [], [~"register"]},
                ~" is enough to get moving. Step 4 (Who is the player?) covers guest versus account properly, so do not overthink it here."
            ]},

            {h2, [], [~"Per-SDK"]},
            {p, [], [
                ~"Register the ",
                {code, [], [~"session.connected"]},
                ~" handler before you call connect, in every SDK."
            ]},

            {p, [], [
                {strong, [], [~"Defold. "]},
                {code, [], [~"connect()"]},
                ~" authenticates asynchronously, so wait for the ",
                {code, [], [~"connected"]},
                ~" callback before doing anything else (README example). Install is the SDK zip plus the ",
                {code, [], [~"extension-websocket"]},
                ~" dependency in ",
                {code, [], [~"game.project"]},
                ~" (README, Installation)."
            ]},
            {p, [], [
                {strong, [], [~"Godot. "]},
                ~"The ",
                {code, [], [~"connected"]},
                ~" signal fires with no arguments, so read the id from the auth response (",
                {code, [], [~"var resp := await Asobi.auth.login(...)"]},
                ~" in the README example) rather than from the signal. Log in before ",
                {code, [], [~"connect_to_server()"]},
                ~"."
            ]},
            {p, [], [
                {strong, [], [~"Unity. "]},
                {code, [], [~"OnConnected"]},
                ~" is an ",
                {code, [], [~"Action"]},
                ~" with no arguments; the confirmed id lives on ",
                {code, [], [~"client.PlayerId"]},
                ~" after authentication (AsobiClient.cs). Authenticate the client before ",
                {code, [], [~"ConnectAsync()"]},
                ~". Realtime events fire on a background thread, so marshal to the main thread before touching ",
                {code, [], [~"UnityEngine.Object"]},
                ~" (README threading note)."
            ]},
            {p, [], [
                {strong, [], [~"Unreal. "]},
                ~"Note the ordering caveat: ",
                {code, [], [~"OnConnected"]},
                ~" fires when the transport opens, which is ",
                {em, [], [~"before"]},
                ~" the auth handshake, so it is socket-open, not session-ready. There is no typed delegate for the post-auth ",
                {code, [], [~"session.connected"]},
                ~" reply in this SDK: only the transport-level ",
                {code, [], [~"OnConnected"]},
                ~" (which fires pre-auth) and the raw ",
                {code, [], [~"OnMessage"]},
                ~" catch-all. Call ",
                {code, [], [~"Authenticate(Token)"]},
                ~" from the ",
                {code, [], [~"OnConnected"]},
                ~" handler, and read the confirmed id from ",
                {code, [], [~"Client->GetPlayerId()"]},
                ~" (AsobiClient.h) once the account is known."
            ]},
            {p, [], [
                {strong, [], [~"Dart/Flame. "]},
                {code, [], [~"onConnected"]},
                ~" is a ",
                {code, [], [~"Stream<void>"]},
                ~", so the event carries no value; read the id from ",
                {code, [], [~"client.playerId"]},
                ~", which the SDK sets at auth (asobi_client.dart). The README example completes a ",
                {code, [], [~"Completer"]},
                ~" on this stream to await the connection."
            ]},
            {p, [], [
                {strong, [], [~"JavaScript. "]},
                ~"This SDK uses the raw wire event name (",
                {code, [], [~"session.connected"]},
                ~", with the fighter) and hands you the untyped payload, so ",
                {code, [], [~"payload.player_id"]},
                ~" is right there (README; websocket.ts). There is no ",
                {code, [], [~"client.realtime"]},
                ~"; create the socket with ",
                {code, [], [~"asobi.websocket({ token })"]},
                ~"."
            ]},
            {p, [], [
                {strong, [], [~"LOVE. "]},
                ~"The ",
                {code, [], [~"connected"]},
                ~" callback receives the payload, so ",
                {code, [], [~"payload.player_id"]},
                ~" works; the SDK also stores it on ",
                {code, [], [~"client.realtime.local_player_id"]},
                ~" (realtime.lua). LOVE runs one cooperative loop, so you must call ",
                {code, [], [~"client.realtime:update()"]},
                ~" every frame from ",
                {code, [], [~"love.update(dt)"]},
                ~" or no callbacks fire, including ",
                {code, [], [~"connected"]},
                ~" (README). Auth calls are synchronous and block the frame, so run them at startup."
            ]},

            ?stateless(asobi_site_tabbed_code, render, #{
                id => ~"learn-connect",
                tabs => [
                    #{
                        label => ~"Defold",
                        lang => ~"lua",
                        body =>
                            ~"""
                            local rt = client.realtime

                            rt:on("connected", function(payload)
                                print("connected, player_id=" .. payload.player_id)
                            end)

                            rt:connect()
                            """
                    },
                    #{
                        label => ~"Godot",
                        lang => ~"gdscript",
                        body =>
                            ~"""
                            Asobi.realtime.connected.connect(_on_connected)
                            Asobi.realtime.connect_to_server()

                            func _on_connected() -> void:
                                print("connected, player_id=%s" % resp["player_id"])
                            """
                    },
                    #{
                        label => ~"Unity",
                        lang => ~"csharp",
                        body =>
                            ~"""
                            client.Realtime.OnConnected += () =>
                                Debug.Log($"connected, player_id={client.PlayerId}");

                            await client.Realtime.ConnectAsync();
                            """
                    },
                    #{
                        label => ~"Unreal",
                        lang => ~"cpp",
                        body =>
                            ~"""
                            WebSocket->OnConnected.AddDynamic(this, &UMyClass::HandleConnected);
                            WebSocket->Connect(Url);

                            void UMyClass::HandleConnected()
                            {
                                WebSocket->Authenticate(Token);
                                UE_LOG(LogTemp, Log, TEXT("socket open, player_id=%s"), *Client->GetPlayerId());
                            }
                            """
                    },
                    #{
                        label => ~"Dart/Flame",
                        lang => ~"dart",
                        body =>
                            ~"""
                            client.realtime.onConnected.stream.listen((_) {
                              print('connected, player_id=${client.playerId}');
                            });

                            await client.realtime.connect(autoReconnect: false);
                            """
                    },
                    #{
                        label => ~"JavaScript",
                        lang => ~"typescript",
                        body =>
                            ~"""
                            const ws = asobi.websocket({ token });

                            ws.on("session.connected", (payload) => {
                              console.log("connected, player_id=" + payload.player_id);
                            });

                            await ws.connect();
                            """
                    },
                    #{
                        label => ~"LOVE",
                        lang => ~"lua",
                        body =>
                            ~"""
                            client.realtime:on("connected", function(payload)
                                print("connected, player_id=" .. payload.player_id)
                            end)

                            assert(client.realtime:connect())
                            """
                    }
                ]
            }),

            checkpoint([
                {p, [], [~"Run your client. You should see exactly one line, something like:"]},
                code(~"text", ~"connected, player_id=0192f3a1-7c4e-7a1b-9d2e-6f0b8c3a11ff\n"),
                {p, [], [
                    ~"If that line prints, the socket is open and the server has accepted your session. That is the entire step. If it does not print, check three things in order: the base URL matches your environment (cloud console URL versus self-hosted ",
                    {code, [], [~":8084/ws"]},
                    ~"), you made an auth call before connecting, and you registered the ",
                    {code, [], [~"connected"]},
                    ~" handler before calling connect."
                ]}
            ]),

            nextstep(
                ~"/docs/learn/identity",
                ~"Step 4 - Who is the player? Guest versus account.",
                ~"You logged in with a throwaway credential to get here; next you decide whether the player needs to register at all."
            )
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).

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
