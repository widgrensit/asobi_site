%% GENERATED from asobi guides/observability.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_observability_view).

-export([mount/1, render/1, markdown/0]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-observability", title => ~"Observability — Asobi docs"}, Bindings
        ),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Observability"
        ]},
        {h1, [], [~"Observability"]},
        {raw,
            ~"""
<p>asobi emits <code>telemetry</code> events and structured JSON logs. It does not ship a
metrics endpoint, a dashboard or an alerting rule, and that is deliberate: a
game backend that grows its own time-series store is a maintenance liability
with a strictly better substitute one hop away. Wire the events to Prometheus,
point your log shipper at stdout, and let Grafana own the graphs.</p>
<p>The operator console at <code>/console</code> answers &quot;what is this node doing right
now&quot;. Everything on this page answers &quot;what has it been doing for six hours&quot;,
which is a different question with a different tool. See
<a href="https://hexdocs.pm/asobi/console.html">Operator console</a> for the first one.</p>
<h2 id="what-you-get" tabindex="-1">What you get</h2>
<ul>
<li><strong>40 telemetry events</strong>, listed below. Stable names; the measurement and
metadata keys are documented per-event in <code>m:asobi_telemetry</code>.</li>
<li><strong>Structured JSON logs</strong> on stdout, one object per line, via
<code>nova_jsonlogger</code>. No configuration needed - a container log shipper reads
them as-is.</li>
<li><strong><code>GET /health</code></strong> and <strong><code>GET /ready</code></strong> for liveness and readiness.</li>
</ul>
<h2 id="what-you-do-not-get" tabindex="-1">What you do not get</h2>
<ul>
<li><strong>No <code>/metrics</code> route.</strong> asobi has no opinion about your scrape path,
registry, or which events become counters versus histograms. Attaching an
exporter is about fifteen lines, below.</li>
<li><strong>No dashboards or alert rules</strong> shipped in this repo yet.</li>
<li><strong>No log aggregation.</strong> The logs are structured; shipping them is your
stack's job.</li>
</ul>
<h2 id="prometheus" tabindex="-1">Prometheus</h2>
<p>Add <code>telemetry_metrics_prometheus</code> to your release and declare the metrics you
want. Nothing in asobi needs changing.</p>
<pre><code class="language-erlang">{deps, [
    {telemetry_metrics_prometheus, &quot;~&gt; 1.1&quot;}
]}.
</code></pre>
<pre><code class="language-erlang">%% In your own application's start/2.
Metrics = [
    telemetry_metrics:counter(~&quot;asobi.match.started.count&quot;, #{
        event_name =&gt; [asobi, match, started],
        measurement =&gt; count,
        tags =&gt; [mode]
    }),
    telemetry_metrics:distribution(~&quot;asobi.match.finished.duration_ms&quot;, #{
        event_name =&gt; [asobi, match, finished],
        measurement =&gt; duration_ms,
        tags =&gt; [mode]
    }),
    telemetry_metrics:counter(~&quot;asobi.ws.connected.count&quot;, #{
        event_name =&gt; [asobi, ws, connected],
        measurement =&gt; count
    })
],
{ok, _} = telemetry_metrics_prometheus:start_link(#{metrics =&gt; Metrics}).
</code></pre>
<h3 id="choosing-tags" tabindex="-1">Choosing tags</h3>
<p>A tag becomes a Prometheus label, and a label with unbounded cardinality will
take down your Prometheus rather than your game. <code>mode</code>, <code>reason</code> and <code>result</code>
are bounded and safe. <strong><code>player_id</code>, <code>match_id</code>, <code>world_id</code> and <code>zone_id</code> are
not</strong> - they are one series per entity, forever. They are in the metadata
because a trace exporter and a log line want them; that is not the same as a
metric label wanting them.</p>
<p><a href="https://github.com/widgrensit/asobi/blob/main/docs/adr/0005-telemetry-event-surface.md">ADR 0005</a>
classifies the metadata keys it covers by label safety. It predates several of
the events below, so treat the list on this page as the current surface and the
ADR as the reasoning.</p>
<h3 id="in-a-cluster" tabindex="-1">In a cluster</h3>
<p>Label every series with the node, or you cannot tell a fleet-wide change from
one node misbehaving. Most of these events are per-node by nature: the process
that emitted one lives somewhere specific.</p>
<pre><code class="language-erlang">telemetry_metrics_prometheus:start_link(#{
    metrics =&gt; Metrics,
    default_tags =&gt; #{node =&gt; atom_to_binary(node(), utf8)}
})
</code></pre>
<h2 id="logs" tabindex="-1">Logs</h2>
<p>Every line is a JSON object on stdout. In Kubernetes, Promtail or Grafana Alloy
picks them up with no application configuration; under Compose, point your
shipper at the container's logs.</p>
<p>Fields worth building queries on:</p>
<table>
<thead>
<tr>
<th>Field</th>
<th>What it is</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>msg</code></td>
<td>a stable event slug, e.g. <code>console_enabled</code>, <code>engine_bootstrap_failed</code></td>
</tr>
<tr>
<td><code>level</code></td>
<td><code>debug</code> through <code>error</code></td>
</tr>
<tr>
<td><code>mfa</code></td>
<td>module, function and arity that logged it</td>
</tr>
<tr>
<td><code>file</code>, <code>line</code></td>
<td>where in the source</td>
</tr>
</tbody>
</table>
<p>Slugs are stable and worth alerting on. <code>engine_bootstrap_failed</code> and
<code>console_disabled_without_secret</code> both mean a deployment came up wrong, and
both are the kind of thing that is otherwise noticed a day later.</p>
<h2 id="the-events" tabindex="-1">The events</h2>
<p>Fifty-two, grouped by what they are about. Measurement and metadata keys
are in <code>m:asobi_telemetry</code>, which is also the list <code>asobi_telemetry:events/0</code>
returns - attach to that rather than restating the names.</p>
<h3 id="sessions-and-the-socket" tabindex="-1">Sessions and the socket</h3>
<pre><code>asobi.session.connected          asobi.session.disconnected
asobi.ws.connected               asobi.ws.disconnected
asobi.ws.message_in              asobi.ws.message_out
asobi.ws.connect_rate_limited    asobi.ws.idle_auth_timeout
asobi.ws.origin_rejected         asobi.ws.legacy_input_unwrap
asobi.dgram.bindings_expired     asobi.dgram.dropped
asobi.dgram.send_failed          asobi.dgram.recv_failed
asobi.dgram.input_undelivered    asobi.dgram.input_unknown
asobi.dgram.input_undecodable    asobi.dgram.canary_missed
asobi.dgram.link_up              asobi.dgram.link_closed
asobi.dgram.link_error           asobi.dgram.pose_saturated
</code></pre>
<p>The <code>asobi.dgram.*</code> events fire only on a node in the
<a href="/docs/configuration#the-datagram-gateway-role"><code>dgram_gw</code> role</a>.</p>
<p><code>asobi.dgram.dropped</code> is the one to build a dashboard on, and <code>gate</code> is why it is
one event rather than seven. Nothing is ever sent back to a rejected datagram, so
this counter is the only evidence a rejection happened at all.</p>
<table>
<thead>
<tr>
<th><code>gate</code> rising</th>
<th>What it means</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>parse</code> alone</td>
<td>Someone is pointing a scanner at the port. Uninteresting.</td>
</tr>
<tr>
<td><code>parse</code> + <code>ingress_global</code></td>
<td>A volumetric flood. The global tier is doing its job.</td>
</tr>
<tr>
<td><code>unknown_conn</code></td>
<td>Guessing at <code>conn_id</code>s, which is a 32-bit space.</td>
</tr>
<tr>
<td><code>mac</code></td>
<td><strong>Wake up.</strong> Someone has a live <code>conn_id</code> and not the key.</td>
</tr>
<tr>
<td><code>ingress</code> / <code>input</code></td>
<td>One connection over its budget: a broken client, usually.</td>
</tr>
<tr>
<td><code>binding</code></td>
<td>Replays or a flapping path. Check <code>reason</code>.</td>
</tr>
</tbody>
</table>
<p><code>asobi.dgram.canary_missed</code> carries <code>consecutive</code>, and that is the field to alert
on: one miss is a scheduler hiccup, two in a row means the receive loop is wedged
and the node stops reporting ready. It is the only signal that separates a wedged
loop from a quiet port, which look identical from outside. Note what it does not
cover: <code>SO_REUSEPORT</code> means the kernel chooses which shard receives the probe, so
a healthy canary proves <strong>at least one</strong> shard is alive, not all of them. A single
wedged shard shows up as a fraction of players timing out, and the place to catch
that is <code>asobi.dgram.recv_failed</code> plus client-side telemetry.</p>
<p><code>asobi.dgram.pose_saturated</code> counts transform values that did not fit their
configured scale. Any sustained rate means the <code>scale</code> in
<a href="/docs/configuration#describing-your-transform-fields"><code>dgram_pose</code></a> is wrong for
this game's world size, and the fix is configuration rather than code.</p>
<p><code>asobi.dgram.link_error</code> with <code>reason = bad_auth</code> is worth an alert. The engine
link is loopback-only, so a failed authentication is either a misconfigured
<code>dgram_link_secret</code> or something local that should not be talking to it.</p>
<p><code>asobi.dgram.link_closed</code> on its own is not an outage: bindings already in the
table keep working, so players stay on the plane while the engine restarts. What
stops is new mints and revocations, and an undeliverable revocation is bounded by
the mint's own expiry.</p>
<p><code>asobi.dgram.input_unknown</code> is expected in small numbers around a session ending,
because the two ends revoke asynchronously. Sustained, it means the gateway
believes in a binding the engine has forgotten.</p>
<p><code>asobi.dgram.bindings_expired</code> fires once per sweep, counting datagram
credentials that were minted and never used. A rising count is
a client-side fault rather than an attack - minting costs an authenticated
WebSocket, so this is clients opening the plane and walking away, not anyone
getting something for free.</p>
<p><code>asobi.ws.origin_rejected</code> and <code>asobi.ws.connect_rate_limited</code> are the two
worth alerting on: a spike in either is either an attack or a client
misconfiguration, and both are invisible in game metrics.</p>
<p><code>asobi.ws.legacy_input_unwrap</code> counts input frames sent in the deprecated
sole-<code>data</code> shape (see <a href="/docs/protocols/websocket#worldinput">WebSocket protocol</a>).
It is not an error, and not worth an alert: it exists so the carve-out can be
retired once the counter reaches zero for a release, instead of guessing which
clients still depend on it.</p>
<h3 id="matches-and-matchmaking" tabindex="-1">Matches and matchmaking</h3>
<pre><code>asobi.match.started              asobi.match.finished
asobi.match.player_joined        asobi.match.player_left
asobi.matchmaker.queued          asobi.matchmaker.removed
asobi.matchmaker.deduped         asobi.matchmaker.formed
asobi.matchmaker.failed
</code></pre>
<p>Queue depth is the number worth watching, and in a cluster it is per-node -
each node's matchmaker holds its own tickets, so a fleet-wide total is a sum
across nodes, not a reading from one. See <a href="/docs/clustering">Clustering</a>.</p>
<p><strong>The alert worth having is <code>removed{reason=expired}</code> rising while <code>formed</code>
stays flat.</strong> That pair says exactly one thing, with no interpretation needed:
players waited the full <code>max_wait_seconds</code> and got nothing. Removals carry
<code>reason</code> - <code>cancelled</code> when a client withdraws, <code>expired</code> when the ticket times
out - and only <code>expired</code> means the matchmaker failed to do its job.</p>
<p><code>deduped</code> fires when a player asks to queue for a mode they already have an
open ticket on and gets that ticket back. (The client-facing field on the reply
is named <code>already_queued</code>; the metric keeps the mechanism's name.) Some of it
is routine: a double-tapped <em>find match</em>, and reconnect resubmits, which are
idempotent by design. It is a hint, not a diagnosis. A sustained rate is worth looking at -
one cause is several clients authenticated as the same player, which no amount
of waiting will fix because one player cannot fill a two-player match - but a
bored player re-tapping in an empty queue produces the same shape.</p>
<p>Note what this view <strong>cannot</strong> tell you. Distinguishing &quot;one player re-tapping&quot;
from &quot;several clients sharing one identity&quot; needs a distinct-player count, and
<code>player_id</code> is unbounded so an exporter must never make it a label (see
<a href="https://github.com/widgrensit/asobi/blob/main/docs/adr/0005-telemetry-event-surface.md">ADR 0005</a>).
<code>queued</code> and <code>deduped</code> are counters of events, not a live-ticket count - queue
depth is the snapshot gauge described above. To separate those two cases you
need the node's queue snapshot or its logs, not Prometheus.</p>
<p>Handlers run <strong>synchronously in the process that emitted the event</strong>, so a
handler attached to a matchmaker event runs inside the matchmaker's own message
loop. Never call <code>asobi_matchmaker:get_queue_stats/0</code> from one - that is a
<code>gen_server:call</code> to the process currently executing your handler, so it
deadlocks until the call times out and stalls matchmaking for every player
meanwhile. Read <code>asobi_matchmaker:snapshot/0</code> instead: it reads ETS and never
messages the matchmaker.</p>
<h3 id="worlds-and-zones" tabindex="-1">Worlds and zones</h3>
<pre><code>asobi.world.started              asobi.world.finished
asobi.world.player_joined        asobi.world.player_left
asobi.world.phase_changed        asobi.world.tick
asobi.zone.opened                asobi.zone.closed
asobi.zone.tick_skipped          asobi.join.rate_limited
asobi.rehome.rate_limited
</code></pre>
<p><code>asobi.world.tick</code> is sampled rather than emitted every tick - at 20 Hz per
world an unsampled event is a metrics pipeline of its own.</p>
<p><code>asobi.zone.tick_skipped</code> is the one to alert on. It counts zones the world
tick skipped because they had not finished the previous one, so a healthy
world never emits it at all and a sustained non-zero rate means a world that
can no longer keep up. A single event is a zone that ran long once, which is
normal; alert on the rate, not the event. Rising counts here usually mean a
<code>zone_tick</code> doing too much, too many entities in one zone, or Lua memory that
is no longer being collected - see
<a href="/docs/performance#lua-memory">Performance tuning</a>.</p>
<h3 id="gameplay-systems" tabindex="-1">Gameplay systems</h3>
<pre><code>asobi.vote.started               asobi.vote.cast
asobi.vote.resolved              asobi.chat.message_sent
asobi.economy.transaction        asobi.store.purchase
asobi.anticheat.violation        asobi.error
</code></pre>
<p><code>asobi.error</code> is game-code failing rather than asobi failing - a Lua callback
raising, a spawn naming a template that does not exist, a zone that could not
be reached. Its <code>kind</code> is a fixed enum and safe as a label; its <code>details</code> are
not.</p>
<h3 id="auth-cache" tabindex="-1">Auth cache</h3>
<pre><code>asobi.auth_cache.hit             asobi.auth_cache.miss
asobi.auth_cache.sweep
</code></pre>
<p>Hit ratio is a useful health signal: a collapse means tokens are being
re-verified against the database on every request.</p>
<h2 id="opentelemetry" tabindex="-1">OpenTelemetry</h2>
<p><code>opentelemetry_asobi</code> attaches to the same events and exports spans, so a
deployment already running a collector needs no exporter of its own.</p>
<h2 id="next-steps" tabindex="-1">Next steps</h2>
<ul>
<li><a href="https://hexdocs.pm/asobi/console.html">Operator console</a> - live state and the ops API.</li>
<li><a href="/docs/clustering">Clustering</a> - which readings are per-node.</li>
<li><a href="/docs/performance">Performance tuning</a> - the knobs behind the numbers.</li>
</ul>
"""}
    ]}.

