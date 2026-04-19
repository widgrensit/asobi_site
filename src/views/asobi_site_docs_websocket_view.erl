-module(asobi_site_docs_websocket_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-ws", title => ~"WebSocket protocol — Asobi docs"},
            Bindings
        ),
        #{}
    }.

-spec render(map()) -> arizona_template:template().
render(Bindings) ->
    Content = ?html(
        {'div', [], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Protocols / WebSocket"
            ]},
            {h1, [], [~"WebSocket protocol"]},
            {p, [{class, ~"docs-lede"}], [
                ~"One WebSocket per client at ",
                {code, [], [~"/ws"]},
                ~". All messages are JSON with a common envelope. Use this directly if you're writing a custom client; the SDKs wrap it."
            ]},

            {h2, [], [~"Envelope"]},
            code(
                ~"json",
                ~"""
// Client → server
{"cid": "optional", "type": "message.type", "payload": {}}

// Server → client
{"cid": "echoed-if-request", "type": "message.type", "payload": {}}
"""
            ),
            {p, [], [
                ~"The ",
                {code, [], [~"cid"]},
                ~" is optional. When present, the server echoes it back so the client can correlate request/response pairs."
            ]},

            {h2, [], [~"Session"]},
            msg(
                ~"session.connect",
                ~"client",
                ~"First message; authenticates the connection.",
                ~"""
{"type": "session.connect", "payload": {"token": "<session_token>"}}
"""
            ),
            msg(
                ~"session.connected",
                ~"server",
                ~"Ack of session.connect.",
                ~"""
{"type": "session.connected", "payload": {"player_id": "..."}}
"""
            ),
            msg(
                ~"session.heartbeat",
                ~"client",
                ~"Keep-alive ping; send periodically.",
                ~"""
{"type": "session.heartbeat", "payload": {}}
"""
            ),

            {h2, [], [~"Matches"]},
            msg(
                ~"match.join",
                ~"client",
                ~"Join a specific match (after matchmaking or invite).",
                ~"""
{"type": "match.join", "payload": {"match_id": "..."}}
"""
            ),
            msg(
                ~"match.input",
                ~"client",
                ~"Send an input to the match.",
                ~"""
{"type": "match.input", "payload": {"action": "move", "x": 10, "y": 5}}
"""
            ),
            msg(
                ~"match.leave",
                ~"client",
                ~"Leave the current match.",
                ~"""
{"type": "match.leave", "payload": {}}
"""
            ),
            msg(
                ~"match.started",
                ~"server",
                ~"Match has begun.",
                ~"""
{"type": "match.started", "payload": {"match_id": "...", "players": [...]}}
"""
            ),
            msg(
                ~"match.state",
                ~"server",
                ~"Broadcast state update (shape is game-specific, returned by your get_state callback).",
                ~"""
{"type": "match.state", "payload": {"players": {...}, "tick": 42}}
"""
            ),
            msg(
                ~"match.finished",
                ~"server",
                ~"Match ended with a result.",
                ~"""
{"type": "match.finished", "payload": {"match_id": "...", "result": {...}}}
"""
            ),

            {h2, [], [~"Matchmaking"]},
            msg(
                ~"matchmaker.add",
                ~"client",
                ~"Submit a ticket.",
                ~"""
{"type": "matchmaker.add",
 "payload": {"mode": "arena", "properties": {"skill": 1200}}}
"""
            ),
            msg(
                ~"matchmaker.remove",
                ~"client",
                ~"Cancel a ticket.",
                ~"""
{"type": "matchmaker.remove", "payload": {"ticket_id": "..."}}
"""
            ),
            msg(
                ~"matchmaker.matched",
                ~"server",
                ~"A match was found.",
                ~"""
{"type": "matchmaker.matched", "payload": {"match_id": "...", "players": [...]}}
"""
            ),

            {h2, [], [~"Chat"]},
            msg(
                ~"chat.join / chat.leave",
                ~"client",
                ~"Join/leave a channel.",
                ~"""
{"type": "chat.join",  "payload": {"channel_id": "lobby"}}
{"type": "chat.leave", "payload": {"channel_id": "lobby"}}
"""
            ),
            msg(
                ~"chat.send",
                ~"client",
                ~"Post a message.",
                ~"""
{"type": "chat.send", "payload": {"channel_id": "lobby", "content": "Hello!"}}
"""
            ),
            msg(
                ~"chat.message",
                ~"server",
                ~"A new message in a joined channel.",
                ~"""
{"type": "chat.message",
 "payload": {
   "channel_id": "lobby",
   "sender_id": "...",
   "content": "Hello!",
   "sent_at": "2026-04-15T10:30:00Z"
 }}
"""
            ),

            {h2, [], [~"Voting"]},
            msg(
                ~"vote.cast",
                ~"client",
                ~"Cast a vote. For approval voting, option_id is a list.",
                ~"""
{"type": "vote.cast",
 "payload": {"vote_id": "...", "option_id": "jungle"}}

// approval voting
{"type": "vote.cast",
 "payload": {"vote_id": "...", "option_id": ["jungle", "caves"]}}
"""
            ),
            msg(
                ~"vote.veto",
                ~"client",
                ~"Use a veto token to cancel. Requires veto_tokens_per_player > 0 and veto_enabled on the vote.",
                ~"""
{"type": "vote.veto", "payload": {"vote_id": "..."}}
"""
            ),
            msg(
                ~"match.vote_start",
                ~"server",
                ~"A new vote has started.",
                ~"""
{"type": "match.vote_start",
 "payload": {
   "vote_id": "...",
   "options": [{"id": "jungle", "label": "Jungle Path"}, {"id": "volcano", "label": "Volcano Path"}],
   "window_ms": 15000,
   "method": "plurality"
 }}
"""
            ),
            msg(
                ~"match.vote_tally",
                ~"server",
                ~"Running tally update (only with visibility: live).",
                ~"""
{"type": "match.vote_tally",
 "payload": {
   "vote_id": "...",
   "tallies": {"jungle": 2, "volcano": 1},
   "time_remaining_ms": 8432,
   "total_votes": 3
 }}
"""
            ),
            msg(
                ~"match.vote_result",
                ~"server",
                ~"Vote closed, winner determined.",
                ~"""
{"type": "match.vote_result",
 "payload": {
   "vote_id": "...",
   "winner": "jungle",
   "counts": {"jungle": 2, "volcano": 1},
   "distribution": {"jungle": 0.666, "volcano": 0.333},
   "total_votes": 3,
   "turnout": 1.0
 }}
"""
            ),
            msg(
                ~"match.vote_vetoed",
                ~"server",
                ~"A player vetoed the vote.",
                ~"""
{"type": "match.vote_vetoed", "payload": {"vote_id": "...", "vetoed_by": "player_id"}}
"""
            ),

            {h2, [], [~"Presence & notifications"]},
            msg(
                ~"presence.update",
                ~"client",
                ~"Update your online status.",
                ~"""
{"type": "presence.update",
 "payload": {"status": "in_game", "metadata": {"match_id": "..."}}}
"""
            ),
            msg(
                ~"presence.changed",
                ~"server",
                ~"A friend's presence changed.",
                ~"""
{"type": "presence.changed", "payload": {"player_id": "...", "status": "online"}}
"""
            ),
            msg(
                ~"notification.new",
                ~"server",
                ~"A new notification for the player.",
                ~"""
{"type": "notification.new",
 "payload": {
   "id": "...",
   "type": "friend_request",
   "subject": "New friend request",
   "content": {"from_player_id": "..."}
 }}
"""
            ),

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/protocols/rest"}, az_navigate], [~"REST API"]},
                    ~" \x{2014} HTTP endpoints for things that don't fit a real-time channel."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/authentication"}, az_navigate], [~"Authentication"]},
                    ~" \x{2014} how to get the session token for ",
                    {code, [], [~"session.connect"]},
                    ~"."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/voting"}, az_navigate], [~"Voting in depth"]},
                    ~" \x{2014} methods, tie-breakers, weighted, ranked."
                ]}
            ]}
        ]}
    ),
    asobi_site_docs_shell:render(maps:get(id, Bindings), ~"/docs/protocols/websocket", Content).

msg(Name, Direction, Desc, Example) ->
    ?html(
        {'div', [{class, ~"docs-api"}], [
            {h3, [], [
                {code, [], [Name]},
                ~" ",
                {span, [{class, ~"docs-ws-dir"}], [~"(", Direction, ~")"]}
            ]},
            {p, [], [Desc]},
            {pre, [], [{code, [{class, ~"language-json"}], [Example]}]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
