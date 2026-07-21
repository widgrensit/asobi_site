-module(asobi_site_docs_learn_where_next_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-learn-where-next", title => ~"Where next - Asobi docs"},
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
                ~" / Learn / Where next"
            ]},
            {h1, [], [~"Where next"]},
            {p, [{class, ~"docs-lede"}], [
                ~"leave the guided track knowing you have the whole loop, and knowing exactly which reference guide to open for each thing you did not build here."
            ]},

            {p, [], [
                ~"You built a backend, one concept at a time. You pushed a Lua bundle, connected a client and proved it talked, resolved a guest identity that survives a restart, stored and re-read a value, ran a match (join, input, server-moved dot, broadcast state, finish), and ran a world (join, tick deltas, finish). That is the complete server-authoritative loop: the client sends intent, the server decides, the server broadcasts state. Nothing below changes that rule."
            ]},
            {p, [], [
                ~"The track stops here on purpose. The rest of Asobi is not a longer tutorial - it is a set of features you switch on when you need them, each documented in its own reference guide. You already know how to read them: every one is the same \"client sends a frame, server decides, server pushes state\" shape you have been writing all along."
            ]},

            {h2, [], [~"The extensions, one pointer each"]},
            {p, [], [
                ~"Everything here is off the linear path so that onboarding was never \"all at once\"."
            ]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Chat"]},
                    ~" - namespaced channels (",
                    {code, [], [~"room:"]},
                    ~", ",
                    {code, [], [~"world:"]},
                    ~", ",
                    {code, [], [~"zone:"]},
                    ~", ",
                    {code, [], [~"prox:"]},
                    ~", ",
                    {code, [], [~"dm:"]},
                    ~"), join and send frames, ",
                    {code, [], [~"chat.message"]},
                    ~" push. No bundle code required; the runtime owns it. See the ",
                    {strong, [], [~"Chat"]},
                    ~" section of the ",
                    {a, [{href, ~"/docs/protocols/websocket"}, az_navigate], [
                        ~"websocket-protocol"
                    ]},
                    ~" reference; message history is REST (",
                    {a, [{href, ~"/docs/protocols/rest"}, az_navigate], [~"rest-api"]},
                    ~")."
                ]},
                {li, [], [
                    {strong, [], [~"Voting"]},
                    ~" - in-match group decisions (path picks, run modifiers) via the ",
                    {code, [], [~"vote_requested"]},
                    ~" / ",
                    {code, [], [~"vote_resolved"]},
                    ~" callbacks and ",
                    {code, [], [~"vote.cast"]},
                    ~". See ",
                    {a, [{href, ~"/docs/voting"}, az_navigate], [~"voting"]},
                    ~"."
                ]},
                {li, [], [
                    {strong, [], [~"Matchmaking"]},
                    ~" - the periodic-tick matchmaker groups tickets into matches by a per-mode strategy; client sends ",
                    {code, [], [~"matchmaker.add"]},
                    ~", server pushes ",
                    {code, [], [~"match.matched"]},
                    ~". See ",
                    {a, [{href, ~"/docs/matchmaking"}, az_navigate], [~"matchmaking"]},
                    ~"."
                ]},
                {li, [], [
                    {strong, [], [~"In-app purchases"]},
                    ~" - server-side receipt validation for Apple App Store and Google Play (",
                    {code, [], [~"POST /api/v1/iap/apple"]},
                    ~", ",
                    {code, [], [~"/api/v1/iap/google"]},
                    ~"). See ",
                    {a, [{href, ~"/docs/economy"}, az_navigate], [~"iap"]},
                    ~"."
                ]},
                {li, [], [
                    {strong, [], [~"Presence"]},
                    ~" - ",
                    {code, [], [~"presence.update"]},
                    ~" intent, ",
                    {code, [], [~"presence.changed"]},
                    ~" push; in a world it is free, since the tick loop already broadcasts who is where. See the ",
                    {strong, [], [~"Presence"]},
                    ~" section of ",
                    {a, [{href, ~"/docs/protocols/websocket"}, az_navigate], [
                        ~"websocket-protocol"
                    ]},
                    ~" and ",
                    {a, [{href, ~"/docs/lobbies"}, az_navigate], [~"lobbies"]},
                    ~"."
                ]},
                {li, [], [
                    {strong, [], [~"Notifications"]},
                    ~" - ",
                    {code, [], [~"notification.new"]},
                    ~" push plus the REST list/read/delete endpoints. See the ",
                    {strong, [], [~"Notifications"]},
                    ~" section of ",
                    {a, [{href, ~"/docs/protocols/websocket"}, az_navigate], [
                        ~"websocket-protocol"
                    ]},
                    ~" and ",
                    {a, [{href, ~"/docs/protocols/rest"}, az_navigate], [~"rest-api"]},
                    ~"."
                ]}
            ]},

            {h2, [], [~"The two full references"]},
            {p, [], [~"When a one-liner above is not enough, these are the complete doors:"]},
            {ul, [], [
                {li, [], [
                    {strong, [], [
                        {a, [{href, ~"/docs/protocols/websocket"}, az_navigate], [
                            ~"WebSocket protocol reference"
                        ]}
                    ]},
                    ~" - every realtime frame the server accepts and every push it sends, across ",
                    {code, [], [~"session.*"]},
                    ~", ",
                    {code, [], [~"match.*"]},
                    ~", ",
                    {code, [], [~"world.*"]},
                    ~", ",
                    {code, [], [~"chat.*"]},
                    ~", ",
                    {code, [], [~"presence.*"]},
                    ~", ",
                    {code, [], [~"notification.*"]},
                    ~", and voting."
                ]},
                {li, [], [
                    {strong, [], [~"SDK reference"]},
                    ~" - the per-engine client guide for whichever SDK you installed in step 2 (Defold, Godot, Unity, Unreal, Dart, JS, or LOVE), plus the ",
                    {a, [{href, ~"/docs/protocols/rest"}, az_navigate], [~"rest-api"]},
                    ~" reference for the request/response surface. The only thing that differs between engines is syntax; the frames on the wire are identical."
                ]}
            ]},

            {h2, [], [~"Cloud and self-hosted: what still differs"]},
            {p, [], [
                ~"The game logic and every client SDK call are identical on cloud and self-hosted; the only routine difference is the base server URL, which you set once. Write it once, run it anywhere."
            ]},
            {p, [], [
                ~"The exception is any feature that needs an ",
                {strong, [], [~"operator secret"]},
                ~":"
            ]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Cloud"]},
                    ~" (",
                    {code, [], [~"asobi deploy"]},
                    ~" / console.asobi.dev) auto-provisions per-environment secrets - the guest pepper and the per-project database - so a bundle that is off in dev is on in prod with no change."
                ]},
                {li, [], [
                    {strong, [], [~"Self-hosted"]},
                    ~" (your own release of ",
                    {code, [], [~"asobi"]},
                    ~" + ",
                    {code, [], [~"asobi_lua"]},
                    ~", your own Postgres) you supply those yourself: the guest pepper via ",
                    {code, [], [~"ASOBI_GUEST_VERIFIER_PEPPER"]},
                    ~", and, for IAP, the store credentials via ",
                    {code, [], [~"sys.config"]},
                    ~" (",
                    {code, [], [~"apple_bundle_id"]},
                    ~", the Google service-account key). The feature code is the same; only where the secret comes from changes."
                ]}
            ]},

            checkpoint([
                {p, [], [
                    ~"Prove the reference door works against the backend you already built - no bundle change, no new SDK code. With ",
                    {code, [], [~"asobi dev"]},
                    ~" (or your self-hosted release) running, open two raw WebSocket connections to ",
                    {code, [], [~"/ws"]},
                    ~" and authenticate each with ",
                    {code, [], [~"session.connect"]},
                    ~". Note the two ",
                    {code, [], [~"player_id"]},
                    ~"s the server returns; call them ",
                    {code, [], [~"<A>"]},
                    ~" and ",
                    {code, [], [~"<B>"]},
                    ~". On ",
                    {strong, [], [~"both"]},
                    ~" connections join the direct-message channel for that pair (the server authorises each end because each is one of the two named players):"
                ]},
                code(
                    ~"json",
                    ~"""
                    {"type": "chat.join", "payload": {"channel_id": "dm:<A>:<B>"}}
                    """
                ),
                {p, [], [~"Then from one connection send:"]},
                code(
                    ~"json",
                    ~"""
                    {"type": "chat.send", "payload": {"channel_id": "dm:<A>:<B>", "content": "loop complete"}}
                    """
                ),
                {p, [], [
                    ~"You should see a ",
                    {code, [], [~"chat.message"]},
                    ~" push arrive on the ",
                    {em, [], [~"other"]},
                    ~" connection carrying ",
                    {code, [], [~"\"content\": \"loop complete\""]},
                    ~" and a ",
                    {code, [], [~"sender_id"]},
                    ~". A third connection that tries to join the same ",
                    {code, [], [~"dm:"]},
                    ~" channel is refused with ",
                    {code, [], [~"not_authorized"]},
                    ~" - the server decides who may read, exactly as it decides everything else. That is a feature you never wrote Lua for, reached the same way as everything you did write: client intent in, server-decided state out. You now have the whole loop and a map of the rest."
                ]}
            ]),

            {h2, [], [~"Next"]},
            {p, [], [
                ~"The track is done. The reference door - every guide named above - is yours; open the one your next feature needs."
            ]}
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
