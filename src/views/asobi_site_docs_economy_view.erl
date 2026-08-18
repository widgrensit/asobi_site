%% GENERATED from asobi guides/economy.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_economy_view).

-export([mount/1, render/1, markdown/0]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"docs-economy", title => ~"Economy & IAP — Asobi docs"}, Bindings), #{}}.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Economy"
        ]},
        {h1, [], [~"Economy"]},
        {raw,
            ~"""
<p>Wallets, transactions, item definitions, a store catalogue and player
inventory.</p>
<p>Run the <code>curl</code> examples in Git Bash or WSL on Windows, or use PowerShell's
<code>Invoke-RestMethod</code> with the same URL and a JSON <code>-Body</code>. Authenticated calls
add <code>-Headers @{ Authorization = 'Bearer &lt;token&gt;' }</code>.</p>
<h2 id="wallets" tabindex="-1">Wallets</h2>
<p>Each player can have one wallet per currency. Every balance change is recorded
as a transaction row, so the wallet's history is a full audit trail.</p>
<h3 id="list-wallets" tabindex="-1">List wallets</h3>
<pre><code class="language-bash">curl http://localhost:8084/api/v1/wallets \
  -H 'Authorization: Bearer &lt;token&gt;'
</code></pre>
<pre><code class="language-json">{
  &quot;wallets&quot;: [
    {&quot;currency&quot;: &quot;gold&quot;, &quot;balance&quot;: 1000},
    {&quot;currency&quot;: &quot;gems&quot;, &quot;balance&quot;: 50}
  ]
}
</code></pre>
<p>The response is an object, and each entry carries <code>currency</code> and <code>balance</code>
only - the wallet's <code>id</code> is stripped on the way out and no route accepts one.</p>
<h3 id="in-lua" tabindex="-1">In Lua</h3>
<p><code>game.economy.*</code> calls return the wrapped envelope: a table with either an <code>ok</code>
field or an <code>error</code> field. <code>balance</code> never returns a number, so comparing its
result numerically silently misbehaves.</p>
<pre><code class="language-lua">local result = game.economy.balance(player_id)
if result.error then
  game.log(&quot;warning&quot;, &quot;balance lookup failed&quot;, { reason = result.error })
  return state
end

local gold = 0
for _, wallet in ipairs(result.ok) do
  if wallet.currency == &quot;gold&quot; then gold = wallet.balance end
end
</code></pre>
<p><code>grant</code>, <code>debit</code> and <code>purchase</code> use the same envelope. See
<a href="https://hexdocs.pm/asobi/lua-api.html">The game.* API</a> for the full list and the two return conventions.</p>
<pre><code class="language-lua">game.economy.grant(player_id, &quot;gold&quot;, 100, &quot;match_reward&quot;)
game.economy.debit(player_id, &quot;gold&quot;, 50, &quot;respawn_fee&quot;)
game.economy.purchase(player_id, listing_id)
</code></pre>
<h3 id="in-erlang" tabindex="-1">In Erlang</h3>
<pre><code class="language-erlang">{ok, Wallet} = asobi_economy:get_or_create_wallet(PlayerId, ~&quot;gold&quot;),
{ok, _} = asobi_economy:grant(PlayerId, ~&quot;gold&quot;, 100, #{reason =&gt; ~&quot;match_reward&quot;}),
{ok, _} = asobi_economy:debit(PlayerId, ~&quot;gold&quot;, 50, #{reason =&gt; ~&quot;respawn_fee&quot;}).
</code></pre>
<p><code>get_or_create_wallet/2</code> creates the wallet with balance 0 if it is missing.
<code>grant/4</code> and <code>debit/4</code> each run in one transaction holding the wallet lock
described under <a href="#purchase">Purchase</a>.</p>
<h3 id="transaction-history" tabindex="-1">Transaction history</h3>
<pre><code class="language-bash">curl 'http://localhost:8084/api/v1/wallets/gold/history?limit=100' \
  -H 'Authorization: Bearer &lt;token&gt;'
</code></pre>
<pre><code class="language-json">{
  &quot;transactions&quot;: [
    {
      &quot;id&quot;: &quot;...&quot;,
      &quot;wallet_id&quot;: &quot;...&quot;,
      &quot;amount&quot;: -500,
      &quot;balance_after&quot;: 500,
      &quot;reason&quot;: &quot;purchase&quot;,
      &quot;reference_type&quot;: &quot;store_listing&quot;,
      &quot;reference_id&quot;: &quot;...&quot;,
      &quot;metadata&quot;: {},
      &quot;inserted_at&quot;: &quot;...&quot;
    }
  ]
}
</code></pre>
<p>Newest first. <code>limit</code> defaults to 50 and is clamped to 1-200.</p>
<h2 id="items" tabindex="-1">Items</h2>
<p>Items are defined once as <code>asobi_item_def</code> rows and granted to players as
<code>asobi_player_item</code> instances.</p>
<h3 id="item-definitions" tabindex="-1">Item definitions</h3>
<p>An item definition is global and describes what an item is:</p>
<table>
<thead>
<tr>
<th>Column</th>
<th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>slug</code></td>
<td>Unique identifier, e.g. <code>&quot;sword_of_fire&quot;</code></td>
</tr>
<tr>
<td><code>name</code></td>
<td>Display name</td>
</tr>
<tr>
<td><code>category</code></td>
<td>Free-form, e.g. weapon, armour, consumable</td>
</tr>
<tr>
<td><code>rarity</code></td>
<td>One of <code>common</code>, <code>uncommon</code>, <code>rare</code>, <code>epic</code>, <code>legendary</code>. Defaults to <code>common</code> and is validated</td>
</tr>
<tr>
<td><code>stackable</code></td>
<td>A boolean, defaulting to <code>true</code></td>
</tr>
<tr>
<td><code>metadata</code></td>
<td>Arbitrary JSON for game-specific attributes</td>
</tr>
</tbody>
</table>
<p><code>stackable</code> is metadata for your game to interpret. Nothing in asobi reads it:
the purchase path always inserts a fresh <code>asobi_player_item</code> row with
<code>quantity</code> 1 and never merges into an existing stack, whatever <code>stackable</code>
says. If you want stacking, do it in your own grant path.</p>
<h3 id="player-inventory" tabindex="-1">Player inventory</h3>
<pre><code class="language-bash">curl 'http://localhost:8084/api/v1/inventory?limit=100' \
  -H 'Authorization: Bearer &lt;token&gt;'
</code></pre>
<pre><code class="language-json">{
  &quot;items&quot;: [
    {
      &quot;id&quot;: &quot;...&quot;,
      &quot;item_def_id&quot;: &quot;...&quot;,
      &quot;player_id&quot;: &quot;...&quot;,
      &quot;quantity&quot;: 1,
      &quot;metadata&quot;: {},
      &quot;acquired_at&quot;: &quot;...&quot;,
      &quot;updated_at&quot;: &quot;...&quot;
    }
  ]
}
</code></pre>
<p>Newest acquisition first. <code>limit</code> defaults to 50 and is clamped to 1-200.</p>
<p>There is no Lua call for inventory. Read it over REST, or query
<code>asobi_player_item</code> from Erlang.</p>
<h3 id="consuming-items" tabindex="-1">Consuming items</h3>
<pre><code class="language-bash">curl -X POST http://localhost:8084/api/v1/inventory/consume \
  -H 'Authorization: Bearer &lt;token&gt;' \
  -H 'Content-Type: application/json' \
  -d '{&quot;item_id&quot;: &quot;...&quot;, &quot;quantity&quot;: 1}'
</code></pre>
<pre><code class="language-json">{&quot;success&quot;: true, &quot;remaining_quantity&quot;: 0}
</code></pre>
<p>Consuming the whole stack deletes the row. <code>quantity</code> must be a positive
integer no greater than 1,000,000.</p>
<h2 id="store" tabindex="-1">Store</h2>
<p>The store is a catalogue of items purchasable with in-game currency.</p>
<h3 id="browse-the-store" tabindex="-1">Browse the store</h3>
<pre><code class="language-bash">curl 'http://localhost:8084/api/v1/store?currency=gold' \
  -H 'Authorization: Bearer &lt;token&gt;'
</code></pre>
<pre><code class="language-json">{
  &quot;listings&quot;: [
    {
      &quot;id&quot;: &quot;...&quot;,
      &quot;item_def_id&quot;: &quot;...&quot;,
      &quot;currency&quot;: &quot;gold&quot;,
      &quot;price&quot;: 500,
      &quot;active&quot;: true,
      &quot;valid_from&quot;: null,
      &quot;valid_until&quot;: null,
      &quot;metadata&quot;: {}
    }
  ]
}
</code></pre>
<p>Only <code>active</code> listings are returned. The optional <code>currency</code> parameter filters
to one currency.</p>
<p><code>valid_from</code> and <code>valid_until</code> are columns on the listing and are returned, but
<strong>asobi does not enforce the window</strong>. A listing with a <code>valid_until</code> in the
past is still purchasable as long as <code>active</code> is true. Treat the two columns as
data for your own scheduling job to act on by flipping <code>active</code>.</p>
<h3 id="purchase" tabindex="-1">Purchase</h3>
<p><code>listing_id</code> is the store listing's <strong>UUID</strong>, the <code>id</code> from the browse
response. Listings have no slug, and no route accepts one.</p>
<pre><code class="language-bash">curl -X POST http://localhost:8084/api/v1/store/purchase \
  -H 'Authorization: Bearer &lt;token&gt;' \
  -H 'Content-Type: application/json' \
  -d '{&quot;listing_id&quot;: &quot;0198c4f2-...&quot;}'
</code></pre>
<pre><code class="language-json">{
  &quot;success&quot;: true,
  &quot;item&quot;: {
    &quot;id&quot;: &quot;...&quot;,
    &quot;item_def_id&quot;: &quot;...&quot;,
    &quot;player_id&quot;: &quot;...&quot;,
    &quot;quantity&quot;: 1,
    &quot;metadata&quot;: {},
    &quot;acquired_at&quot;: &quot;...&quot;,
    &quot;updated_at&quot;: &quot;...&quot;
  }
}
</code></pre>
<p><code>item</code> is the inserted <code>player_items</code> row, not the item definition. Read
<code>item_def_id</code> to find out what it is.</p>
<div class="tabbed-code"><input type="radio" name="econ-tab0" id="econ-tab0-1" checked><input type="radio" name="econ-tab0" id="econ-tab0-2"><div class="tabbed-code-labels" role="tablist"><label for="econ-tab0-1">Lua</label><label for="econ-tab0-2">Erlang</label></div><div class="tabbed-code-panels"><pre class="tabbed-code-panel"><code class="language-lua">local result = game.economy.purchase(player_id, listing_id)
if result.error then
  game.log("info", "purchase refused", { reason = result.error })
end</code></pre><pre class="tabbed-code-panel"><code class="language-erlang">{ok, Item} = asobi_economy:purchase(PlayerId, ListingId).</code></pre></div></div>
<p>The debit and the item grant happen in <strong>one database transaction</strong>, serialised
by a Postgres advisory lock keyed on <code>(player_id, currency)</code>. Any concurrent
transaction touching the same wallet blocks until this one commits or rolls
back, which is what makes a double-spend impossible without rewriting the query
layer to use <code>SELECT ... FOR UPDATE</code>.</p>
<p>Items are granted through this path or by writing an <code>asobi_player_item</code> row
via <code>asobi_repo</code>. There is no <code>grant_item/3</code> helper.</p>
<h2 id="error-codes" tabindex="-1">Error codes</h2>
<table>
<thead>
<tr>
<th>Status</th>
<th>Code</th>
<th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>402</code></td>
<td><code>economy.insufficient_funds</code></td>
<td>The wallet does not hold enough of this currency</td>
</tr>
<tr>
<td><code>400</code></td>
<td><code>economy.listing_inactive</code></td>
<td>The listing exists but <code>active</code> is false</td>
</tr>
<tr>
<td><code>500</code></td>
<td><code>economy.purchase_failed</code></td>
<td>The purchase could not be completed</td>
</tr>
<tr>
<td><code>404</code></td>
<td><code>inventory.item_not_found</code></td>
<td>No inventory item with this id</td>
</tr>
<tr>
<td><code>403</code></td>
<td><code>forbidden</code></td>
<td>The item exists but belongs to another player</td>
</tr>
<tr>
<td><code>400</code></td>
<td><code>inventory.insufficient_quantity</code></td>
<td>The stack holds fewer than the amount asked</td>
</tr>
<tr>
<td><code>400</code></td>
<td><code>inventory.invalid_quantity</code></td>
<td><code>quantity</code> is missing, not a positive integer, or over the cap</td>
</tr>
</tbody>
</table>
<p>Every one arrives in the shared shape:</p>
<pre><code class="language-json">{&quot;error&quot;: {&quot;code&quot;: &quot;economy.insufficient_funds&quot;, &quot;message&quot;: &quot;...&quot;, &quot;details&quot;: {}}}
</code></pre>
<h2 id="inspecting-the-economy" tabindex="-1">Inspecting the economy</h2>
<p>The console has an Economy screen: the item catalogue, then the store listings
below it. It is the catalogue only - it reads, and it cannot
create a listing, grant an item or adjust a balance. Wallets and inventory are
not on that plane at all; query the <code>wallets</code>, <code>transactions</code> and
<code>player_items</code> tables directly for those. See
<a href="https://hexdocs.pm/asobi/console.html">Operator console</a>.</p>
<h2 id="next-steps" tabindex="-1">Next steps</h2>
<ul>
<li><a href="/docs/authentication">Authentication</a> - player identity behind wallets and purchases.</li>
<li><a href="/docs/economy">In-app purchases</a> - real-money receipts, which do not touch wallets on their own.</li>
<li><a href="/docs/protocols/rest">REST API</a> - the wallet, store and inventory endpoints.</li>
</ul>
"""}
    ]}.

