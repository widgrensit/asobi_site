%% GENERATED from asobi guides/economy.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_economy_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

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
<p>Asobi provides a full virtual economy system: wallets, transactions, item
definitions, a store catalog, and player inventory.</p>
<div class="docs-callout docs-callout-info"><p class="docs-callout-title">Windows</p><p>Run the <code>curl</code> examples in Git Bash or WSL, or use PowerShell's
<code>Invoke-RestMethod</code> with the same URL and a JSON <code>-Body</code>. Authenticated calls
add <code>-Headers @{ Authorization = 'Bearer &lt;token&gt;' }</code>.</p>
</div>
<h2 id="wallets" tabindex="-1">Wallets</h2>
<p>Each player can have multiple wallets, one per currency. All balance changes
are recorded as transactions for a full audit trail.</p>
<h3 id="list-wallets" tabindex="-1">List Wallets</h3>
<pre><code class="language-bash">curl http://localhost:8084/api/v1/wallets \
  -H 'Authorization: Bearer &lt;token&gt;'
</code></pre>
<pre><code class="language-json">[
  {&quot;id&quot;: &quot;...&quot;, &quot;currency&quot;: &quot;gold&quot;, &quot;balance&quot;: 1000},
  {&quot;id&quot;: &quot;...&quot;, &quot;currency&quot;: &quot;gems&quot;, &quot;balance&quot;: 50}
]
</code></pre>
<div class="tabbed-code"><input type="radio" name="econ-tab0" id="econ-tab0-1" checked><input type="radio" name="econ-tab0" id="econ-tab0-2"><div class="tabbed-code-labels" role="tablist"><label for="econ-tab0-1">Lua</label><label for="econ-tab0-2">Erlang</label></div><div class="tabbed-code-panels"><pre class="tabbed-code-panel"><code class="language-lua">local balance = game.economy.balance(player_id)</code></pre><pre class="tabbed-code-panel"><code class="language-erlang">{ok, Wallet} = asobi_economy:get_or_create_wallet(PlayerId, &lt;&lt;"coins"&gt;&gt;),
{ok, _} = asobi_economy:debit(PlayerId, &lt;&lt;"coins"&gt;&gt;, 50, #{}).</code></pre></div></div>
<h3 id="transaction-history" tabindex="-1">Transaction History</h3>
<pre><code class="language-bash">curl http://localhost:8084/api/v1/wallets/gold/history \
  -H 'Authorization: Bearer &lt;token&gt;'
</code></pre>
<h2 id="items" tabindex="-1">Items</h2>
<p>Items are defined once via <code>asobi_item_def</code> and granted to players as
<code>asobi_player_item</code> instances.</p>
<h3 id="item-definitions" tabindex="-1">Item Definitions</h3>
<p>Item definitions are global -- they describe what an item is:</p>
<ul>
<li><code>slug</code> -- unique identifier (e.g., <code>&quot;sword_of_fire&quot;</code>)</li>
<li><code>name</code> -- display name</li>
<li><code>category</code> -- weapon, armor, consumable, etc.</li>
<li><code>rarity</code> -- common, rare, epic, legendary</li>
<li><code>stackable</code> -- whether multiple instances stack into one slot</li>
<li><code>metadata</code> -- arbitrary JSON for game-specific attributes</li>
</ul>
<h3 id="player-inventory" tabindex="-1">Player Inventory</h3>
<pre><code class="language-bash">curl http://localhost:8084/api/v1/inventory \
  -H 'Authorization: Bearer &lt;token&gt;'
</code></pre>
<h3 id="consuming-items" tabindex="-1">Consuming Items</h3>
<pre><code class="language-bash">curl -X POST http://localhost:8084/api/v1/inventory/consume \
  -H 'Authorization: Bearer &lt;token&gt;' \
  -H 'Content-Type: application/json' \
  -d '{&quot;item_id&quot;: &quot;...&quot;, &quot;quantity&quot;: 1}'
</code></pre>
<h2 id="store" tabindex="-1">Store</h2>
<p>The store is a catalog of items available for purchase with in-game currency.</p>
<h3 id="browse-store" tabindex="-1">Browse Store</h3>
<pre><code class="language-bash">curl http://localhost:8084/api/v1/store \
  -H 'Authorization: Bearer &lt;token&gt;'
</code></pre>
<pre><code class="language-json">[
  {
    &quot;id&quot;: &quot;...&quot;,
    &quot;item_def_id&quot;: &quot;...&quot;,
    &quot;currency&quot;: &quot;gold&quot;,
    &quot;price&quot;: 500,
    &quot;active&quot;: true
  }
]
</code></pre>
<h3 id="purchase" tabindex="-1">Purchase</h3>
<p>Purchases are atomic: the wallet is debited and the item is granted in a
single database transaction via Kura Multi.</p>
<pre><code class="language-bash">curl -X POST http://localhost:8084/api/v1/store/purchase \
  -H 'Authorization: Bearer &lt;token&gt;' \
  -H 'Content-Type: application/json' \
  -d '{&quot;listing_id&quot;: &quot;...&quot;}'
</code></pre>
<div class="tabbed-code"><input type="radio" name="econ-tab1" id="econ-tab1-1" checked><input type="radio" name="econ-tab1" id="econ-tab1-2"><div class="tabbed-code-labels" role="tablist"><label for="econ-tab1-1">Lua</label><label for="econ-tab1-2">Erlang</label></div><div class="tabbed-code-panels"><pre class="tabbed-code-panel"><code class="language-lua">game.economy.purchase(player_id, "shop:starter_pack")</code></pre><pre class="tabbed-code-panel"><code class="language-erlang">{ok, _} = asobi_economy:purchase(PlayerId, &lt;&lt;"shop:starter_pack"&gt;&gt;).</code></pre></div></div>
<p>Items are granted through the store/purchase flow or by writing an
<code>asobi_player_item</code> row via <code>asobi_repo</code> - there is no <code>grant_item/3</code> helper.</p>
<h2 id="server-side-operations" tabindex="-1">Server-Side Operations</h2>
<p>For admin or game logic that needs to grant/debit currency or items
programmatically:</p>
<pre><code class="language-erlang">%% Grant currency
asobi_economy:grant(PlayerId, ~&quot;gold&quot;, 100, #{reason =&gt; ~&quot;match_reward&quot;}).

%% Debit currency
asobi_economy:debit(PlayerId, ~&quot;gold&quot;, 50, #{reason =&gt; ~&quot;store_purchase&quot;}).

%% Read a wallet (creates one with balance 0 if missing)
{ok, #{balance := Bal}} = asobi_economy:get_or_create_wallet(PlayerId, ~&quot;gold&quot;).

%% Purchase a store listing (atomically debits wallet and grants item)
{ok, _} = asobi_economy:purchase(PlayerId, ListingId).
</code></pre>
<p>All economy operations use ACID transactions to prevent double-spending
or inconsistent state.</p>
<h2 id="next-steps" tabindex="-1">Next steps</h2>
<ul>
<li><a href="/docs/authentication">Authentication</a> - player identity behind wallets and purchases.</li>
<li><a href="/docs/protocols/rest">REST API</a> - the wallet, store, inventory, and IAP endpoints.</li>
</ul>
"""}
    ]}.
