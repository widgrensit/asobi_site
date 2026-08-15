%% GENERATED from asobi guides/exit.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_exit_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1, markdown/0]).

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
<p>A runbook for keeping your game alive if Widgrens IT AB, the company behind
asobi, vanishes, pivots, gets acquired or otherwise stops. It exists because
you should not have to trust us.</p>
<h2 id="what-we-commit-to" tabindex="-1">What we commit to</h2>
<ol>
<li><strong>Apache-2.0 forever.</strong> <a href="https://github.com/widgrensit/asobi">asobi</a> is
published under Apache-2.0, and that includes the Lua runtime and the
operator console, which are part of the same repository. We will never
relicense: no BSL, no SSPL, no dual track. If the licence ever has to
change we will fork our own project under a new name rather than take
Apache-2.0 away from you.</li>
<li><strong>No closed core.</strong> Every feature in the public repository is the feature
you run. Our commercial cloud runs the same <code>asobi</code> library published here.
It is a different release build - <code>ghcr.io/widgrensit/asobi_engine</code>, which
fetches its Lua as a bundle rather than reading a mounted directory - so the
artefact is not byte-identical to <code>ghcr.io/widgrensit/asobi:latest</code>, but the
game code behind it is the code in this repository. There is no feature the
cloud has and this repository does not. See <a href="https://hexdocs.pm/asobi/cloud.html">Cloud</a>.</li>
<li><strong>Public images mirrored.</strong> Published to GitHub Container Registry under
<code>ghcr.io/widgrensit/*</code>. GHCR is free to pull without authentication, and you
can mirror to your own registry.</li>
<li><strong>No phone-home and no licence check-in.</strong> The node works indefinitely
without talking to us.</li>
<li><strong>Git history is the source of truth.</strong> No force-pushes to release tags, no
rewritten history on <code>main</code>.</li>
</ol>
<h2 id="if-we-go-quiet-here-is-what-to-do" tabindex="-1">If we go quiet, here is what to do</h2>
<h3 id="1-pin-a-known-good-version" tabindex="-1">1. Pin a known-good version</h3>
<p>As soon as you notice us gone quiet - no commits, no releases, nothing for 30
days or more - pin your deployment to a specific image digest:</p>
<pre><code class="language-yaml"># docker-compose.yml
services:
  asobi:
    image: ghcr.io/widgrensit/asobi@sha256:&lt;digest-of-your-last-known-good&gt;
</code></pre>
<p>Get the digest from <code>docker pull</code> output or from the
<a href="https://github.com/widgrensit/asobi/pkgs/container/asobi">GHCR package page</a>.</p>
<h3 id="2-mirror-the-image-to-your-own-registry" tabindex="-1">2. Mirror the image to your own registry</h3>
<pre><code class="language-bash">docker pull ghcr.io/widgrensit/asobi:latest
docker tag ghcr.io/widgrensit/asobi:latest \
           your-registry.example.com/asobi:v-$(date +%Y-%m-%d)
docker push your-registry.example.com/asobi:v-$(date +%Y-%m-%d)
</code></pre>
<p>Point your compose file or k8s manifest at <code>your-registry.example.com</code>. You now
own the runtime.</p>
<h3 id="3-fork-the-source" tabindex="-1">3. Fork the source</h3>
<p>One repository. The game backend, the Lua runtime and the operator console are
all in it.</p>
<pre><code class="language-bash">git clone https://github.com/widgrensit/asobi.git
</code></pre>
<p>Push it to your own remote. The full history comes with it, and you can build
the image yourself:</p>
<pre><code class="language-bash">cd asobi
docker build -t myorg/asobi:from-fork .
</code></pre>
<h3 id="4-export-everything" tabindex="-1">4. Export everything</h3>
<p>Two things make up a running deployment, and a backup of only the first is not
a backup.</p>
<p><strong>Your database.</strong> All persistent state lives in the PostgreSQL you host:
players, wallets, transactions, inventories, match records, votes, IAP
transactions, leaderboards, chat history, cloud saves.</p>
<pre><code class="language-bash">docker compose exec postgres pg_dump -U postgres my_game &gt; backup-$(date +%Y-%m-%d).sql
</code></pre>
<p><strong>Your game scripts.</strong> These are not in the database and they are not in the
image. They are the directory you mount at <code>/app/game</code> - <code>match.lua</code>,
<code>config.lua</code>, world scripts, bot scripts, anything they require. That directory
is the game. Keep it in version control and back it up alongside the dump.</p>
<pre><code class="language-bash">tar czf game-$(date +%Y-%m-%d).tar.gz ./game
</code></pre>
<p>Restore both onto stock PostgreSQL and the image you mirrored, and you have a
functioning deployment.</p>
<h4 id="do-not-lose-the-operator-surface" tabindex="-1">Do not lose the operator surface</h4>
<p>The console and the ops API are configured entirely from the environment, so
they live in your compose file rather than in the database or the game
directory. A custodian who rebuilds from a dump and a script tarball and
forgets them ends up with a working game and no way to look at it.</p>
<p>Carry <code>ASOBI_CONSOLE</code> and the ops secret (<code>ASOBI_OPS_SECRET_FILE</code>, or
<code>ASOBI_OPS_SECRET</code>) across with the rest of your deployment configuration, and
carry the secret file itself. See <a href="https://hexdocs.pm/asobi/console.html">Operator console</a>.</p>
<h3 id="5-update-otp-and-postgres-yourself" tabindex="-1">5. Update OTP and Postgres yourself</h3>
<p>asobi depends on standard, long-lived open-source infrastructure:</p>
<ul>
<li><strong>Erlang/OTP.</strong> Ericsson maintains it and does not disappear.</li>
<li><strong>PostgreSQL.</strong> Standard <code>pg_upgrade</code> works.</li>
<li><strong>Lua 5.3 via <a href="https://github.com/rvirding/luerl">Luerl</a></strong>, also Apache-2.0.</li>
</ul>
<p>The tested combination is in the Requirements section of
<a href="https://hexdocs.pm/asobi/self-hosting.html#requirements">Self-hosting</a>. Older or newer versions may well
work; they are not what CI runs, so verify before you commit to one.</p>
<h3 id="6-join-a-community-fork" tabindex="-1">6. Join a community fork</h3>
<p>If we go dark, someone is likely to pick up maintenance. Watch:</p>
<ul>
<li>GitHub forks of <code>widgrensit/asobi</code></li>
<li>The <code>#operations</code> channel on the <a href="https://discord.gg/vYSfYYyXpu">Discord</a></li>
<li>The Erlang Forum (<code>erlangforums.com</code>), <code>#gamedev</code></li>
</ul>
<h2 id="what-is-not-covered-here" tabindex="-1">What is not covered here</h2>
<p>This page covers the open-source node. The commercial <code>asobi.dev</code> cloud is a
separate layer, described in <a href="https://hexdocs.pm/asobi/cloud.html">Cloud</a>. If we shut the managed service
down, we commit to:</p>
<ul>
<li>60 days' notice minimum, in writing</li>
<li>an export of your data, your scripts and your PostgreSQL dump in a form you
can self-host</li>
<li>best-effort migration help through the shutdown date</li>
</ul>
<p>The open-source side stays open source regardless.</p>
<h2 id="questions" tabindex="-1">Questions</h2>
<p>Open an issue, post in the Discord <code>#operations</code> channel, or email
<code>hello@asobi.dev</code>. If none of those still exist, fork the code, export your
Postgres and your game directory, and you are the custodian now.</p>
"""}
    ]}.

%% The guide source, served at this page's .md URL. asobi_site_markdown cannot
%% walk the {raw, ...} blob above, and does not need to: this is what that HTML
%% was rendered from.
-spec markdown() -> binary().
markdown() ->
    ~"""
# If asobi disappears tomorrow

A runbook for keeping your game alive if Widgrens IT AB, the company behind
asobi, vanishes, pivots, gets acquired or otherwise stops. It exists because
you should not have to trust us.

## What we commit to

1. **Apache-2.0 forever.** [asobi](https://github.com/widgrensit/asobi) is
   published under Apache-2.0, and that includes the Lua runtime and the
   operator console, which are part of the same repository. We will never
   relicense: no BSL, no SSPL, no dual track. If the licence ever has to
   change we will fork our own project under a new name rather than take
   Apache-2.0 away from you.
2. **No closed core.** Every feature in the public repository is the feature
   you run. Our commercial cloud runs the same `asobi` library published here.
   It is a different release build - `ghcr.io/widgrensit/asobi_engine`, which
   fetches its Lua as a bundle rather than reading a mounted directory - so the
   artefact is not byte-identical to `ghcr.io/widgrensit/asobi:latest`, but the
   game code behind it is the code in this repository. There is no feature the
   cloud has and this repository does not. See [Cloud](https://hexdocs.pm/asobi/cloud.html).
3. **Public images mirrored.** Published to GitHub Container Registry under
   `ghcr.io/widgrensit/*`. GHCR is free to pull without authentication, and you
   can mirror to your own registry.
4. **No phone-home and no licence check-in.** The node works indefinitely
   without talking to us.
5. **Git history is the source of truth.** No force-pushes to release tags, no
   rewritten history on `main`.

## If we go quiet, here is what to do

### 1. Pin a known-good version

As soon as you notice us gone quiet - no commits, no releases, nothing for 30
days or more - pin your deployment to a specific image digest:

```yaml
# docker-compose.yml
services:
  asobi:
    image: ghcr.io/widgrensit/asobi@sha256:<digest-of-your-last-known-good>
```

Get the digest from `docker pull` output or from the
[GHCR package page](https://github.com/widgrensit/asobi/pkgs/container/asobi).

### 2. Mirror the image to your own registry

```bash
docker pull ghcr.io/widgrensit/asobi:latest
docker tag ghcr.io/widgrensit/asobi:latest \
           your-registry.example.com/asobi:v-$(date +%Y-%m-%d)
docker push your-registry.example.com/asobi:v-$(date +%Y-%m-%d)
```

Point your compose file or k8s manifest at `your-registry.example.com`. You now
own the runtime.

### 3. Fork the source

One repository. The game backend, the Lua runtime and the operator console are
all in it.

```bash
git clone https://github.com/widgrensit/asobi.git
```

Push it to your own remote. The full history comes with it, and you can build
the image yourself:

```bash
cd asobi
docker build -t myorg/asobi:from-fork .
```

### 4. Export everything

Two things make up a running deployment, and a backup of only the first is not
a backup.

**Your database.** All persistent state lives in the PostgreSQL you host:
players, wallets, transactions, inventories, match records, votes, IAP
transactions, leaderboards, chat history, cloud saves.

```bash
docker compose exec postgres pg_dump -U postgres my_game > backup-$(date +%Y-%m-%d).sql
```

**Your game scripts.** These are not in the database and they are not in the
image. They are the directory you mount at `/app/game` - `match.lua`,
`config.lua`, world scripts, bot scripts, anything they require. That directory
is the game. Keep it in version control and back it up alongside the dump.

```bash
tar czf game-$(date +%Y-%m-%d).tar.gz ./game
```

Restore both onto stock PostgreSQL and the image you mirrored, and you have a
functioning deployment.

#### Do not lose the operator surface

The console and the ops API are configured entirely from the environment, so
they live in your compose file rather than in the database or the game
directory. A custodian who rebuilds from a dump and a script tarball and
forgets them ends up with a working game and no way to look at it.

Carry `ASOBI_CONSOLE` and the ops secret (`ASOBI_OPS_SECRET_FILE`, or
`ASOBI_OPS_SECRET`) across with the rest of your deployment configuration, and
carry the secret file itself. See [Operator console](https://hexdocs.pm/asobi/console.html).

### 5. Update OTP and Postgres yourself

asobi depends on standard, long-lived open-source infrastructure:

- **Erlang/OTP.** Ericsson maintains it and does not disappear.
- **PostgreSQL.** Standard `pg_upgrade` works.
- **Lua 5.3 via [Luerl](https://github.com/rvirding/luerl)**, also Apache-2.0.

The tested combination is in the Requirements section of
[Self-hosting](https://hexdocs.pm/asobi/self-hosting.html#requirements). Older or newer versions may well
work; they are not what CI runs, so verify before you commit to one.

### 6. Join a community fork

If we go dark, someone is likely to pick up maintenance. Watch:

- GitHub forks of `widgrensit/asobi`
- The `#operations` channel on the [Discord](https://discord.gg/vYSfYYyXpu)
- The Erlang Forum (`erlangforums.com`), `#gamedev`

## What is not covered here

This page covers the open-source node. The commercial `asobi.dev` cloud is a
separate layer, described in [Cloud](https://hexdocs.pm/asobi/cloud.html). If we shut the managed service
down, we commit to:

- 60 days' notice minimum, in writing
- an export of your data, your scripts and your PostgreSQL dump in a form you
  can self-host
- best-effort migration help through the shutdown date

The open-source side stays open source regardless.

## Questions

Open an issue, post in the Discord `#operations` channel, or email
`hello@asobi.dev`. If none of those still exist, fork the code, export your
Postgres and your game directory, and you are the custodian now.
""".