%% The guide source, served at this page's .md URL. asobi_site_markdown cannot
%% walk the {raw, ...} blob above, and does not need to: this is what that HTML
%% was rendered from.
-spec markdown() -> binary().
markdown() ->
    ~"""
# Economy

Wallets, transactions, item definitions, a store catalogue and player
inventory.

Run the `curl` examples in Git Bash or WSL on Windows, or use PowerShell's
`Invoke-RestMethod` with the same URL and a JSON `-Body`. Authenticated calls
add `-Headers @{ Authorization = 'Bearer <token>' }`.

## Wallets

Each player can have one wallet per currency. Every balance change is recorded
as a transaction row, so the wallet's history is a full audit trail.

### List wallets

```bash
curl http://localhost:8084/api/v1/wallets \
  -H 'Authorization: Bearer <token>'
```

```json
{
  "wallets": [
    {"currency": "gold", "balance": 1000},
    {"currency": "gems", "balance": 50}
  ]
}
```

The response is an object, and each entry carries `currency` and `balance`
only - the wallet's `id` is stripped on the way out and no route accepts one.

### In Lua

`game.economy.*` calls return the wrapped envelope: a table with either an `ok`
field or an `error` field. `balance` never returns a number, so comparing its
result numerically silently misbehaves.

```lua
local result = game.economy.balance(player_id)
if result.error then
  game.log("warning", "balance lookup failed", { reason = result.error })
  return state
end

local gold = 0
for _, wallet in ipairs(result.ok) do
  if wallet.currency == "gold" then gold = wallet.balance end
end
```

`grant`, `debit` and `purchase` use the same envelope. See
[The game.* API](https://hexdocs.pm/asobi/lua-api.html) for the full list and the two return conventions.

```lua
game.economy.grant(player_id, "gold", 100, "match_reward")
game.economy.debit(player_id, "gold", 50, "respawn_fee")
game.economy.purchase(player_id, listing_id)
```

### In Erlang

```erlang
{ok, Wallet} = asobi_economy:get_or_create_wallet(PlayerId, ~"gold"),
{ok, _} = asobi_economy:grant(PlayerId, ~"gold", 100, #{reason => ~"match_reward"}),
{ok, _} = asobi_economy:debit(PlayerId, ~"gold", 50, #{reason => ~"respawn_fee"}).
```

`get_or_create_wallet/2` creates the wallet with balance 0 if it is missing.
`grant/4` and `debit/4` each run in one transaction holding the wallet lock
described under [Purchase](#purchase).

### Transaction history

```bash
curl 'http://localhost:8084/api/v1/wallets/gold/history?limit=100' \
  -H 'Authorization: Bearer <token>'
```

```json
{
  "transactions": [
    {
      "id": "...",
      "wallet_id": "...",
      "amount": -500,
      "balance_after": 500,
      "reason": "purchase",
      "reference_type": "store_listing",
      "reference_id": "...",
      "metadata": {},
      "inserted_at": "..."
    }
  ]
}
```

Newest first. `limit` defaults to 50 and is clamped to 1-200.

## Items

Items are defined once as `asobi_item_def` rows and granted to players as
`asobi_player_item` instances.

### Item definitions

An item definition is global and describes what an item is:

| Column | Meaning |
|---|---|
| `slug` | Unique identifier, e.g. `"sword_of_fire"` |
| `name` | Display name |
| `category` | Free-form, e.g. weapon, armour, consumable |
| `rarity` | One of `common`, `uncommon`, `rare`, `epic`, `legendary`. Defaults to `common` and is validated |
| `stackable` | A boolean, defaulting to `true` |
| `metadata` | Arbitrary JSON for game-specific attributes |

`stackable` is metadata for your game to interpret. Nothing in asobi reads it:
the purchase path always inserts a fresh `asobi_player_item` row with
`quantity` 1 and never merges into an existing stack, whatever `stackable`
says. If you want stacking, do it in your own grant path.

### Player inventory

```bash
curl 'http://localhost:8084/api/v1/inventory?limit=100' \
  -H 'Authorization: Bearer <token>'
```

```json
{
  "items": [
    {
      "id": "...",
      "item_def_id": "...",
      "player_id": "...",
      "quantity": 1,
      "metadata": {},
      "acquired_at": "...",
      "updated_at": "..."
    }
  ]
}
```

Newest acquisition first. `limit` defaults to 50 and is clamped to 1-200.

There is no Lua call for inventory. Read it over REST, or query
`asobi_player_item` from Erlang.

### Consuming items

```bash
curl -X POST http://localhost:8084/api/v1/inventory/consume \
  -H 'Authorization: Bearer <token>' \
  -H 'Content-Type: application/json' \
  -d '{"item_id": "...", "quantity": 1}'
```

```json
{"success": true, "remaining_quantity": 0}
```

Consuming the whole stack deletes the row. `quantity` must be a positive
integer no greater than 1,000,000.

## Store

The store is a catalogue of items purchasable with in-game currency.

### Browse the store

```bash
curl 'http://localhost:8084/api/v1/store?currency=gold' \
  -H 'Authorization: Bearer <token>'
```

```json
{
  "listings": [
    {
      "id": "...",
      "item_def_id": "...",
      "currency": "gold",
      "price": 500,
      "active": true,
      "valid_from": null,
      "valid_until": null,
      "metadata": {}
    }
  ]
}
```

Only `active` listings are returned. The optional `currency` parameter filters
to one currency.

`valid_from` and `valid_until` are columns on the listing and are returned, but
**asobi does not enforce the window**. A listing with a `valid_until` in the
past is still purchasable as long as `active` is true. Treat the two columns as
data for your own scheduling job to act on by flipping `active`.

### Purchase

`listing_id` is the store listing's **UUID**, the `id` from the browse
response. Listings have no slug, and no route accepts one.

```bash
curl -X POST http://localhost:8084/api/v1/store/purchase \
  -H 'Authorization: Bearer <token>' \
  -H 'Content-Type: application/json' \
  -d '{"listing_id": "0198c4f2-..."}'
```

```json
{
  "success": true,
  "item": {
    "id": "...",
    "item_def_id": "...",
    "player_id": "...",
    "quantity": 1,
    "metadata": {},
    "acquired_at": "...",
    "updated_at": "..."
  }
}
```

`item` is the inserted `player_items` row, not the item definition. Read
`item_def_id` to find out what it is.

**Lua**
```lua
local result = game.economy.purchase(player_id, listing_id)
if result.error then
  game.log("info", "purchase refused", { reason = result.error })
end
```
**Erlang**
```erlang
{ok, Item} = asobi_economy:purchase(PlayerId, ListingId).
```

The debit and the item grant happen in **one database transaction**, serialised
by a Postgres advisory lock keyed on `(player_id, currency)`. Any concurrent
transaction touching the same wallet blocks until this one commits or rolls
back, which is what makes a double-spend impossible without rewriting the query
layer to use `SELECT ... FOR UPDATE`.

Items are granted through this path or by writing an `asobi_player_item` row
via `asobi_repo`. There is no `grant_item/3` helper.

## Error codes

| Status | Code | Meaning |
|---|---|---|
| `402` | `economy.insufficient_funds` | The wallet does not hold enough of this currency |
| `400` | `economy.listing_inactive` | The listing exists but `active` is false |
| `500` | `economy.purchase_failed` | The purchase could not be completed |
| `404` | `inventory.item_not_found` | No inventory item with this id |
| `403` | `forbidden` | The item exists but belongs to another player |
| `400` | `inventory.insufficient_quantity` | The stack holds fewer than the amount asked |
| `400` | `inventory.invalid_quantity` | `quantity` is missing, not a positive integer, or over the cap |

Every one arrives in the shared shape:

```json
{"error": {"code": "economy.insufficient_funds", "message": "...", "details": {}}}
```

## Inspecting the economy

The console has an Economy screen: the item catalogue, then the store listings
below it. It is the catalogue only - it reads, and it cannot
create a listing, grant an item or adjust a balance. Wallets and inventory are
not on that plane at all; query the `wallets`, `transactions` and
`player_items` tables directly for those. See
[Operator console](https://hexdocs.pm/asobi/console.html).

## Next steps

- [Authentication](https://asobi.dev/docs/authentication) - player identity behind wallets and purchases.
- [In-app purchases](https://asobi.dev/docs/economy) - real-money receipts, which do not touch wallets on their own.
- [REST API](https://asobi.dev/docs/protocols/rest) - the wallet, store and inventory endpoints.
""".
