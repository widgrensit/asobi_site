-module(asobi_site_docs_quickstart_unreal_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-qs-unreal", title => ~"Unreal quickstart — Asobi docs"},
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
                ~" / Quick start - Unreal"
            ]},
            {h1, [], [~"Quick start - Unreal"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Connect an Unreal Engine 5 project to a running Asobi server. The SDK is a C++ runtime ",
                ~"plugin (",
                {code, [], [~"AsobiSDK"]},
                ~", UE 5.4+); every call is also ",
                {code, [], [~"BlueprintCallable"]},
                ~". No server yet? Run the ",
                {a, [{href, ~"/docs/quickstart"}, az_navigate], [~"server quickstart"]},
                ~" first."
            ]},

            {h2, [], [~"1. Install the plugin"]},
            {ul, [], [
                {li, [], [
                    ~"Clone into your project's ",
                    {code, [], [~"Plugins/"]},
                    ~" folder: ",
                    {code, [], [
                        ~"git clone https://github.com/widgrensit/asobi-unreal.git Plugins/AsobiSDK"
                    ]},
                    ~"."
                ]},
                {li, [], [
                    ~"Regenerate project files, then enable ",
                    {strong, [], [~"Asobi SDK"]},
                    ~" under Edit -> Plugins -> Networking."
                ]},
                {li, [], [
                    ~"Add ",
                    {code, [], [~"\"AsobiSDK\""]},
                    ~" to ",
                    {code, [], [~"PublicDependencyModuleNames"]},
                    ~" in your module's ",
                    {code, [], [~"Build.cs"]},
                    ~"."
                ]}
            ]},

            {h2, [], [~"2. Auth, connect, queue"]},
            {p, [], [
                ~"There is no subsystem or singleton - you create the objects yourself with ",
                {code, [], [~"NewObject"]},
                ~" and keep them in ",
                {code, [], [~"UPROPERTY"]},
                ~" fields so they aren't garbage-collected. Auth is two steps: get a REST token, then ",
                ~"authenticate the socket with it."
            ]},
            code(
                ~"cpp",
                ~"""
#include "AsobiClient.h"
#include "AsobiAuth.h"
#include "AsobiMatchmaker.h"
#include "AsobiWebSocket.h"

// 1. HTTP client + guest auth
Client = NewObject<UAsobiClient>(this);
Client->SetBaseUrl(TEXT("http://localhost:8084"));

Auth = NewObject<UAsobiAuth>(this);
Auth->Init(Client);
FOnAsobiAuthResponse OnAuth;
OnAuth.BindDynamic(this, &UMyClass::HandleAuth);
Auth->Guest(DeviceId, DeviceSecret, OnAuth); // DeviceSecret: your base64 >=32 bytes

// 2. On auth -> open the socket (note ws:// scheme + /ws path)
void UMyClass::HandleAuth(bool bOk, const FAsobiAuthTokens& Tokens) {
    WebSocket = NewObject<UAsobiWebSocket>(this);
    WebSocket->OnConnected.AddDynamic(this, &UMyClass::HandleWsConnected);
    WebSocket->OnMatchMatched.AddDynamic(this, &UMyClass::OnInMatch);
    WebSocket->OnMatchState.AddDynamic(this, &UMyClass::OnState);
    WebSocket->Connect(TEXT("ws://localhost:8084/ws"));
}

// 3. On socket open -> authenticate it, then queue the matchmaker
void UMyClass::HandleWsConnected() {
    WebSocket->Authenticate(Client->GetAuthToken());

    Matchmaker = NewObject<UAsobiMatchmaker>(this);
    Matchmaker->Init(Client);
    FOnAsobiMatchmakerResponse OnMm;
    OnMm.BindDynamic(this, &UMyClass::HandleMm);
    Matchmaker->Add(TEXT("default"), TArray<FString>{ Client->GetPlayerId() }, OnMm);
}
"""
            ),
            {p, [], [
                ~"Then send input each tick with ",
                {code, [], [~"WebSocket->SendMatchInput(DataJson)"]},
                ~" and read state on the ",
                {code, [], [~"OnMatchState"]},
                ~" delegate. The whole flow is Blueprint-callable too."
            ]},

            {h2, [], [~"Core API"]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"UAsobiAuth::Guest(DeviceId, DeviceSecret, Cb)"]},
                    ~" - also ",
                    {code, [], [~"Register"]},
                    ~", ",
                    {code, [], [~"Login"]},
                    ~"; callback delivers ",
                    {code, [], [~"FAsobiAuthTokens"]},
                    ~"."
                ]},
                {li, [], [
                    {code, [], [~"UAsobiWebSocket::Connect(Url)"]},
                    ~" then ",
                    {code, [], [~"Authenticate(Token)"]},
                    ~"."
                ]},
                {li, [], [
                    {code, [], [~"UAsobiMatchmaker::Add(Mode, Party, Cb)"]},
                    ~" - or ",
                    {code, [], [~"UAsobiWebSocket::JoinMatch(MatchId)"]},
                    ~" for a specific match."
                ]},
                {li, [], [
                    {code, [], [~"UAsobiWebSocket::SendMatchInput(DataJson)"]},
                    ~"; delegates ",
                    {code, [], [~"OnMatchMatched"]},
                    ~", ",
                    {code, [], [~"OnMatchJoined"]},
                    ~", ",
                    {code, [], [~"OnMatchState"]},
                    ~"."
                ]}
            ]},

            {h2, [], [~"Gotchas"]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Point the socket at ws://.../ws. "]},
                    ~"A frequent slip is connecting to ",
                    {code, [], [~"http://localhost:8084"]},
                    ~" instead of ",
                    {code, [], [~"ws://localhost:8084/ws"]},
                    ~"."
                ]},
                {li, [], [
                    {strong, [], [~"Two-step auth. "]},
                    ~"After ",
                    {code, [], [~"Connect"]},
                    ~", call ",
                    {code, [], [~"Authenticate(Client->GetAuthToken())"]},
                    ~" on ",
                    {code, [], [~"OnConnected"]},
                    ~". Send a periodic ",
                    {code, [], [~"SendHeartbeat()"]},
                    ~" or the server drops you with ",
                    {code, [], [~"1008 idle_auth_timeout"]},
                    ~"."
                ]},
                {li, [], [
                    {strong, [], [~"Hold references. "]},
                    ~"Keep the client, auth, matchmaker, and socket in ",
                    {code, [], [~"UPROPERTY"]},
                    ~" fields (the demo parks them on the ",
                    {code, [], [~"UGameInstance"]},
                    ~") or they're GC'd mid-session."
                ]}
            ]},

            {h2, [], [~"What's next"]},
            {ul, [], [
                {li, [], [{a, [{href, ~"/unreal"}, az_navigate], [~"Full Unreal SDK reference"]}]},
                {li, [], [{a, [{href, ~"/docs/authentication"}, az_navigate], [~"Authentication"]}]}
            ]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
