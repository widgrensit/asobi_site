-module(asobi_site_docs_rest_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(#{id => ~"docs-rest", title => ~"REST API — Asobi docs"}, Bindings),
        #{}
    }.

-spec render(map()) -> arizona_template:template().
render(Bindings) ->
    Content = ?html(
        {'div', [], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Protocols / REST"
            ]},
            {h1, [], [~"REST API"]},
            {p, [{class, ~"docs-lede"}], [
                ~"All endpoints are under ",
                {code, [], [~"/api/v1"]},
                ~". Requests and responses are JSON. Authenticated endpoints require ",
                {code, [], [~"Authorization: Bearer <session_token>"]},
                ~"."
            ]},

            section(
                ~"Auth",
                ~"""
POST /api/v1/auth/register     Register a new player
POST /api/v1/auth/login        Login, returns session token
POST /api/v1/auth/refresh      Refresh session token
POST /api/v1/auth/oauth        OAuth / Steam token validation
POST /api/v1/auth/link         Link a provider to the current account
DELETE /api/v1/auth/unlink     Unlink a provider (never the last one)
"""
            ),

            section(
                ~"Players",
                ~"""
GET /api/v1/players/:id        Get player profile
PUT /api/v1/players/:id        Update own profile
"""
            ),

            section(
                ~"Social",
                ~"""
GET    /api/v1/friends                          List friends
POST   /api/v1/friends                          Send friend request
PUT    /api/v1/friends/:friend_id               Accept / reject / block
DELETE /api/v1/friends/:friend_id               Remove friend

POST   /api/v1/groups                           Create group
GET    /api/v1/groups/:id                       Get group
PUT    /api/v1/groups/:id                       Update group
POST   /api/v1/groups/:id/join                  Join group
POST   /api/v1/groups/:id/leave                 Leave group
GET    /api/v1/groups/:id/members               List group members
PUT    /api/v1/groups/:id/members/:player_id/role  Update member role
DELETE /api/v1/groups/:id/members/:player_id    Kick member
"""
            ),

            section(
                ~"Economy",
                ~"""
GET  /api/v1/wallets                   List player wallets
GET  /api/v1/wallets/:currency/history Transaction history
GET  /api/v1/store                     List store catalog
POST /api/v1/store/purchase            Purchase a store listing
GET  /api/v1/inventory                 List player items
POST /api/v1/inventory/consume         Consume an item

POST /api/v1/iap/apple                 Validate an Apple receipt
POST /api/v1/iap/google                Validate a Google Play receipt
"""
            ),

            section(
                ~"Leaderboards & tournaments",
                ~"""
GET  /api/v1/leaderboards/:id                  Top N entries
GET  /api/v1/leaderboards/:id/around/:player   Entries around a player
POST /api/v1/leaderboards/:id                  Submit a score

GET  /api/v1/tournaments               List active tournaments
GET  /api/v1/tournaments/:id           Get tournament details
POST /api/v1/tournaments/:id/join      Join a tournament
"""
            ),

            section(
                ~"Matchmaking",
                ~"""
POST   /api/v1/matchmaker              Submit a matchmaking ticket
GET    /api/v1/matchmaker/:ticket_id   Check ticket status
DELETE /api/v1/matchmaker/:ticket_id   Cancel a ticket
"""
            ),

            section(
                ~"Votes",
                ~"""
GET /api/v1/matches/:match_id/votes    List votes for a match (newest first, max 50)
GET /api/v1/votes/:id                  Get a single vote with full results
"""
            ),

            section(
                ~"Chat",
                ~"""
GET /api/v1/chat/:channel_id/history   Message history (paginated)
"""
            ),

            section(
                ~"Notifications",
                ~"""
GET    /api/v1/notifications           List notifications (paginated)
PUT    /api/v1/notifications/:id/read  Mark as read
DELETE /api/v1/notifications/:id       Delete a notification
"""
            ),

            section(
                ~"Storage",
                ~"""
GET    /api/v1/saves                              List save slots
GET    /api/v1/saves/:slot                        Get save data
PUT    /api/v1/saves/:slot                        Write save (version for OCC)

GET    /api/v1/storage/:collection                List objects
GET    /api/v1/storage/:collection/:key           Read object
PUT    /api/v1/storage/:collection/:key           Write object
DELETE /api/v1/storage/:collection/:key           Delete object
"""
            ),

            section(
                ~"Direct messages",
                ~"""
POST   /api/v1/dm                          Send a direct message
GET    /api/v1/dm/:player_id/history       DM history with a player
"""
            ),

            {h2, [], [~"Typical curl example"]},
            code(
                ~"bash",
                ~"""
# login
curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username": "player1", "password": "secret123"}' > /tmp/login.json
TOKEN=$(jq -r .session_token /tmp/login.json)

# submit a matchmaking ticket
curl -X POST http://localhost:8080/api/v1/matchmaker \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"mode": "arena", "properties": {"skill": 1200}}'
"""
            ),

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Real-time flows go over WebSocket. "]},
                    ~"Matchmaking notifications, chat, votes, presence, and live state updates are on the ",
                    {a, [{href, ~"/docs/protocols/websocket"}, az_navigate], [~"WebSocket protocol"]},
                    ~". Use REST for request/response; use WS for push + low-latency interactions."
                ]}
            ]},

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [{a, [{href, ~"/docs/protocols/websocket"}, az_navigate], [~"WebSocket protocol"]}]},
                {li, [], [{a, [{href, ~"/docs/authentication"}, az_navigate], [~"Authentication"]}]},
                {li, [], [{a, [{href, ~"/docs/economy"}, az_navigate], [~"Economy & IAP"]}]}
            ]}
        ]}
    ),
    asobi_site_docs_shell:render(maps:get(id, Bindings), ~"/docs/protocols/rest", Content).

section(Title, Body) ->
    ?html(
        {'div', [], [
            {h2, [], [Title]},
            {pre, [], [{code, [], [Body]}]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
