-module(asobi_site_docs_quickstart_dart_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-qs-dart", title => ~"Dart quickstart — Asobi docs"},
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
                ~" / Quick start - Dart"
            ]},
            {h1, [], [~"Quick start - Dart"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Connect a plain Dart or Flutter app to a running Asobi server in about five minutes. ",
                ~"Building a Flame game? See the ",
                {a, [{href, ~"/docs/quickstart/flame"}, az_navigate], [~"Flame quickstart"]},
                ~" instead. No server yet? Run the ",
                {a, [{href, ~"/docs/quickstart"}, az_navigate], [~"server quickstart"]},
                ~" first - it gives you a backend on localhost:8084 with a ",
                {code, [], [~"default"]},
                ~" match mode."
            ]},

            {h2, [], [~"1. Add the package"]},
            {p, [], [
                ~"The package is ",
                {code, [], [~"asobi"]},
                ~". Its only dependencies are ",
                {code, [], [~"http"]},
                ~" and ",
                {code, [], [~"web_socket_channel"]},
                ~"."
            ]},
            code(~"bash", ~"dart pub add asobi"),
            {p, [], [
                ~"Everything is exported from one barrel - ",
                {code, [], [~"import 'package:asobi/asobi.dart';"]},
                ~"."
            ]},

            {h2, [], [~"2. Authenticate and connect"]},
            {p, [], [
                ~"Construct the client, get a guest session, subscribe to the realtime streams, then ",
                ~"connect. The realtime hooks are ",
                {strong, [], [~"broadcast streams"]},
                ~" - subscribe ",
                {em, [], [~"before"]},
                ~" calling ",
                {code, [], [~"connect()"]},
                ~", and wait for ",
                {code, [], [~"onConnected"]},
                ~" before queueing."
            ]},
            code(
                ~"dart",
                ~"""
import 'dart:async';
import 'package:asobi/asobi.dart';

Future<void> main() async {
  final client = AsobiClient('localhost', port: 8084);

  // Same deviceId + deviceSecret resumes the guest; a new pair creates one.
  // You generate and persist deviceSecret (>= 32 CSPRNG bytes, base64).
  await client.auth.guest(deviceId, deviceSecret);

  final connected = Completer<void>();
  client.realtime.onConnected.stream.listen((_) {
    if (!connected.isCompleted) connected.complete();
  });
  client.realtime.onMatchmakerMatched.stream.listen((m) => print('match ${m.matchId}'));
  client.realtime.onMatchState.stream.listen((s) => render(s.players));

  await client.realtime.connect();
  await connected.future.timeout(const Duration(seconds: 5));

  // No join(mode) call - queue the matchmaker; the server pushes the match.
  await client.realtime.addToMatchmaker(mode: 'default');
}
"""
            ),
            {p, [], [
                ~"Then send input with the fire-and-forget ",
                {code, [], [~"sendMatchInput"]},
                ~" (payload shape is game-specific): ",
                {code, [], [~"client.realtime.sendMatchInput({'move_x': 1, 'move_y': 0});"]},
                ~"."
            ]},

            {h2, [], [~"Core API"]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"AsobiClient(host, {port = 8084, useSsl = false, tokenStore})"]},
                    ~"."
                ]},
                {li, [], [
                    {code, [], [~"client.auth.guest(deviceId, deviceSecret)"]},
                    ~" - also ",
                    {code, [], [~"register"]},
                    ~", ",
                    {code, [], [~"login"]},
                    ~", ",
                    {code, [], [~"upgradeGuest"]},
                    ~", ",
                    {code, [], [~"refresh"]},
                    ~"."
                ]},
                {li, [], [
                    {code, [], [~"client.realtime.connect()"]},
                    ~" / ",
                    {code, [], [~"addToMatchmaker(mode: 'default')"]},
                    ~" / ",
                    {code, [], [~"sendMatchInput(map)"]},
                    ~"."
                ]},
                {li, [], [
                    ~"Broadcast streams: ",
                    {code, [], [~"onConnected"]},
                    ~", ",
                    {code, [], [~"onMatchmakerMatched"]},
                    ~", ",
                    {code, [], [~"onMatchState"]},
                    ~", ",
                    {code, [], [~"onMatchFinished"]},
                    ~", ",
                    {code, [], [~"onAuthExpired"]},
                    ~" (consume via ",
                    {code, [], [~".stream.listen(...)"]},
                    ~")."
                ]}
            ]},

            {h2, [], [~"Gotchas"]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Subscribe before connect. "]},
                    ~"Broadcast streams don't buffer, so a late listener misses early frames. Gate ",
                    {code, [], [~"addToMatchmaker"]},
                    ~" on ",
                    {code, [], [~"onConnected"]},
                    ~"."
                ]},
                {li, [], [
                    {strong, [], [~"Persist tokens yourself. "]},
                    ~"The access token is memory-only; inject a ",
                    {code, [], [~"TokenStore"]},
                    ~" (e.g. flutter_secure_storage) to persist the refresh token, and store the guest ",
                    {code, [], [~"deviceSecret"]},
                    ~" separately."
                ]},
                {li, [], [
                    {strong, [], [~"Auth expiry stops reconnect. "]},
                    ~"On ",
                    {code, [], [~"onAuthExpired"]},
                    ~", re-auth (",
                    {code, [], [~"client.auth.refresh()"]},
                    ~") and reconnect. On Flutter Web use ",
                    {code, [], [~"useSsl: true"]},
                    ~" so the socket is ",
                    {code, [], [~"wss://"]},
                    ~"."
                ]}
            ]},

            {h2, [], [~"What's next"]},
            {ul, [], [
                {li, [], [{a, [{href, ~"/dart"}, az_navigate], [~"Full Dart SDK reference"]}]},
                {li, [], [
                    {a, [{href, ~"/docs/quickstart/flame"}, az_navigate], [~"Flame quickstart"]}
                ]},
                {li, [], [{a, [{href, ~"/docs/authentication"}, az_navigate], [~"Authentication"]}]}
            ]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
