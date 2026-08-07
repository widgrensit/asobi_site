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
<p>asobi is one node with two surfaces. Run the image and configure it from the
environment plus your Lua scripts, or depend on the Hex package and configure it
in <code>sys.config</code>. This page is the reference for both.</p>
<p>Version floors, supported Postgres and the image's architecture live in
<a href="https://hexdocs.pm/asobi/self-hosting.html#requirements">Self-hosting</a>.</p>
<h2 id="lua-docker" tabindex="-1">Lua (Docker)</h2>
<p>For Lua game developers using the image, configuration lives in your Lua
scripts. No Erlang syntax needed.</p>
<h3 id="game-mode-config" tabindex="-1">Game mode config</h3>
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
<td>none</td>
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
<td><code>&quot;fill&quot;</code>, <code>&quot;skill_based&quot;</code>, or a custom module</td>
</tr>
<tr>
<td><code>bots</code></td>
<td>no</td>
<td>none</td>
<td><code>{ script = &quot;path/to/bot.lua&quot; }</code> - see <a href="/docs/lua/bots">Bots</a></td>
</tr>
<tr>
<td><code>game_type</code></td>
<td>no</td>
<td><code>&quot;match&quot;</code></td>
<td><code>&quot;match&quot;</code> or <code>&quot;world&quot;</code></td>
</tr>
<tr>
<td><code>state_strategy</code></td>
<td>no</td>
<td>none</td>
<td><code>&quot;shared&quot;</code> selects the encode-once broadcast path</td>
</tr>
<tr>
<td><code>guest_auth</code></td>
<td>no</td>
<td><code>false</code></td>
<td>Declares that this game offers anonymous play. The operator still has to supply a pepper</td>
</tr>
<tr>
<td><code>registration</code></td>
<td>no</td>
<td>none</td>
<td><code>&quot;open&quot;</code>, <code>&quot;oauth_only&quot;</code> or <code>&quot;closed&quot;</code>. The operator's <code>sys.config</code> wins when it sets one</td>
</tr>
</tbody>
</table>
<p>World-mode games (<code>game_type = &quot;world&quot;</code>) read a further set of globals -
<code>tick_rate</code>, <code>grid_size</code>, <code>zone_size</code>, <code>view_radius</code>, <code>empty_grace_ms</code>,
<code>player_ttl_ms</code>. <a href="/docs/world-server">World server</a> documents those.</p>
<p><strong>Where you put <code>guest_auth</code> and <code>registration</code> matters.</strong> They are read from
<code>match.lua</code> in single-mode and from <code>config.lua</code> in multi-mode. A game with a
<code>config.lua</code> manifest that declares <code>guest_auth = true</code> in <code>match.lua</code> instead
gets nothing, silently: the config loader reads <code>config.lua</code> when it exists and
never looks at <code>match.lua</code>.</p>
<h3 id="multiple-game-modes" tabindex="-1">Multiple game modes</h3>
<p>Add a <code>config.lua</code> manifest mapping mode names to scripts:</p>
<pre><code class="language-lua">-- config.lua
return {
    arena = &quot;arena/match.lua&quot;,
    ctf   = &quot;ctf/match.lua&quot;
}
</code></pre>
<h3 id="infrastructure-config" tabindex="-1">Infrastructure config</h3>
<p>Infrastructure settings come from environment variables. Every default below is
the image's own <code>ENV</code>; consuming asobi as a dependency, these do not exist and
you write <code>sys.config</code> instead.</p>
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
<td>HTTP and WebSocket port</td>
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
<td><code>inet</code></td>
<td>Erlang term fragment spliced into kura's <code>socket_options</code> list. <code>inet</code>, <code>inet6</code>, <code>inet, {nodelay, true}</code>. Set <code>inet6</code> for IPv6-only Postgres networks</td>
</tr>
<tr>
<td><code>ASOBI_CORS_ORIGINS</code></td>
<td>none</td>
<td>Allowed CORS origin. Effectively required for any browser client: unset renders an empty <code>Access-Control-Allow-Origin</code>, which no browser accepts</td>
</tr>
<tr>
<td><code>ASOBI_NODE_HOST</code></td>
<td><code>127.0.0.1</code></td>
<td>Erlang node hostname, in <code>-name asobi@...</code>. Not a bind address</td>
</tr>
<tr>
<td><code>ERLANG_COOKIE</code></td>
<td><code>asobi</code></td>
<td>Erlang distribution cookie. The default is the literal string <code>asobi</code></td>
</tr>
</tbody>
</table>
<p>The database port is <strong>not</strong> a variable. It is fixed at <code>5432</code> in the image's
<code>sys.config</code>, so a Postgres on another port means supplying your own.</p>
<h2 id="erlang-sysconfig" tabindex="-1">Erlang (sys.config)</h2>
<p>For Erlang OTP projects that add asobi as a dependency, configuration lives in
<code>sys.config</code> under the <code>{asobi, [...]}</code> key.</p>
<h3 id="which-application-key" tabindex="-1">Which application key</h3>
<p>Everything below goes under <code>{asobi, [...]}</code>.</p>
<p>The Lua runtime used to be its own OTP application, so the keys it owns -
<code>max_heap_words</code>, <code>max_reductions_per_ms</code>, <code>reload_mode</code>,
<code>config_watch_interval</code>, <code>dev_errors</code>, <code>terrain_providers</code> and <code>rate_limits</code> -
are still read from <code>asobi_lua</code> first and <code>asobi</code> second
(<code>asobi_lua_env:get_env/2</code>). An existing <code>{asobi_lua, [...]}</code> block keeps
working and there is nothing to migrate. Put new configuration under <code>{asobi, [...]}</code>.</p>
<p>Everything else, <code>game_dir</code> and <code>game_modes</code> included, is an <code>asobi</code> key only
and always was.</p>
<p>The module names have not moved either: <code>asobi_lua_config</code>, <code>asobi_lua_api</code>,
<code>asobi_lua_loader</code> and friends are current, and so is <code>ASOBI_LUA_RELOAD</code>. Only
the <em>image</em> name changed - see <a href="https://hexdocs.pm/asobi/glossary.html#asobi">Glossary</a>.</p>
<h3 id="game-modes" tabindex="-1">Game modes</h3>
<pre><code class="language-erlang">{game_modes, #{
    ~&quot;arena&quot; =&gt; #{
        module =&gt; my_arena_game,
        match_size =&gt; 4,
        max_players =&gt; 8,
        strategy =&gt; fill
    }
}}
</code></pre>
<p>Lua scripts work too, in the same release:</p>
<pre><code class="language-erlang">{game_modes, #{
    ~&quot;arena&quot; =&gt; #{
        module =&gt; {lua, &quot;game/match.lua&quot;},
        match_size =&gt; 4,
        max_players =&gt; 8,
        strategy =&gt; fill
    }
}}
</code></pre>
<p>Luerl is a hard dependency of asobi and <code>asobi_app:start/2</code> registers the Lua
providers itself, so <code>{lua, _}</code> modes work in a stock release with no extra
application. <code>{error, lua_runtime_unavailable}</code> survives only as the answer for
a mode <em>kind</em> that has no registered provider, which a stock release does not
have.</p>
<p>Shorthand (Erlang module only):</p>
<pre><code class="language-erlang">{game_modes, #{
    ~&quot;arena&quot; =&gt; my_arena_game
}}
</code></pre>
<h3 id="mode-options" tabindex="-1">Mode options</h3>
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
<td><code>match_size</code> for matches, <code>500</code> for worlds</td>
<td>Maximum players per instance</td>
</tr>
<tr>
<td><code>strategy</code></td>
<td><code>fill</code></td>
<td>Matchmaking strategy: <code>fill</code>, <code>skill_based</code>, or a custom module</td>
</tr>
<tr>
<td><code>skill_window</code></td>
<td><code>200</code></td>
<td>Initial skill difference allowed (<code>skill_based</code> only)</td>
</tr>
<tr>
<td><code>skill_expand_rate</code></td>
<td><code>50</code></td>
<td>Window expansion per 5 seconds (<code>skill_based</code> only)</td>
</tr>
<tr>
<td><code>bots</code></td>
<td><code>#{}</code></td>
<td>Bot configuration - see <a href="/docs/lua/bots">Bots</a></td>
</tr>
<tr>
<td><code>listed</code></td>
<td><code>false</code> for matches, <code>true</code> for worlds</td>
<td>Whether instances appear in discovery (<code>match.list</code> / <code>world.list</code>). Matches are unlisted by default: a matchmaker-spawned match is already assigned to its players, so opt in explicitly</td>
</tr>
<tr>
<td><code>quick_play</code></td>
<td><code>true</code></td>
<td>Worlds only. Whether <code>world.find_or_create</code> may place a player into an existing world of this mode. Independent of <code>listed</code> - see <a href="/docs/world-server#visibility">World server</a></td>
</tr>
</tbody>
</table>
<h3 id="operator-modes-and-game-declared-modes" tabindex="-1">Operator modes and game-declared modes</h3>
<p>Modes come from two independent places and asobi keeps them apart (ADR 0006):</p>
<ul>
<li><strong>Operator modes</strong> are the ones above, in your <code>sys.config</code> <code>game_modes</code>.
asobi never rewrites that key.</li>
<li><strong>Game-declared modes</strong> are what a Lua game declares in <code>match.lua</code> or a
<code>config.lua</code> manifest. Loading a game replaces that set wholesale, so a mode
you delete from <code>config.lua</code> is gone the next time the config loads instead
of lingering until a restart.</li>
</ul>
<p>The effective registry is the game-declared set with the operator set on top:
an operator mode wins a name clash and a game bundle can never drop or redefine
it. Read it with <code>asobi_game_config:modes/0</code>. The raw <code>game_modes</code> app-env key
is only the operator half.</p>
<h2 id="game-directory" tabindex="-1">Game directory</h2>
<pre><code class="language-erlang">{game_dir, &quot;/app/game&quot;}
</code></pre>
<p>Where the Lua loader looks for <code>config.lua</code>, <code>match.lua</code> and every script a
mode names. <code>/app/game</code> is the image's default and the mount point it declares.
There is no environment variable for it.</p>
<h2 id="matchmaker" tabindex="-1">Matchmaker</h2>
<pre><code class="language-erlang">{matchmaker, #{
    tick_interval =&gt; 1000,     %% ms between matchmaker ticks (default 1000)
    max_wait_seconds =&gt; 60     %% ticket expiry (default 60)
}}
</code></pre>
<p>The queue and its tickets live in this node's own process. Players queuing
against different nodes never match each other - see
<a href="/docs/clustering">Clustering</a>.</p>
<h2 id="sessions" tabindex="-1">Sessions</h2>
<p>Nothing to configure. Access tokens last 60 minutes and refresh tokens 30 days,
from nova_auth's defaults, and <code>asobi_auth:config/0</code> does not override them.
Changing either means editing that function.</p>
<h2 id="rate-limiting" tabindex="-1">Rate limiting</h2>
<p>Per-route-group sliding windows via <a href="https://github.com/Taure/seki">Seki</a>.
<strong>Buckets are per node</strong>, so a 5/s limit is 5 x N across a cluster; size them
for one node and read <a href="/docs/clustering">Clustering</a> before you rely on a number.</p>
<pre><code class="language-erlang">{rate_limits, #{
    auth =&gt; #{limit =&gt; 5, window =&gt; 1000},      %% 5 req/sec for login/refresh
    iap  =&gt; #{limit =&gt; 10, window =&gt; 1000},     %% 10 req/sec for IAP
    api  =&gt; #{limit =&gt; 300, window =&gt; 1000}     %% 300 req/sec for API
}}
</code></pre>
<table>
<thead>
<tr>
<th>Group</th>
<th>Default</th>
<th>Keyed on</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>auth</code></td>
<td>5 / 1000 ms</td>
<td>IP</td>
</tr>
<tr>
<td><code>register</code></td>
<td>3 / 1000 ms</td>
<td>IP</td>
</tr>
<tr>
<td><code>iap</code></td>
<td>10 / 1000 ms</td>
<td>IP</td>
</tr>
<tr>
<td><code>api</code></td>
<td>300 / 1000 ms</td>
<td>IP</td>
</tr>
<tr>
<td><code>ws_connect</code></td>
<td>60 / 1000 ms</td>
<td>IP</td>
</tr>
<tr>
<td><code>join</code></td>
<td>10 / 60000 ms</td>
<td>player</td>
</tr>
<tr>
<td><code>rehome</code></td>
<td>5 / 1000 ms</td>
<td>player</td>
</tr>
<tr>
<td><code>guest_global</code></td>
<td>100 / 1000 ms</td>
<td>a constant (global)</td>
</tr>
<tr>
<td><code>rehome_global</code></td>
<td>200 / 1000 ms</td>
<td>a constant (global)</td>
</tr>
<tr>
<td><code>script_log</code></td>
<td>3 / 10000 ms</td>
<td>the failing call site</td>
</tr>
</tbody>
</table>
<p><code>register</code> has its own bucket because <code>/auth/register</code> runs the password KDF as
its only cost gate. <code>script_log</code> bounds log lines from a script that fails on
every tick, not the telemetry counter behind them. <code>rehome_global</code> is a
placeholder default: size it from your real concurrent-player target.</p>
<p>Override any group; unset groups keep their default.</p>
<h2 id="request-body-cap" tabindex="-1">Request body cap</h2>
<p><code>asobi_body_cap_plugin</code> runs before Nova buffers a request body, so an
oversized POST is rejected before it reaches the heap.</p>
<pre><code class="language-erlang">{nova, [
    {plugins, [
        {pre_request, asobi_body_cap_plugin, #{
            max_body =&gt; 1048576,
            require_content_length =&gt; true
        }}
    ]}
]}
</code></pre>
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
<td><code>max_body</code></td>
<td><code>1048576</code> (1 MiB)</td>
<td>Bodies larger than this get <code>413 payload_too_large</code></td>
</tr>
<tr>
<td><code>require_content_length</code></td>
<td><code>true</code></td>
<td>A body with no <code>content-length</code> gets <code>411 length_required</code> rather than being streamed</td>
</tr>
</tbody>
</table>
<p>Per-route checks (cloud save, storage) still apply on top of this floor. The
image configures both values already.</p>
<h2 id="pre-auth-client-gate" tabindex="-1">Pre-auth client gate</h2>
<p>An optional gate in front of the anonymous auth-create routes, for a CAPTCHA or
an attestation check. Unset, it is a no-op.</p>
<pre><code class="language-erlang">{client_gate, my_captcha_gate},
{client_gate_timeout, 5000},
{client_gate_on_error, deny}
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
<td><code>client_gate</code></td>
<td>unset</td>
<td>Module implementing <code>asobi_client_gate</code>. Unset disables the gate entirely</td>
</tr>
<tr>
<td><code>client_gate_timeout</code></td>
<td><code>5000</code></td>
<td>Milliseconds to wait for the gate's verdict</td>
</tr>
<tr>
<td><code>client_gate_on_error</code></td>
<td><code>deny</code></td>
<td>What a crashed or timed-out gate means. Anything but <code>skip</code> rejects; <code>skip</code> trades the check for availability</td>
</tr>
</tbody>
</table>
<p>A rejected request gets <code>403 client_gate_denied</code>, with the gate's own reason in
<code>details.reason</code> (<code>client_gate_unavailable</code> when the gate itself failed). It
runs after the rate limiter, so a flood is shed by the cheap in-memory check
before it reaches an external verification service.</p>
<h2 id="websocket-origin-allowlist" tabindex="-1">WebSocket origin allowlist</h2>
<p>By default the <code>/ws</code> upgrade accepts any <code>Origin</code>: web builds are served from
arbitrary studio and hosting domains, so a strict default would break them.</p>
<p>To harden a deployment against cross-site WebSocket hijacking, set an
allowlist:</p>
<pre><code class="language-erlang">{ws_allowed_origins, [
    ~&quot;https://play.yourgame.com&quot;,
    ~&quot;https://yourstudio.itch.io&quot;
]}
</code></pre>
<p>When set, a browser upgrade whose <code>Origin</code> is not listed is closed with <code>1008 origin_rejected</code> and emits <code>[asobi, ws, origin_rejected]</code>. Leaving it unset or
empty keeps the open default.</p>
<p>Match is exact against the value the browser sends, so copy that verbatim:
scheme, host and non-default port only. No trailing slash, no path, all
lowercase, punycode (<code>xn--...</code>) for internationalised domains, and each entry a
binary rather than a string. A trailing slash, an explicit <code>:443</code> or an
uppercase host silently matches nothing and locks out real users. A value that
is not a list of binaries is treated as a misconfiguration and fails closed,
rejecting everything, with a logged error.</p>
<p>This is independent of <a href="#cors">CORS</a>: CORS governs XHR and fetch, not the
WebSocket handshake.</p>
<p>Native clients (Defold, Unity, Unreal) send no <code>Origin</code> header and are never
affected. An absent <code>Origin</code> always passes, since a non-browser client cannot
be a CSWSH vector. The socket also does nothing until it presents a valid token
in the first <code>session.connect</code> frame, so this is defence in depth, not the
primary auth gate.</p>
<h2 id="deprecated-game-extension-frames" tabindex="-1">Deprecated <code>game.*</code> extension frames</h2>
<p>Extension-produced pushes go out as <code>module.message</code> and <code>module.error</code>. The
pre-rename names <code>game.message</code> and <code>game.error</code> are emitted alongside them,
with identical payloads, so SDK builds from before the rename keep working.
They are removed at the 1.0 wire break.</p>
<pre><code class="language-erlang">{ws_legacy_game_frames, false}
</code></pre>
<p>Set this once every client on the deployment dispatches on <code>module.*</code>, and each
extension message drops from two frames to one. <code>game.message</code> carries
<code>game.send/2</code>, which a script may call per player per tick, so on a chatty game
the compatibility frame doubles that path. Any client still listening for
<code>game.*</code> goes silent the moment you set it. Default <code>true</code>. See
<a href="/docs/protocols/websocket">WebSocket protocol</a>.</p>
<h2 id="cors" tabindex="-1">CORS</h2>
<p>CORS is handled by <code>nova_cors_plugin</code> in the Nova plugin chain:</p>
<pre><code class="language-erlang">{nova, [
    {plugins, [
        {pre_request, nova_cors_plugin, #{allow_origins =&gt; ~&quot;https://mygame.com&quot;}}
    ]}
]}
</code></pre>
<p>In the image this is <code>ASOBI_CORS_ORIGINS</code>, and it has no default.</p>
<h2 id="clustering" tabindex="-1">Clustering</h2>
<p>Optional multi-node clustering via Erlang distribution. Both forms below match
<a href="/docs/clustering">Clustering</a>, which is the guide for this.</p>
<h3 id="dns-strategy-flyio-kubernetes" tabindex="-1">DNS strategy (Fly.io, Kubernetes)</h3>
<pre><code class="language-erlang">{cluster, #{
    strategy =&gt; dns,
    dns_name =&gt; ~&quot;asobi-headless.default.svc.cluster.local&quot;,
    poll_interval =&gt; 10000
}}
</code></pre>
<p><code>dns_name</code> must be a binary. A string crashes the discovery server on every
poll.</p>
<h3 id="epmd-strategy-static-hosts" tabindex="-1">EPMD strategy (static hosts)</h3>
<pre><code class="language-erlang">{cluster, #{
    strategy =&gt; epmd,
    hosts =&gt; ['host-a', 'host-b']
}}
</code></pre>
<p><code>hosts</code> are bare hostnames, not node names. asobi derives each peer's node name
by reusing this node's basename, so <code>'node@host'</code> in that list produces
<code>asobi@node@host</code>, which resolves to nothing.</p>
<h2 id="authentication-providers" tabindex="-1">Authentication providers</h2>
<h3 id="oauth-and-oidc" tabindex="-1">OAuth and OIDC</h3>
<pre><code class="language-erlang">{oidc_providers, #{
    google =&gt; #{
        issuer =&gt; ~&quot;https://accounts.google.com&quot;,
        client_id =&gt; ~&quot;...&quot;,
        client_secret =&gt; ~&quot;...&quot;
    },
    apple =&gt; #{
        issuer =&gt; ~&quot;https://appleid.apple.com&quot;,
        client_id =&gt; ~&quot;...&quot;,
        client_secret =&gt; ~&quot;...&quot;
    }
}}
</code></pre>
<p>Every provider needs <code>issuer</code>, <code>client_id</code> and <code>client_secret</code>. asobi discovers
the rest (authorize, token and JWKS endpoints) from the issuer's
<code>.well-known/openid-configuration</code> document. A provider entry with no <code>issuer</code>,
or an issuer that is not <code>https://</code>, is logged and disabled on its own; the node
still boots and the other providers are unaffected - see
<a href="/docs/authentication">Authentication</a> for the full supported-provider table and
per-provider notes.</p>
<p><code>base_url</code> is the public origin asobi uses to build redirect URIs (default
<code>~&quot;http://localhost:8082&quot;</code>). Set it to your deployed URL so the redirect
providers call back to matches what you registered:</p>
<pre><code class="language-erlang">{base_url, ~&quot;https://mygame.com&quot;}
</code></pre>
<h3 id="steam" tabindex="-1">Steam</h3>
<pre><code class="language-erlang">{steam_api_key, ~&quot;your-steam-web-api-key&quot;},
{steam_app_id, ~&quot;480&quot;}
</code></pre>
<h3 id="apple-and-google-iap" tabindex="-1">Apple and Google IAP</h3>
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
upgrade it to a real account later. It is opt-in and fails closed: the guest
endpoints return <code>403 guest.disabled</code> until the <strong>game</strong> declares <code>guest_auth = true</code> in its Lua config and the <strong>operator</strong> sets a <code>guest_verifier_pepper</code>
(ADR 0004). The game half is a Lua global, not a <code>sys.config</code> key - see
<a href="/docs/authentication#guest-anonymous">Authentication</a>. This page covers the
operator half.</p>
<pre><code class="language-erlang">%% Required. A key-id -&gt; pepper map (&gt;= 32 bytes each). Keep old key ids for the
%% guest retention window so existing guests can still resume after rotation.
{guest_verifier_pepper, #{~&quot;v1&quot; =&gt; ~&quot;a-32-byte-or-longer-secret......&quot;}},
{guest_verifier_key_id, ~&quot;v1&quot;},

%% Optional abuse control: max unclaimed guests, or `infinity`.
{guest_unlinked_cap, 100000},

%% Optional retention. Unset = permanent guests (never reaped). Seconds of
%% inactivity after which an unclaimed guest is deleted by the reaper. The
%% clock restarts every time the device resumes, so this never expires a
%% player who is still playing.
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
<td><code>guest_verifier_pepper</code></td>
<td>none</td>
<td>Key-id -&gt; pepper map, or a single binary. Each pepper must be at least 32 bytes; a shorter one is treated as absent. Presence is the operator's on switch</td>
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
<td>Seconds of inactivity since the device last resumed; unset disables the reaper, so guests are permanent</td>
</tr>
</tbody>
</table>
<p>Measured from the last resume, not from account creation. Under device auth a
guest stays unclaimed for life - there is no password to set - so account age
would say nothing about whether anyone is still playing, and a returning player
would be deleted on schedule.</p>
<p>A reaped guest is erased in full - wallet, ledger, saves, storage, chat,
friendships, identities and any installed extension's rows - through the same
<code>asobi_player_erase</code> an operator-initiated erasure uses. This is permanent and
irreversible, it takes up to 500 accounts per sweep, and the sweep writes no
audit rows; it logs a count. Set it deliberately. See
<a href="/docs/protocols/rest#erasing-and-exporting-a-player">Erasing and exporting a player</a>.</p>
<p><strong>In the image today this needs a <code>sys.config</code>.</strong> The Dockerfile declares
<code>ASOBI_GUEST_VERIFIER_PEPPER</code>, but nothing substitutes it into <code>sys.config</code>, so
setting the variable configures nothing and guest auth stays closed. Mount a
<code>sys.config</code> with the pepper until that is fixed.</p>
<p>The pepper is a server-side secret kept outside the database: keep it in a
secret manager, never in source. To rotate, add a new key id and point
<code>guest_verifier_key_id</code> at it, keeping the old ids for at least the retention
window so existing guests can still resume. Guest creation is bounded by the
per-IP <code>auth</code> limiter plus the global <code>guest_global</code> limit.</p>
<h2 id="ops-plane" tabindex="-1">Ops plane</h2>
<p>The <code>/api/v1/ops</code> routes are for a game-operations console, not a game client,
and they carry their own credential. Fails closed: unset the key and every ops
request is rejected, so a deployment that never reads this page is closed
rather than open. There is no default credential.</p>
<pre><code class="language-erlang">%% Required to use /api/v1/ops at all. Random, &gt;= 32 bytes.
{ops_secret, ~&quot;a-32-byte-or-longer-random-secret&quot;}
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
<td><code>ops_secret</code></td>
<td>none</td>
<td>Operator bearer token for <code>/api/v1/ops</code>. Unset rejects every ops request</td>
</tr>
</tbody>
</table>
<p>32 bytes is a recommendation here, not a rule: <code>asobi_ops_auth</code> accepts any
non-empty binary. <code>ops_token_secret</code> below and <code>guest_verifier_pepper</code> above
<em>are</em> length-checked and silently treat a short value as unset, so the three do
not behave alike.</p>
<p>Send it as <code>Authorization: Bearer &lt;ops_secret&gt;</code>. It is compared in constant time
and never leaves the server. Player and guest tokens are rejected here: the ops
plane never consults the player token store.</p>
<p>One secret is one privilege level: whoever holds it holds every capability
class, including <code>config</code> and <code>erasure</code>. Restrict who can reach the plane with
a reverse proxy, and set <code>x-asobi-operator</code> per person for attribution in the
audit trail - it is a label, never authority. A console session opened with
this secret is the one exception: it gets every class but <code>erasure</code> unless
<code>console_erasure</code> is set. See
<a href="/docs/protocols/rest#ops-authentication">REST API</a> for the per-route reference and
<a href="https://hexdocs.pm/asobi/console.html">Operator console</a> for the operator narrative and for what the plane
can and cannot do.</p>
<h3 id="minted-tokens-managed-environments" tabindex="-1">Minted tokens (managed environments)</h3>
<p>A managed environment takes a second kind of ops credential: a short-lived,
env-scoped token minted by a control plane after it has authenticated the tenant
and checked they own this environment. Self-hosting needs none of this, and
<a href="https://hexdocs.pm/asobi/cloud.html#the-console">Cloud</a> walks the handoff end to end.</p>
<pre><code class="language-erlang">{ops_token_secret, ~&quot;${ASOBI_OPS_TOKEN_SECRET}&quot;},
{env_id, ~&quot;${GAME_ID}&quot;}
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
<td><code>ops_token_secret</code></td>
<td>none</td>
<td>A per-environment secret that signs ops tokens and nothing else. At least 32 bytes; shorter is treated as unset</td>
</tr>
<tr>
<td><code>env_id</code></td>
<td>none</td>
<td>This environment's id. A token minted for another one is refused</td>
</tr>
</tbody>
</table>
<p>It is deliberately not the credential the engine authenticates with. A value
that both proves who the engine is and signs the operator credentials it
accepts is one leak away from doing both for an attacker, and deriving one from
the other prevents confusion but not shared compromise.</p>
<p>Rotating it revokes every ops token outstanding for the environment at once,
which is the only revocation there is.</p>
<p>Both or neither: a node that knows the secret but not which environment it is
cannot check a token's <code>env</code> claim, so it refuses every minted token rather
than accepting one issued for somebody else's environment.</p>
<p>Unlike <code>ops_secret</code>, a minted token carries only the capability classes it was
minted with, so a tenant whose role maps to <code>read</code> and <code>player_data</code> cannot
reach a <code>config</code> route with it. The role name never arrives here; the control
plane maps it to classes at mint time.</p>
<p>The lifetime is capped at 15 minutes by this node, not by the minter. A token
signed with a longer one is refused, because there is no revocation list to
fall back on if the minting side ever issues a bad one.</p>
<h2 id="operator-console" tabindex="-1">Operator console</h2>
<p>A browser console for the ops plane, served by this node at <code>/console</code>. Off by
default: Nova starts one listener, so the console shares the game port, and an
operator surface on a public port has to be asked for.</p>
<pre><code class="language-erlang">{console, true},
{ops_secret, ~&quot;a-32-byte-or-longer-random-secret&quot;}
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
<td><code>console</code></td>
<td><code>false</code></td>
<td>Serve the console at <code>/console</code>. Anything but <code>true</code> is off, and every console route answers 404</td>
</tr>
<tr>
<td><code>console_session_ttl</code></td>
<td><code>43200</code></td>
<td>Session lifetime in seconds, clamped to 60-86400. Absolute: it is not extended by use</td>
</tr>
<tr>
<td><code>console_secure_cookie</code></td>
<td><code>false</code></td>
<td>Force <code>Secure</code> on the session cookies. Set it behind a TLS terminator that does not send <code>x-forwarded-proto</code></td>
</tr>
<tr>
<td><code>console_api_base</code></td>
<td>none</td>
<td>Absolute <code>https://host[:port]</code> origin the console should call instead of this one. Also widens <code>connect-src</code>. Anything that is not a bare origin is ignored</td>
</tr>
<tr>
<td><code>console_label</code></td>
<td>none</td>
<td>Names this deployment in the tab title and the console header</td>
</tr>
<tr>
<td><code>console_production</code></td>
<td><code>false</code></td>
<td>Marks a deployment to be careful in. The console colours its label</td>
</tr>
<tr>
<td><code>console_erasure</code></td>
<td><code>false</code></td>
<td>Let a console session erase players. Off because a browser can be clickjacked and an erasure cannot be undone; a bearer secret holds the class regardless</td>
</tr>
</tbody>
</table>
<p><code>console</code>, <code>console_label</code> and <code>console_production</code> also read
<code>ASOBI_CONSOLE</code>, <code>ASOBI_CONSOLE_LABEL</code> and <code>ASOBI_CONSOLE_PRODUCTION</code>, and
<code>ops_secret</code> reads <code>ASOBI_OPS_SECRET_FILE</code> or <code>ASOBI_OPS_SECRET</code>. The other
four - <code>console_session_ttl</code>, <code>console_secure_cookie</code>, <code>console_api_base</code> and
<code>console_erasure</code> - have no environment variable and need a <code>sys.config</code>. A variable overrides
<code>sys.config</code> only when it is set, so the two coexist.</p>
<p>There is no <code>ASOBI_DB_PASSWORD_FILE</code>. The database password is substituted into
<code>sys.config</code> before any Erlang runs, so it cannot be read from a file the way
the ops secret can.</p>
<p>Sessions live in memory. The session store and the CSRF secret are per node, so
the console needs a sticky route behind a load balancer and a restart signs
everyone out - see <a href="/docs/clustering">Clustering</a> and
<a href="https://hexdocs.pm/asobi/console.html">Operator console</a>, which owns turning it on, signing in, what the
screens show and the troubleshooting.</p>
<h2 id="vote-templates" tabindex="-1">Vote templates</h2>
<p>Reusable vote configurations, merged with the per-vote config from your game
module:</p>
<pre><code class="language-erlang">{vote_templates, #{
    ~&quot;map_vote&quot; =&gt; #{
        method =&gt; ~&quot;plurality&quot;,
        window_ms =&gt; 15000,
        visibility =&gt; ~&quot;live&quot;
    }
}}
</code></pre>
<h2 id="world-capacity" tabindex="-1">World capacity</h2>
<p>Bounds on persistent world creation, enforced as a DoS backstop:</p>
<pre><code class="language-erlang">{world_max_per_player, 5},   %% default 5
{world_max, 1000}            %% default 1000
</code></pre>
<p>A player at the per-player cap gets <code>429 world.player_limit_reached</code>; once the
global cap is reached further creates get <code>503 world.capacity_reached</code>. The
global cap is checked first.</p>
<h2 id="join-rate" tabindex="-1">Join rate</h2>
<p>Joins are bounded per player, not per IP:</p>
<pre><code class="language-erlang">{rate_limits, #{
    join =&gt; #{algorithm =&gt; sliding_window, limit =&gt; 10, window =&gt; 60000}
}}
</code></pre>
<p>Joining is how a client reaches a world's roster and leaving is free, so an
unbounded join rate lets one account enumerate every live world by joining,
reading <code>world.joined</code> and leaving. The default (10 per minute) is generous for
real play and turns a sweep of a full deployment from seconds into hours per
identity. Exceeding it returns <code>join_rate_limited</code> and emits <code>[asobi, join, rate_limited]</code>.</p>
<p>This bounds the cost of a sweep; it does not make worlds private. For that,
implement <code>join/3</code> in your game module and reject unauthorised joins - see
<a href="/docs/protocols/websocket">WebSocket protocol</a>.</p>
<h2 id="zone-crossing-rate" tabindex="-1">Zone crossing rate</h2>
<p>For <code>world</code>-mode games, re-homing a player across a zone boundary is bounded
per player and, separately, globally:</p>
<pre><code class="language-erlang">{rate_limits, #{
    rehome =&gt; #{algorithm =&gt; sliding_window, limit =&gt; 5, window =&gt; 1000},
    rehome_global =&gt; #{algorithm =&gt; sliding_window, limit =&gt; 200, window =&gt; 1000}
}}
</code></pre>
<p>Each crossing updates part of the player's interest ring and resends a full
zone snapshot to any newly-subscribed zone, so an unbounded rate lets one
client force that work every tick by parking on a zone boundary. The per-player
default (5/sec) bounds the worst case on top of the crossing's own hysteresis
margin (see <a href="/docs/world-server">World server</a>); it caps sustained crossing speed
at <code>limit * zone_size</code> units/sec, so a fast-moving game on a small <code>zone_size</code>
may need to raise it. The global bucket bounds the aggregate load N concurrent
attackers can push into the world's single terrain store.</p>
<p>Denied crossings are not dropped input: the player's position still updates
within their current zone, they just do not re-home that tick. Exceeding the
limit emits <code>[asobi, rehome, rate_limited]</code>.</p>
<h2 id="terrain-provider-allowlist" tabindex="-1">Terrain provider allowlist</h2>
<p>For Lua large-world games, only allowlisted terrain generators can be named
from Lua:</p>
<pre><code class="language-erlang">{asobi, [
    {terrain_providers, [asobi_terrain_flat, asobi_terrain_perlin]}
]}
</code></pre>
<p>The default allows <code>asobi_terrain_flat</code> and <code>asobi_terrain_perlin</code>.</p>
<h2 id="per-call-upper-bounds" tabindex="-1">Per-call upper bounds</h2>
<p>These runtime limits bound the cost of a single request. They are not
configurable; they are here so you can size clients accordingly.</p>
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
<h2 id="background-jobs-shigoto" tabindex="-1">Background jobs (Shigoto)</h2>
<pre><code class="language-erlang">{shigoto, [
    {pool, asobi_repo}
]}
</code></pre>
<h2 id="full-example-erlang-sysconfig" tabindex="-1">Full example (Erlang sys.config)</h2>
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
                    min_players =&gt; 4,
                    script =&gt; ~&quot;game/bots/chaser.lua&quot;
                }
            }
        }}
    ]}
].
</code></pre>
<h2 id="full-example-lua-and-docker" tabindex="-1">Full example (Lua and Docker)</h2>
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
    image: ghcr.io/widgrensit/asobi:latest
    depends_on:
      postgres: { condition: service_healthy }
    ports:
      - &quot;8084:8084&quot;
    volumes:
      - ./lua:/app/game:ro
    environment:
      ASOBI_DB_HOST: postgres
      ASOBI_DB_NAME: my_game_dev
      ASOBI_CORS_ORIGINS: https://play.yourgame.com
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
<li><a href="https://hexdocs.pm/asobi/self-hosting.html">Self-hosting</a> - requirements, the production compose, and
what to check before you go live.</li>
<li><a href="/docs/clustering">Clustering</a> - multi-node config and what is per node.</li>
<li><a href="https://hexdocs.pm/asobi/console.html">Operator console</a> - turning the console on and using it.</li>
<li><a href="/docs/performance">Performance tuning</a> - the tick and BEAM knobs.</li>
</ul>
"""}
    ]}.
