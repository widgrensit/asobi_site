-module(asobi_site_docs_economy_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-economy", title => ~"Economy & IAP — Asobi docs"},
            Bindings
        ),
        #{}
    }.

-spec render(map()) -> arizona_template:template().
render(Bindings) ->
    Content = ?html(
        {'div', [], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}], [~"Docs"]},
                ~" / Economy"
            ]},
            {h1, [], [~"Economy & IAP"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Virtual economy primitives: wallets (multi-currency), item definitions, player inventory, store listings, and server-side validated in-app purchases (Apple + Google Play). All balance changes go through a transactional ledger."
            ]},

            {h2, [], [~"Wallets"]},
            {p, [], [
                ~"Each player can have multiple wallets, one per currency. Every change is a transaction in an audit-ready ledger."
            ]},
            pair(
                ~"""
-- Lua: game.economy.balance returns the full wallet list for the player
local wallets = game.economy.balance(player_id)
-- each entry looks like { currency = "...", balance = N }
""",
                ~"""
%% Erlang: fetch the wallet for a single currency, then debit
case asobi_economy:get_or_create_wallet(PlayerId, <<"gold">>) of
    {ok, #{balance := Bal}} when Bal >= 100 ->
        asobi_economy:debit(PlayerId, <<"gold">>, 100, #{reason => <<"store_purchase">>});
    _ ->
        {error, insufficient}
end.
"""
            ),

            {h3, [], [~"REST"]},
            code(
                ~"bash",
                ~"""
GET  /api/v1/wallets                   List wallets
GET  /api/v1/wallets/:currency/history Transaction history
"""
            ),

            {h2, [], [~"Items"]},
            {p, [], [
                ~"Items are defined globally (",
                {code, [], [~"asobi_item_def"]},
                ~") and granted to players as instances (",
                {code, [], [~"asobi_player_item"]},
                ~"). Definitions have ",
                {code, [], [~"slug"]},
                ~", ",
                {code, [], [~"name"]},
                ~", ",
                {code, [], [~"category"]},
                ~", ",
                {code, [], [~"rarity"]},
                ~", ",
                {code, [], [~"stackable"]},
                ~" and arbitrary ",
                {code, [], [~"metadata"]},
                ~"."
            ]},
            code(
                ~"bash",
                ~"""
GET  /api/v1/inventory                 List player items
POST /api/v1/inventory/consume         Consume an item
"""
            ),

            {h2, [], [~"Store"]},
            {p, [], [
                ~"Listings bind an item definition to a currency and price. Purchases are atomic \x{2014} wallet debit and inventory grant run in one DB transaction via Kura Multi."
            ]},
            code(
                ~"bash",
                ~"""
GET  /api/v1/store                     List store catalog
POST /api/v1/store/purchase            Purchase a listing
"""
            ),
            pair(
                ~"""
game.economy.purchase(player_id, "shop:starter_pack")
""",
                ~"""
asobi_economy:purchase(PlayerId, <<"shop:starter_pack">>).
"""
            ),

            {h2, [], [~"Server-side grants"]},
            code(
                ~"erlang",
                ~"""
%% grant currency (e.g. match rewards)
asobi_economy:grant(PlayerId, <<"gold">>, 100, #{reason => <<"match_reward">>}).

%% debit
asobi_economy:debit(PlayerId, <<"gold">>, 50, #{reason => <<"respawn_fee">>}).

%% items are granted via the store/purchase flow or by writing an
%% asobi_player_item row through asobi_repo — there is no grant_item/3 helper.
"""
            ),

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"ACID. "]},
                    ~"Every economy call uses a DB transaction. Double-spend, inconsistent inventory, or \x{201C}currency went missing\x{201D} bugs are architecturally prevented, not just tested for."
                ]}
            ]},

            {h2, [], [~"In-app purchases"]},
            {p, [], [
                ~"Server-side receipt validation for Apple App Store and Google Play. ",
                {strong, [], [~"Always validate on the server"]},
                ~" \x{2014} client receipts can be spoofed. Grant currency/items only after validation returns ",
                {code, [], [~"valid: true"]},
                ~"."
            ]},

            {h3, [], [~"Apple App Store"]},
            {p, [], [
                ~"StoreKit 2 signed transactions (JWS). Client sends the JWS string after a purchase:"
            ]},
            code(
                ~"bash",
                ~"""
curl -X POST http://localhost:8080/api/v1/iap/apple \
  -H 'Authorization: Bearer <session_token>' \
  -H 'Content-Type: application/json' \
  -d '{"signed_transaction": "eyJhbGciOi..."}'
"""
            ),
            code(
                ~"json",
                ~"""
{
  "product_id": "com.example.game.gems_100",
  "transaction_id": "2000000123456789",
  "purchase_date": 1711700000000,
  "type": "Consumable",
  "valid": true
}
"""
            ),
            {p, [], [
                ~"Config: ",
                {code, [], [~"{apple_bundle_id, <<\"com.example.game\">>}"]},
                ~" must match your app bundle."
            ]},

            {h3, [], [~"Google Play"]},
            {p, [], [~"Google Play Developer API. Client sends product ID and purchase token:"]},
            code(
                ~"bash",
                ~"""
curl -X POST http://localhost:8080/api/v1/iap/google \
  -H 'Authorization: Bearer <session_token>' \
  -H 'Content-Type: application/json' \
  -d '{"product_id": "gems_100", "purchase_token": "..."}'
"""
            ),

            {h3, [], [~"Granting after validation"]},
            code(
                ~"erlang",
                ~"""
case asobi_iap:verify_apple(SignedTransaction) of
    {ok, #{product_id := <<"gems_100">>, valid := true}} ->
        asobi_economy:grant(PlayerId, <<"gems">>, 100, #{reason => <<"iap_apple">>});
    {ok, #{valid := false}} ->
        {error, invalid_receipt};
    {error, Reason} ->
        {error, Reason}
end.
"""
            ),

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [{a, [{href, ~"/docs/leaderboards"}], [~"Leaderboards & tournaments"]}]},
                {li, [], [{a, [{href, ~"/docs/lua/api"}], [~"Lua API: game.economy.*"]}]},
                {li, [], [{a, [{href, ~"/docs/protocols/rest"}], [~"REST API"]}]}
            ]}
        ]}
    ),
    asobi_site_docs_shell:render(maps:get(id, Bindings), ~"/docs/economy", Content).

pair(LuaBody, ErlBody) ->
    ?html(
        {'div', [{class, ~"docs-lang-pair"}], [
            {'div', [{class, ~"docs-lang-block"}], [
                {h4, [{class, ~"docs-lang-label"}], [~"Lua"]},
                code(~"lua", LuaBody)
            ]},
            {'div', [{class, ~"docs-lang-block"}], [
                {h4, [{class, ~"docs-lang-label"}], [~"Erlang"]},
                code(~"erlang", ErlBody)
            ]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
