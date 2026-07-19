%% GENERATED from asobi guides/exit.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_exit_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(#{id => ~"docs-exit", title => ~"If Asobi disappears — Asobi docs"}, Bindings),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / No lock-in"
        ]},
        {h1, [], [~"If asobi disappears tomorrow"]},
        {raw,
            ~"""
<p>This is a one-page runbook for keeping your game alive if Widgrensit AB
(the company behind asobi) vanishes, pivots to AI, gets acquired, or
otherwise ceases to exist. <strong>We wrote it because you shouldn't have to
trust us.</strong></p>
<h2 id="what-we-commit-to" tabindex="-1">What we commit to</h2>
<ol>
<li><strong>Apache-2.0 forever.</strong> The <a href="https://github.com/widgrensit/asobi">asobi library</a>
and <a href="https://github.com/widgrensit/asobi_lua">asobi_lua runtime</a> are
published under Apache-2.0. <strong>We will never relicense</strong> — no BSL, no
SSPL, no Business Source dual-track. If we need to change the licence
we'll fork our own project under a new name rather than take Apache-2
away from you.</li>
<li><strong>No closed-core.</strong> Every feature in the public repos is the feature you
run. Our commercial cloud runs the same binary you can pull from
<code>ghcr.io/widgrensit/asobi_lua:latest</code>.</li>
<li><strong>Public Docker images mirrored.</strong> Published to GitHub Container Registry
under <code>ghcr.io/widgrensit/*</code>. GHCR is free to pull without auth; you can
also mirror to your own registry.</li>
<li><strong>No mandatory phone-home, no licence check-in.</strong> The runtime works
indefinitely without talking to us.</li>
<li><strong>Git history is the source of truth.</strong> No force-pushes to release tags.
No rewritten history on <code>main</code>.</li>
</ol>
<h2 id="if-we-disappear-heres-what-to-do" tabindex="-1">If we disappear, here's what to do</h2>
<h3 id="1-pin-a-known-good-version" tabindex="-1">1. Pin a known-good version</h3>
<p>As soon as you see us go quiet (no commits / no Discord / no blog posts for
30+ days), pin your deployment to a specific Docker image digest:</p>
<pre><code class="language-yaml"># docker-compose.yml
services:
  asobi:
    # Before: ghcr.io/widgrensit/asobi_lua:latest
    # After: pinned by digest
    image: ghcr.io/widgrensit/asobi_lua@sha256:&lt;digest-of-your-last-known-good&gt;
</code></pre>
<p>Grab the digest from <code>docker pull</code> output or the
<a href="https://github.com/widgrensit/asobi_lua/pkgs/container/asobi_lua">GHCR package page</a>.</p>
<h3 id="2-mirror-the-image-to-your-own-registry" tabindex="-1">2. Mirror the image to your own registry</h3>
<pre><code class="language-bash">docker pull ghcr.io/widgrensit/asobi_lua:latest
docker tag ghcr.io/widgrensit/asobi_lua:latest \
           your-registry.example.com/asobi_lua:v-$(date +%Y-%m-%d)
docker push your-registry.example.com/asobi_lua:v-$(date +%Y-%m-%d)
</code></pre>
<p>Point your <code>docker-compose.yml</code> / k8s manifest at <code>your-registry.example.com</code>.
You now own the runtime.</p>
<h3 id="3-fork-the-source" tabindex="-1">3. Fork the source</h3>
<pre><code class="language-bash">git clone https://github.com/widgrensit/asobi.git
git clone https://github.com/widgrensit/asobi_lua.git
# Push both to your own remote.
</code></pre>
<p>Both repos include the full history. You can build the Docker image yourself:</p>
<pre><code class="language-bash">cd asobi_lua
docker build -t myorg/asobi_lua:from-fork .
</code></pre>
<h3 id="4-export-your-data" tabindex="-1">4. Export your data</h3>
<p>Every piece of state in asobi lives in PostgreSQL (the one you host). There
is <strong>no state outside your database</strong>. To produce a cold-storage backup:</p>
<pre><code class="language-bash"># Full logical backup
docker compose exec postgres pg_dump -U postgres my_game &gt; backup-$(date +%Y-%m-%d).sql

# Binary backup (faster to restore)
docker compose exec postgres pg_basebackup -U postgres -D /backup -Fp
</code></pre>
<p>Restoring onto any stock PostgreSQL server (any version within pgo's
supported range) gets you back a functional asobi tenant.</p>
<h3 id="5-update-otp-postgres-yourself" tabindex="-1">5. Update OTP / Postgres yourself</h3>
<p>asobi depends on standard, long-lived open-source infrastructure:</p>
<ul>
<li><strong>Erlang/OTP</strong> ≥ 28. Upgrade path: drop in a newer OTP version, run
<code>rebar3 compile</code>. asobi spec-is-clean and tested against recent OTP;
upstream OTP is Ericsson's responsibility and they don't disappear.</li>
<li><strong>PostgreSQL</strong> ≥ 15. Standard <code>pg_upgrade</code> works.</li>
<li><strong>Lua</strong> 5.3 via <a href="https://github.com/rvirding/luerl">Luerl</a>. Rob Virding
(the V in BEAM) maintains Luerl in Apache-2 as well.</li>
</ul>
<p>None of these depend on us being alive.</p>
<h3 id="6-join-the-community-fork" tabindex="-1">6. Join the community fork</h3>
<p>If we go dark, it's likely someone in the Discord — or the closest thing
the Discord becomes — will pick up maintenance. Keep an eye on:</p>
<ul>
<li>GitHub forks of <code>widgrensit/asobi</code> and <code>widgrensit/asobi_lua</code></li>
<li>The <code>#operations</code> channel on the <a href="https://discord.gg/vYSfYYyXpu">Asobi Discord</a></li>
<li>The Erlang Forum (<code>erlangforums.com</code>) and the #gamedev tag</li>
</ul>
<h2 id="what-isnt-here" tabindex="-1">What isn't here</h2>
<p>This guide covers the open-source library + runtime only. The commercial
<code>asobi.dev</code> cloud (opens later in 2026) is a separate layer: if we shut down
the managed service, we'll give you:</p>
<ul>
<li>60 days' notice minimum, in writing, before shutdown</li>
<li>A one-click <strong>&quot;export everything to a Docker bundle&quot;</strong> button that
produces a runnable self-host package with your data, your scripts, and
your PostgreSQL dump</li>
<li>Best-effort migration help through the shutdown date</li>
</ul>
<p>The open-source side stays open-source regardless.</p>
<h2 id="questions" tabindex="-1">Questions?</h2>
<p>Open an issue, post in the Discord <code>#operations</code> channel, or email
<code>hello@asobi.dev</code>. If none of those still exist — fork the code, export
your Postgres, and you're the custodian now.</p>
<p>We'd rather earn your trust by making leaving easy.</p>
"""}
    ]}.
