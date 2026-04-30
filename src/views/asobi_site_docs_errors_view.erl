-module(asobi_site_docs_errors_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-errors", title => ~"Errors & status codes — Asobi docs"},
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
                ~" / Errors"
            ]},
            {h1, [], [~"Errors & status codes"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Every Asobi REST endpoint returns a JSON body of the shape ",
                {code, [], [~"{\"error\": \"<reason>\", ...}"]},
                ~" on failure. The reason atom is stable; the HTTP status indicates the class."
            ]},

            {h2, [], [~"Status codes the runtime emits"]},
            {pre, [], [
                {code, [], [
                    ~"""
 Status | Class                   | Reason atoms (examples)                                    | Where it comes from
--------|-------------------------|------------------------------------------------------------|------------------------------------------------
 400    | Bad request             | content_empty, invalid_perm, invalid_quantity,             | Controllers reject malformed payloads or
        |                         | bad_data, channel_id_invalid, body_too_large               | invalid query params before any DB work.
 401    | Unauthenticated         | invalid_token, expired_token                               | asobi_auth_plugin / IAP receipt validation.
 403    | Forbidden               | not_member, not_owner, not_match_participant,              | Caller is authenticated but lacks the right
        |                         | last_auth_method, group_full, friendship_self              | (channel membership, ticket ownership, etc).
 404    | Not found               | match_not_found, world_not_found, ticket_not_found,        | Resource lookup miss.
        |                         | save_not_found, group_not_found
 409    | Conflict                | already_friends, username_taken, world_already_owned       | Idempotent-ish endpoints flag duplicate state.
 413    | Payload too large       | content_too_large, save_too_large                          | Body exceeded the per-endpoint cap (DM 2000B,
        |                         |                                                            | save 256KB, etc).
 429    | Too many requests       | rate_limited, world_cap_exceeded                           | Seki limiter or per-player world cap hit.
 500    | Internal error          | internal_error                                             | Unexpected crash in a controller; logged with
        |                         |                                                            | a correlation id, never leaks internals.
 503    | Service unavailable     | world_global_cap                                           | Global world cap hit (operator should raise
        |                         |                                                            | world_max in sys config).
"""
                ]}
            ]},

            {h2, [], [~"Per-endpoint specifics"]},

            {h3, [], [~"Auth (", {code, [], [~"/api/v1/auth/*"]}, ~")"]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"401"]},
                    ~" + ",
                    {code, [], [~"invalid_credentials"]},
                    ~" \x{2014} login failed. Rate-limited at 5 req/sec/IP."
                ]},
                {li, [], [
                    {code, [], [~"409"]},
                    ~" + ",
                    {code, [], [~"username_taken"]},
                    ~" \x{2014} register against an existing username."
                ]},
                {li, [], [
                    {code, [], [~"403"]},
                    ~" + ",
                    {code, [], [~"last_auth_method"]},
                    ~" \x{2014} unlinking the only remaining auth method (would lock the player out)."
                ]}
            ]},

            {h3, [], [~"IAP (", {code, [], [~"/api/v1/iap/*"]}, ~")"]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"400"]},
                    ~" + ",
                    {code, [], [~"invalid_jws"]},
                    ~" \x{2014} Apple receipt failed any of header alg, x5c chain, or signature checks. Reason atom is sanitised; full detail stays in server logs."
                ]},
                {li, [], [
                    {code, [], [~"400"]},
                    ~" + ",
                    {code, [], [~"invalid_ticket_format"]},
                    ~" \x{2014} Steam ticket failed hex/length validation."
                ]}
            ]},

            {h3, [], [~"World (", {code, [], [~"/api/v1/worlds"]}, ~")"]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"429"]},
                    ~" + ",
                    {code, [], [~"world_cap_exceeded"]},
                    ~" \x{2014} player already owns ",
                    {code, [], [~"world_max_per_player"]},
                    ~" worlds (default 5)."
                ]},
                {li, [], [
                    {code, [], [~"503"]},
                    ~" + ",
                    {code, [], [~"world_global_cap"]},
                    ~" \x{2014} global ",
                    {code, [], [~"world_max"]},
                    ~" hit (default 1000). Operators should raise this and possibly add nodes."
                ]}
            ]},

            {h3, [], [~"Storage / saves"]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"413"]},
                    ~" + ",
                    {code, [], [~"save_too_large"]},
                    ~" \x{2014} save body > 256 KB."
                ]},
                {li, [], [
                    {code, [], [~"400"]},
                    ~" + ",
                    {code, [], [~"slot_cap"]},
                    ~" \x{2014} player already has 10 slots."
                ]},
                {li, [], [
                    {code, [], [~"400"]},
                    ~" + ",
                    {code, [], [~"invalid_perm"]},
                    ~" \x{2014} ",
                    {code, [], [~"read_perm"]},
                    ~"/",
                    {code, [], [~"write_perm"]},
                    ~" must be ",
                    {code, [], [~"\"public\""]},
                    ~" or ",
                    {code, [], [~"\"owner\""]},
                    ~"."
                ]}
            ]},

            {h3, [], [~"Chat / DM"]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"400"]},
                    ~" + ",
                    {code, [], [~"channel_id_invalid"]},
                    ~" \x{2014} channel id must start with one of ",
                    {code, [], [~"dm:"]},
                    ~", ",
                    {code, [], [~"world:"]},
                    ~", ",
                    {code, [], [~"zone:"]},
                    ~", ",
                    {code, [], [~"prox:"]},
                    ~", ",
                    {code, [], [~"room:"]},
                    ~"."
                ]},
                {li, [], [
                    {code, [], [~"403"]},
                    ~" + ",
                    {code, [], [~"not_member"]},
                    ~" \x{2014} fetching history for a channel you don't belong to."
                ]},
                {li, [], [
                    {code, [], [~"413"]},
                    ~" + ",
                    {code, [], [~"content_too_large"]},
                    ~" \x{2014} DM content > 2000 bytes."
                ]},
                {li, [], [
                    {code, [], [~"400"]},
                    ~" + ",
                    {code, [], [~"too_many_channels"]},
                    ~" \x{2014} more than 32 channels joined on one WS connection."
                ]}
            ]},

            {h3, [], [~"Matchmaker"]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"403"]},
                    ~" + ",
                    {code, [], [~"not_owner"]},
                    ~" \x{2014} fetching or cancelling a ticket the caller didn't create. Ticket reads / cancellations require ownership."
                ]}
            ]},

            {h3, [], [~"Voting"]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"403"]},
                    ~" + ",
                    {code, [], [~"not_match_participant"]},
                    ~" \x{2014} the caller is not in the match they are trying to vote in."
                ]}
            ]},

            {h2, [], [~"WebSocket frame errors"]},
            {p, [], [
                ~"Errors on a WebSocket are returned as a frame of type ",
                {code, [], [~"error"]},
                ~", not as an HTTP status. Common reasons:"
            ]},
            {pre, [], [
                {code, [], [
                    ~"""
{"type": "error",
 "payload": {"reason": "rate_limited", "context": "chat.send"}}
"""
                ]}
            ]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"unauthenticated"]},
                    ~" \x{2014} sent a non-",
                    {code, [], [~"session.connect"]},
                    ~" frame as the first message."
                ]},
                {li, [], [
                    {code, [], [~"channel_id_invalid"]},
                    ~", ",
                    {code, [], [~"too_many_channels"]},
                    ~", ",
                    {code, [], [~"not_member"]},
                    ~" \x{2014} chat-related, mirror the REST shapes above."
                ]},
                {li, [], [
                    {code, [], [~"unknown_type"]},
                    ~" \x{2014} message type the runtime does not recognise; safe to ignore client-side."
                ]}
            ]},

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/security/auth"}, az_navigate], [
                        ~"Auth & rate limiting"
                    ]},
                    ~" \x{2014} the rationale and tunables for the codes above."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/protocols/rest"}, az_navigate], [~"REST API reference"]}
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/protocols/websocket"}, az_navigate], [
                        ~"WebSocket protocol"
                    ]}
                ]}
            ]}
        ]}
    ).
