%% GENERATED from asobi guides/configuration.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_configuration_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-configuration", title => ~"Configuration — Asobi docs"}, Bindings
        ),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Configuration"
        ]},
        {h1, [], [~"Configuration"]},
        {raw,
            ~"""
<p>Asobi supports two configuration paths depending on how you use it.</p>
<div class="docs-callout docs-callout-info"><p class="docs-callout-title">Do you even need this file?</p><p>On Asobi Cloud (<code>asobi deploy</code>) and the <code>asobi_lua</code> Docker image you write
no config file at all - the platform supplies sane defaults and you tune the
few knobs that matter through environment variables. You only edit
<code>sys.config</code> when you build the release from source and embed asobi as an
Erlang dependency.</p>
</div>
<h2 id="lua-docker" tabindex="-1">Lua (Docker)</h2>
<p>For Lua game developers using the Docker image, configuration lives in
your Lua scripts. No Erlang syntax needed.</p>
<h3 id="game-mode-config" tabindex="-1">Game Mode Config</h3>
<p>Declare settings as globals at the top of your match script:</p>
<pre><code class="language-lua">-- match.lua
match_size = 4
max_players = 10
strategy = &quot;fill&quot;
bots = { script = &quot;bots/arena_bot.lua&quot; }
</code></pre>
<table>
<thead>
<tr>
<th>Global</th>
<th>Required</th>
<th>Default</th>
<th>Description</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>match_size</code></td>
<td>yes</td>
<td>--</td>
<td>Minimum players to start a match</td>
</tr>
<tr>
<td><code>max_players</code></td>
<td>no</td>
<td><code>match_size</code></td>
<td>Maximum players per match</td>
</tr>
<tr>
<td><code>strategy</code></td>
<td>no</td>
<td><code>&quot;fill&quot;</code></td>
<td><code>&quot;fill&quot;</code>, <code>&quot;skill_based&quot;</code>, or custom</td>
</tr>
<tr>
<td><code>bots</code></td>
<td>no</td>
<td>none</td>
<td><code>{ script = &quot;path/to/bot.lua&quot; }</code></td>
</tr>
</tbody>
</table>
<h3 id="multiple-game-modes" tabindex="-1">Multiple Game Modes</h3>
<p>Add a <code>config.lua</code> manifest mapping mode names to scripts:</p>
<pre><code class="language-lua">-- config.lua
return {
    arena = &quot;arena/match.lua&quot;,
    ctf   = &quot;ctf/match.lua&quot;
}
</code></pre>
<h3 id="infrastructure-config" tabindex="-1">Infrastructure Config</h3>
<p>Infrastructure settings come from environment variables:</p>
<table>
<thead>
<tr>
<th>Variable</th>
<th>Default</th>
<th>Description</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>ASOBI_PORT</code></td>
<td><code>8084</code></td>
<td>HTTP/WebSocket port</td>
</tr>
<tr>
<td><code>ASOBI_DB_HOST</code></td>
<td><code>db</code></td>
<td>PostgreSQL host</td>
</tr>
<tr>
<td><code>ASOBI_DB_NAME</code></td>
<td><code>asobi</code></td>
<td>Database name</td>
</tr>
<tr>
<td><code>ASOBI_DB_USER</code></td>
<td><code>postgres</code></td>
<td>Database user</td>
</tr>
<tr>
<td><code>ASOBI_DB_PASSWORD</code></td>
<td><code>postgres</code></td>
<td>Database password</td>
</tr>
<tr>
<td><code>ASOBI_DB_SOCKET_OPTS</code></td>
<td><code>inet</code> (set by asobi_lua image; empty when consuming asobi directly)</td>
<td>Erlang term fragment spliced into the kura <code>socket_options</code> list. Examples: <code>inet</code>, <code>inet6</code>, <code>inet, {nodelay, true}</code>. Set to <code>inet6</code> for IPv6-only Postgres networks.</td>
</tr>
<tr>
<td><code>ASOBI_CORS_ORIGINS</code></td>
<td><code>*</code></td>
<td>Allowed CORS origins</td>
</tr>
<tr>
<td><code>ASOBI_NODE_HOST</code></td>
<td><code>127.0.0.1</code></td>
<td>Erlang node hostname</td>
</tr>
<tr>
<td><code>ERLANG_COOKIE</code></td>
<td><code>asobi_cookie</code></td>
<td>Erlang distribution cookie</td>
</tr>
</tbody>
</table>
<h2 id="erlang-sysconfig" tabindex="-1">Erlang (sys.config)</h2>
<p>For Erlang OTP projects that add asobi as a dependency, all configuration
lives in <code>sys.config</code> under the <code>{asobi, [...]}</code> key.</p>
<h3 id="game-modes" tabindex="-1">Game Modes</h3>
<pre><code class="language-erlang">{game_modes, #{
    ~&quot;arena&quot; =&gt; #{
        module =&gt; my_arena_game,
        match_size =&gt; 4,
        max_players =&gt; 8,
        strategy =&gt; fill
    }
}}
</code></pre>
<p>Lua scripts work too:</p>
<pre><code class="language-erlang">{game_modes, #{
    ~&quot;arena&quot; =&gt; #{
        module =&gt; {lua, &quot;game/match.lua&quot;},
        match_size =&gt; 4,
        max_players =&gt; 8,
        strategy =&gt; fill
    }
}}
</code></pre>
<p>Shorthand (Erlang module only):</p>
<pre><code class="language-erlang">{game_modes, #{
    ~&quot;arena&quot; =&gt; my_arena_game
}}
</code></pre>
<h3 id="mode-options" tabindex="-1">Mode Options</h3>
<table>
<thead>
<tr>
<th>Option</th>
<th>Default</th>
<th>Description</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>module</code></td>
<td>required</td>
<td>Erlang module or <code>{lua, &quot;path.lua&quot;}</code></td>
</tr>
<tr>
<td><code>match_size</code></td>
<td><code>2</code></td>
<td>Players needed to start a match</td>
</tr>
<tr>
<td><code>max_players</code></td>
<td><code>10</code></td>
<td>Maximum players per match</td>
</tr>
<tr>
<td><code>strategy</code></td>
<td><code>fill</code></td>
<td>Matchmaking strategy: <code>fill</code>, <code>skill_based</code>, or custom module</td>
</tr>
<tr>
<td><code>skill_window</code></td>
<td><code>200</code></td>
<td>Initial skill difference allowed (skill_based only)</td>
</tr>
<tr>
<td><code>skill_expand_rate</code></td>
<td><code>50</code></td>
<td>Window expansion per 5 seconds (skill_based only)</td>
</tr>
<tr>
<td><code>bots</code></td>
<td><code>#{}</code></td>
<td>Bot configuration. Read by <a href="https://github.com/widgrensit/asobi_lua">asobi_lua</a>, not by asobi — see <a href="https://hexdocs.pm/asobi/lua-bots.html">Bots</a></td>
</tr>
</tbody>
</table>
<h2 id="matchmaker" tabindex="-1">Matchmaker</h2>
<pre><code class="language-erlang">{matchmaker, #{
    tick_interval =&gt; 1000,     %% ms between matchmaker ticks (default 1000)
    max_wait_seconds =&gt; 60     %% ticket expiry (default 60)
}}
</code></pre>
<h2 id="sessions" tabindex="-1">Sessions</h2>
<p>Session token lifetime is handled by Nova's <code>nova_auth_session</code> — configure
there (not under <code>asobi</code>). See the Nova docs for token/refresh TTL settings.</p>
<h2 id="rate-limiting" tabindex="-1">Rate Limiting</h2>
<p>Per-route-group rate limits using sliding window algorithm via
<a href="https://github.com/Taure/seki">Seki</a>.</p>
<pre><code class="language-erlang">{rate_limits, #{
    auth =&gt; #{limit =&gt; 5, window =&gt; 1000},      %% 5 req/sec for login/refresh
    iap  =&gt; #{limit =&gt; 10, window =&gt; 1000},     %% 10 req/sec for IAP
    api  =&gt; #{limit =&gt; 300, window =&gt; 1000}     %% 300 req/sec for API
}}
</code></pre>
<p>Each route group has its own per-IP default (window in ms): <code>auth</code> 5/1000,
<code>register</code> 3/1000, <code>iap</code> 10/1000, <code>api</code> 300/1000, <code>ws_connect</code> 60/1000, and the
global (not per-IP) guest-create bound <code>guest_global</code> 100/1000. Override any
group under <code>rate_limits</code>; unset groups keep their default.</p>
<h2 id="cors" tabindex="-1">CORS</h2>
<p>CORS is handled by <code>nova_cors_plugin</code> in the Nova plugin chain — configure
it under <code>{nova, [{plugins, [...]}]}</code>:</p>
<pre><code class="language-erlang">{nova, [
    {plugins, [
        {pre_request, nova_cors_plugin, #{allow_origins =&gt; ~&quot;https://mygame.com&quot;}}
    ]}
]}
</code></pre>
<h2 id="clustering" tabindex="-1">Clustering</h2>
<p>Optional multi-node clustering via Erlang distribution.</p>
<h3 id="dns-strategy-recommended-for-flyiokubernetes" tabindex="-1">DNS Strategy (recommended for Fly.io/Kubernetes)</h3>
<pre><code class="language-erlang">{cluster, #{
    strategy =&gt; dns,
    dns_name =&gt; &quot;my-game.internal&quot;,
    poll_interval =&gt; 10000
}}
</code></pre>
<h3 id="epmd-strategy-for-static-hosts" tabindex="-1">EPMD Strategy (for static hosts)</h3>
<pre><code class="language-erlang">{cluster, #{
    strategy =&gt; epmd,
    hosts =&gt; ['node1@host1', 'node2@host2']
}}
</code></pre>
<h2 id="authentication-providers" tabindex="-1">Authentication Providers</h2>
<h3 id="oauthoidc" tabindex="-1">OAuth/OIDC</h3>
<pre><code class="language-erlang">{oidc_providers, #{
    google =&gt; #{
        client_id =&gt; ~&quot;...&quot;,
        client_secret =&gt; ~&quot;...&quot;,
        discovery_url =&gt; ~&quot;https://accounts.google.com/.well-known/openid-configuration&quot;
    },
    discord =&gt; #{
        client_id =&gt; ~&quot;...&quot;,
        client_secret =&gt; ~&quot;...&quot;,
        authorize_url =&gt; ~&quot;https://discord.com/api/oauth2/authorize&quot;,
        token_url =&gt; ~&quot;https://discord.com/api/oauth2/token&quot;,
        userinfo_url =&gt; ~&quot;https://discord.com/api/users/@me&quot;
    }
}}
</code></pre>
<p><code>base_url</code> is the public origin asobi uses to build OAuth/OIDC redirect URIs
(defaults to <code>~&quot;http://localhost:8082&quot;</code>). Set it to your deployed URL so the
redirect that providers call back to matches what you registered:</p>
<pre><code class="language-erlang">{base_url, ~&quot;https://mygame.com&quot;}
</code></pre>
<h3 id="steam" tabindex="-1">Steam</h3>
<pre><code class="language-erlang">{steam_api_key, ~&quot;your-steam-web-api-key&quot;},
{steam_app_id, ~&quot;480&quot;}
</code></pre>
<h3 id="applegoogle-iap" tabindex="-1">Apple/Google IAP</h3>
<pre><code class="language-erlang">{apple_bundle_id, ~&quot;com.example.mygame&quot;},
{apple_root_cert_path, ~&quot;/path/to/AppleRootCA-G3.pem&quot;},
{google_package_name, ~&quot;com.example.mygame&quot;},
{google_service_account_key, ~&quot;/path/to/service-account.json&quot;}
</code></pre>
<p><code>apple_root_cert_path</code> points at the Apple Root CA (PEM or DER) that
<code>asobi_iap:verify_apple/1</code> validates the StoreKit 2 receipt chain against.
Without it Apple receipt verification is refused.</p>
<h2 id="guest-anonymous-auth" tabindex="-1">Guest (anonymous) auth</h2>
<p>Guest auth lets a device create a throwaway player without credentials and
upgrade it to a real account later. It is <strong>opt-in and fails closed</strong>: the
guest endpoints return <code>403 guest_auth_disabled</code> until <code>guest_auth</code> is <code>true</code>
<strong>and</strong> a <code>guest_verifier_pepper</code> is set.</p>
<pre><code class="language-erlang">{guest_auth, true},
%% Required. A key-id -&gt; pepper map (&gt;= 32 bytes each). Keep old key ids for the
%% guest retention window so existing guests can still resume after rotation.
{guest_verifier_pepper, #{~&quot;v1&quot; =&gt; ~&quot;a-32-byte-or-longer-secret......&quot;}},
{guest_verifier_key_id, ~&quot;v1&quot;},

%% Optional abuse control: max unclaimed guests, or `infinity`.
{guest_unlinked_cap, 100000},

%% Optional retention. Unset = permanent guests (never reaped). Seconds after
%% which unclaimed guests are deleted by the reaper.
{guest_reap_after, 2592000}
</code></pre>
<table>
<thead>
<tr>
<th>Key</th>
<th>Default</th>
<th>Description</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>guest_auth</code></td>
<td><code>false</code></td>
<td>Master switch. Both this and a pepper are required</td>
</tr>
<tr>
<td><code>guest_verifier_pepper</code></td>
<td>none</td>
<td>Key-id -&gt; pepper map (each pepper &gt;= 32 bytes) or a single &gt;= 32-byte binary</td>
</tr>
<tr>
<td><code>guest_verifier_key_id</code></td>
<td><code>~&quot;v1&quot;</code></td>
<td>Which pepper key id to use when minting new verifiers</td>
</tr>
<tr>
<td><code>guest_unlinked_cap</code></td>
<td><code>100000</code></td>
<td>Soft ceiling on unclaimed guests, or <code>infinity</code></td>
</tr>
<tr>
<td><code>guest_reap_after</code></td>
<td>unset</td>
<td>Seconds; unset disables the reaper (guests are permanent)</td>
</tr>
</tbody>
</table>
<p>The pepper is a server-side secret kept <strong>outside</strong> the database - store it in
an env var or secret manager, never in source. To rotate, add a new key id and
point <code>guest_verifier_key_id</code> at it; keep the old key ids for at least the
retention window so existing guests can still resume. Guest creation is bounded
by the per-IP auth limiter plus the global <code>guest_global</code> create limit.</p>
<h2 id="vote-templates" tabindex="-1">Vote Templates</h2>
<p>Define reusable vote configurations:</p>
<pre><code class="language-erlang">{vote_templates, #{
    ~&quot;map_vote&quot; =&gt; #{
        method =&gt; ~&quot;plurality&quot;,
        window_ms =&gt; 15000,
        visibility =&gt; ~&quot;live&quot;
    },
    ~&quot;boon_pick&quot; =&gt; #{
        method =&gt; ~&quot;plurality&quot;,
        window_ms =&gt; 15000,
        visibility =&gt; ~&quot;live&quot;
    }
}}
</code></pre>
<p>Templates are merged with per-vote config from your game module.</p>
<h2 id="world-capacity" tabindex="-1">World capacity</h2>
<p>Bounds on persistent world creation, enforced as a DoS backstop:</p>
<pre><code class="language-erlang">{world_max_per_player, 5},   %% default 5
{world_max, 1000}            %% default 1000
</code></pre>
<p>A player at the per-player cap gets <code>429</code>; once the global cap is reached
further creates get <code>503</code>.</p>
<h2 id="terrain-provider-allowlist" tabindex="-1">Terrain provider allowlist</h2>
<p>For Lua large-world games, only allowlisted terrain generators can be named
from Lua. This is an <code>asobi_lua</code> key (not <code>asobi</code>):</p>
<pre><code class="language-erlang">{asobi_lua, [
    {terrain_providers, [asobi_terrain_flat, asobi_terrain_perlin]}
]}
</code></pre>
<p>The default allows <code>asobi_terrain_flat</code> and <code>asobi_terrain_perlin</code>.</p>
<h2 id="per-call-upper-bounds" tabindex="-1">Per-call upper bounds</h2>
<p>These runtime limits bound the cost of a single request. They are not
configurable - they are documented here so you can size clients accordingly:</p>
<table>
<thead>
<tr>
<th>Limit</th>
<th>Value</th>
</tr>
</thead>
<tbody>
<tr>
<td>Cloud save body</td>
<td>256 KB</td>
</tr>
<tr>
<td>Save slots per player</td>
<td>10</td>
</tr>
<tr>
<td>Inventory consume quantity</td>
<td>1 .. 1000000</td>
</tr>
<tr>
<td>Leaderboard <code>top</code> <code>?limit</code></td>
<td>1 .. 100</td>
</tr>
<tr>
<td>Leaderboard <code>around</code> <code>?range</code></td>
<td>1 .. 50</td>
</tr>
<tr>
<td>Chat history <code>?limit</code></td>
<td>1 .. 200</td>
</tr>
<tr>
<td>DM content</td>
<td>2000 bytes</td>
</tr>
<tr>
<td>WS chat channels per connection</td>
<td>32</td>
</tr>
<tr>
<td>Idle channel timeout</td>
<td>60s</td>
</tr>
<tr>
<td>Lua table decode depth</td>
<td>64</td>
</tr>
</tbody>
</table>
<h2 id="database-kura" tabindex="-1">Database (Kura)</h2>
<p>Database configuration is under the <code>kura</code> application key:</p>
<pre><code class="language-erlang">{kura, [
    {backend, kura_backend_postgres},
    {repo, asobi_repo},
    {host, &quot;localhost&quot;},
    {port, 5432},
    {database, &quot;my_game_dev&quot;},
    {user, &quot;postgres&quot;},
    {password, &quot;postgres&quot;},
    {pool_size, 10}
]}
</code></pre>
<h2 id="background-jobs-shigoto" tabindex="-1">Background Jobs (Shigoto)</h2>
<pre><code class="language-erlang">{shigoto, [
    {pool, asobi_repo}
]}
</code></pre>
<h2 id="full-example-erlang-sysconfig" tabindex="-1">Full Example (Erlang sys.config)</h2>
<pre><code class="language-erlang">[
    {kura, [
        {backend, kura_backend_postgres},
        {repo, asobi_repo},
        {host, &quot;localhost&quot;},
        {database, &quot;my_game_dev&quot;},
        {user, &quot;postgres&quot;},
        {password, &quot;postgres&quot;},
        {pool_size, 20}
    ]},
    {shigoto, [
        {pool, asobi_repo}
    ]},
    {asobi, [
        {rate_limits, #{
            auth =&gt; #{limit =&gt; 10, window =&gt; 60000},
            api =&gt; #{limit =&gt; 300, window =&gt; 1000}
        }},
        {matchmaker, #{
            tick_interval =&gt; 1000,
            max_wait_seconds =&gt; 60
        }},
        {game_modes, #{
            ~&quot;arena&quot; =&gt; #{
                module =&gt; {lua, &quot;game/match.lua&quot;},
                match_size =&gt; 4,
                max_players =&gt; 8,
                strategy =&gt; fill,
                bots =&gt; #{
                    enabled =&gt; true,
                    fill_after_ms =&gt; 8000,
                    min_players =&gt; 4,
                    script =&gt; &lt;&lt;&quot;game/bots/chaser.lua&quot;&gt;&gt;
                }
            }
        }}
    ]}
].
</code></pre>
<h2 id="full-example-lua-docker" tabindex="-1">Full Example (Lua Docker)</h2>
<pre><code class="language-yaml"># docker-compose.yml
services:
  postgres:
    image: postgres:17
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: my_game_dev
    healthcheck:
      test: [&quot;CMD-SHELL&quot;, &quot;pg_isready -U postgres&quot;]
      interval: 5s
      timeout: 5s
      retries: 5

  asobi:
    image: ghcr.io/widgrensit/asobi_lua:latest
    depends_on:
      postgres: { condition: service_healthy }
    ports:
      - &quot;8084:8084&quot;
    volumes:
      - ./lua:/app/game:ro
    environment:
      ASOBI_DB_HOST: postgres
      ASOBI_DB_NAME: my_game_dev
</code></pre>
<pre><code class="language-lua">-- lua/match.lua
match_size = 4
max_players = 8
strategy = &quot;fill&quot;
bots = { script = &quot;bots/chaser.lua&quot; }

function init(config)
    return { players = {} }
end

-- ... rest of callbacks
</code></pre>
<pre><code class="language-lua">-- lua/bots/chaser.lua
names = {&quot;Spark&quot;, &quot;Blitz&quot;, &quot;Volt&quot;, &quot;Neon&quot;}

function think(bot_id, state)
    -- AI logic
end
</code></pre>
<h2 id="next-steps" tabindex="-1">Next steps</h2>
<ul>
<li><a href="https://github.com/widgrensit/asobi_lua/blob/main/guides/self-hosting.md">Self-hosting</a> - running the image.</li>
<li><a href="/docs/clustering">Clustering</a> - multi-node config.</li>
<li><a href="/docs/performance">Performance tuning</a> - the tick and BEAM knobs.</li>
</ul>
"""}
    ]}.