%% The guide source, served at this page's .md URL. asobi_site_markdown cannot
%% walk the {raw, ...} blob above, and does not need to: this is what that HTML
%% was rendered from.
-spec markdown() -> binary().
markdown() ->
    ~"""
# Observability

asobi emits `telemetry` events and structured JSON logs. It does not ship a
metrics endpoint, a dashboard or an alerting rule, and that is deliberate: a
game backend that grows its own time-series store is a maintenance liability
with a strictly better substitute one hop away. Wire the events to Prometheus,
point your log shipper at stdout, and let Grafana own the graphs.

The operator console at `/console` answers "what is this node doing right
now". Everything on this page answers "what has it been doing for six hours",
which is a different question with a different tool. See
[Operator console](https://hexdocs.pm/asobi/console.html) for the first one.

## What you get

- **40 telemetry events**, listed below. Stable names; the measurement and
  metadata keys are documented per-event in `m:asobi_telemetry`.
- **Structured JSON logs** on stdout, one object per line, via
  `nova_jsonlogger`. No configuration needed - a container log shipper reads
  them as-is.
- **`GET /health`** and **`GET /ready`** for liveness and readiness.

## What you do not get

- **No `/metrics` route.** asobi has no opinion about your scrape path,
  registry, or which events become counters versus histograms. Attaching an
  exporter is about fifteen lines, below.
- **No dashboards or alert rules** shipped in this repo yet.
- **No log aggregation.** The logs are structured; shipping them is your
  stack's job.

## Prometheus

Add `telemetry_metrics_prometheus` to your release and declare the metrics you
want. Nothing in asobi needs changing.

```erlang
{deps, [
    {telemetry_metrics_prometheus, "~> 1.1"}
]}.
```

```erlang
%% In your own application's start/2.
Metrics = [
    telemetry_metrics:counter(~"asobi.match.started.count", #{
        event_name => [asobi, match, started],
        measurement => count,
        tags => [mode]
    }),
    telemetry_metrics:distribution(~"asobi.match.finished.duration_ms", #{
        event_name => [asobi, match, finished],
        measurement => duration_ms,
        tags => [mode]
    }),
    telemetry_metrics:counter(~"asobi.ws.connected.count", #{
        event_name => [asobi, ws, connected],
        measurement => count
    })
],
{ok, _} = telemetry_metrics_prometheus:start_link(#{metrics => Metrics}).
```

### Choosing tags

A tag becomes a Prometheus label, and a label with unbounded cardinality will
take down your Prometheus rather than your game. `mode`, `reason` and `result`
are bounded and safe. **`player_id`, `match_id`, `world_id` and `zone_id` are
not** - they are one series per entity, forever. They are in the metadata
because a trace exporter and a log line want them; that is not the same as a
metric label wanting them.

[ADR 0005](https://github.com/widgrensit/asobi/blob/main/docs/adr/0005-telemetry-event-surface.md)
classifies the metadata keys it covers by label safety. It predates several of
the events below, so treat the list on this page as the current surface and the
ADR as the reasoning.

### In a cluster

Label every series with the node, or you cannot tell a fleet-wide change from
one node misbehaving. Most of these events are per-node by nature: the process
that emitted one lives somewhere specific.

```erlang
telemetry_metrics_prometheus:start_link(#{
    metrics => Metrics,
    default_tags => #{node => atom_to_binary(node(), utf8)}
})
```

## Logs

Every line is a JSON object on stdout. In Kubernetes, Promtail or Grafana Alloy
picks them up with no application configuration; under Compose, point your
shipper at the container's logs.

Fields worth building queries on:

| Field | What it is |
|-------|------------|
| `msg` | a stable event slug, e.g. `console_enabled`, `engine_bootstrap_failed` |
| `level` | `debug` through `error` |
| `mfa` | module, function and arity that logged it |
| `file`, `line` | where in the source |

Slugs are stable and worth alerting on. `engine_bootstrap_failed` and
`console_disabled_without_secret` both mean a deployment came up wrong, and
both are the kind of thing that is otherwise noticed a day later.

## The events

Fifty-two, grouped by what they are about. Measurement and metadata keys
are in `m:asobi_telemetry`, which is also the list `asobi_telemetry:events/0`
returns - attach to that rather than restating the names.

### Sessions and the socket

```
asobi.session.connected          asobi.session.disconnected
asobi.ws.connected               asobi.ws.disconnected
asobi.ws.message_in              asobi.ws.message_out
asobi.ws.connect_rate_limited    asobi.ws.idle_auth_timeout
asobi.ws.origin_rejected         asobi.ws.legacy_input_unwrap
asobi.dgram.bindings_expired     asobi.dgram.dropped
asobi.dgram.send_failed          asobi.dgram.recv_failed
asobi.dgram.input_undelivered    asobi.dgram.input_unknown
asobi.dgram.input_undecodable    asobi.dgram.canary_missed
asobi.dgram.link_up              asobi.dgram.link_closed
asobi.dgram.link_error           asobi.dgram.pose_saturated
```

The `asobi.dgram.*` events fire only on a node in the
[`dgram_gw` role](https://asobi.dev/docs/configuration#the-datagram-gateway-role).

`asobi.dgram.dropped` is the one to build a dashboard on, and `gate` is why it is
one event rather than seven. Nothing is ever sent back to a rejected datagram, so
this counter is the only evidence a rejection happened at all.

| `gate` rising | What it means |
| --- | --- |
| `parse` alone | Someone is pointing a scanner at the port. Uninteresting. |
| `parse` + `ingress_global` | A volumetric flood. The global tier is doing its job. |
| `unknown_conn` | Guessing at `conn_id`s, which is a 32-bit space. |
| `mac` | **Wake up.** Someone has a live `conn_id` and not the key. |
| `ingress` / `input` | One connection over its budget: a broken client, usually. |
| `binding` | Replays or a flapping path. Check `reason`. |

`asobi.dgram.canary_missed` carries `consecutive`, and that is the field to alert
on: one miss is a scheduler hiccup, two in a row means the receive loop is wedged
and the node stops reporting ready. It is the only signal that separates a wedged
loop from a quiet port, which look identical from outside. Note what it does not
cover: `SO_REUSEPORT` means the kernel chooses which shard receives the probe, so
a healthy canary proves **at least one** shard is alive, not all of them. A single
wedged shard shows up as a fraction of players timing out, and the place to catch
that is `asobi.dgram.recv_failed` plus client-side telemetry.

`asobi.dgram.pose_saturated` counts transform values that did not fit their
configured scale. Any sustained rate means the `scale` in
[`dgram_pose`](https://asobi.dev/docs/configuration#describing-your-transform-fields) is wrong for
this game's world size, and the fix is configuration rather than code.

`asobi.dgram.link_error` with `reason = bad_auth` is worth an alert. The engine
link is loopback-only, so a failed authentication is either a misconfigured
`dgram_link_secret` or something local that should not be talking to it.

`asobi.dgram.link_closed` on its own is not an outage: bindings already in the
table keep working, so players stay on the plane while the engine restarts. What
stops is new mints and revocations, and an undeliverable revocation is bounded by
the mint's own expiry.

`asobi.dgram.input_unknown` is expected in small numbers around a session ending,
because the two ends revoke asynchronously. Sustained, it means the gateway
believes in a binding the engine has forgotten.

`asobi.dgram.bindings_expired` fires once per sweep, counting datagram
credentials that were minted and never used. A rising count is
a client-side fault rather than an attack - minting costs an authenticated
WebSocket, so this is clients opening the plane and walking away, not anyone
getting something for free.

`asobi.ws.origin_rejected` and `asobi.ws.connect_rate_limited` are the two
worth alerting on: a spike in either is either an attack or a client
misconfiguration, and both are invisible in game metrics.

`asobi.ws.legacy_input_unwrap` counts input frames sent in the deprecated
sole-`data` shape (see [WebSocket protocol](https://asobi.dev/docs/protocols/websocket#worldinput)).
It is not an error, and not worth an alert: it exists so the carve-out can be
retired once the counter reaches zero for a release, instead of guessing which
clients still depend on it.

### Matches and matchmaking

```
asobi.match.started              asobi.match.finished
asobi.match.player_joined        asobi.match.player_left
asobi.matchmaker.queued          asobi.matchmaker.removed
asobi.matchmaker.deduped         asobi.matchmaker.formed
asobi.matchmaker.failed
```

Queue depth is the number worth watching, and in a cluster it is per-node -
each node's matchmaker holds its own tickets, so a fleet-wide total is a sum
across nodes, not a reading from one. See [Clustering](https://asobi.dev/docs/clustering).

**The alert worth having is `removed{reason=expired}` rising while `formed`
stays flat.** That pair says exactly one thing, with no interpretation needed:
players waited the full `max_wait_seconds` and got nothing. Removals carry
`reason` - `cancelled` when a client withdraws, `expired` when the ticket times
out - and only `expired` means the matchmaker failed to do its job.

`deduped` fires when a player asks to queue for a mode they already have an
open ticket on and gets that ticket back. (The client-facing field on the reply
is named `already_queued`; the metric keeps the mechanism's name.) Some of it
is routine: a double-tapped *find match*, and reconnect resubmits, which are
idempotent by design. It is a hint, not a diagnosis. A sustained rate is worth looking at -
one cause is several clients authenticated as the same player, which no amount
of waiting will fix because one player cannot fill a two-player match - but a
bored player re-tapping in an empty queue produces the same shape.

Note what this view **cannot** tell you. Distinguishing "one player re-tapping"
from "several clients sharing one identity" needs a distinct-player count, and
`player_id` is unbounded so an exporter must never make it a label (see
[ADR 0005](https://github.com/widgrensit/asobi/blob/main/docs/adr/0005-telemetry-event-surface.md)).
`queued` and `deduped` are counters of events, not a live-ticket count - queue
depth is the snapshot gauge described above. To separate those two cases you
need the node's queue snapshot or its logs, not Prometheus.

Handlers run **synchronously in the process that emitted the event**, so a
handler attached to a matchmaker event runs inside the matchmaker's own message
loop. Never call `asobi_matchmaker:get_queue_stats/0` from one - that is a
`gen_server:call` to the process currently executing your handler, so it
deadlocks until the call times out and stalls matchmaking for every player
meanwhile. Read `asobi_matchmaker:snapshot/0` instead: it reads ETS and never
messages the matchmaker.

### Worlds and zones

```
asobi.world.started              asobi.world.finished
asobi.world.player_joined        asobi.world.player_left
asobi.world.phase_changed        asobi.world.tick
asobi.zone.opened                asobi.zone.closed
asobi.zone.tick_skipped          asobi.join.rate_limited
asobi.rehome.rate_limited
```

`asobi.world.tick` is sampled rather than emitted every tick - at 20 Hz per
world an unsampled event is a metrics pipeline of its own.

`asobi.zone.tick_skipped` is the one to alert on. It counts zones the world
tick skipped because they had not finished the previous one, so a healthy
world never emits it at all and a sustained non-zero rate means a world that
can no longer keep up. A single event is a zone that ran long once, which is
normal; alert on the rate, not the event. Rising counts here usually mean a
`zone_tick` doing too much, too many entities in one zone, or Lua memory that
is no longer being collected - see
[Performance tuning](https://asobi.dev/docs/performance#lua-memory).

### Gameplay systems

```
asobi.vote.started               asobi.vote.cast
asobi.vote.resolved              asobi.chat.message_sent
asobi.economy.transaction        asobi.store.purchase
asobi.anticheat.violation        asobi.error
```

`asobi.error` is game-code failing rather than asobi failing - a Lua callback
raising, a spawn naming a template that does not exist, a zone that could not
be reached. Its `kind` is a fixed enum and safe as a label; its `details` are
not.

### Auth cache

```
asobi.auth_cache.hit             asobi.auth_cache.miss
asobi.auth_cache.sweep
```

Hit ratio is a useful health signal: a collapse means tokens are being
re-verified against the database on every request.

## OpenTelemetry

`opentelemetry_asobi` attaches to the same events and exports spans, so a
deployment already running a collector needs no exporter of its own.

## Next steps

- [Operator console](https://hexdocs.pm/asobi/console.html) - live state and the ops API.
- [Clustering](https://asobi.dev/docs/clustering) - which readings are per-node.
- [Performance tuning](https://asobi.dev/docs/performance) - the knobs behind the numbers.
""".
