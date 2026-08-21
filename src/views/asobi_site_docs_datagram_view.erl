%% GENERATED from asobi guides/datagram-plane.md - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(asobi_site_docs_datagram_view).

-export([mount/1, render/1, markdown/0]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"docs-datagram", title => ~"Datagram plane — Asobi docs"}, Bindings), #{}}.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ~" / Protocols / Datagram plane"
        ]},
        {h1, [], [~"The datagram plane"]},
        {raw,
            ~"""
<p>Entity <strong>positions</strong> can travel over UDP instead of the WebSocket. One lost
packet then costs one frame of staleness rather than stalling everything behind
a TCP retransmit.</p>
<p>Optional, off by default, and <strong>self-hosting only</strong>. Everything below is safe to
switch on and safe to leave alone.</p>
<h2 id="what-problem-it-solves" tabindex="-1">What problem it solves</h2>
<p>Every frame today goes over one TLS WebSocket, which is TCP. TCP guarantees
order, so a single lost packet stalls everything behind it until it is
retransmitted, typically 100-200ms. For a chat message that is invisible. For
&quot;where is the player standing right now&quot; it is a rubber-band.</p>
<h2 id="what-it-carries-and-what-it-never-carries" tabindex="-1">What it carries, and what it never carries</h2>
<p>Downstream, exactly one thing: <code>pose</code>, the absolute transform state of entities.
<code>x, y, vx, vy</code> as <code>int16</code> against a scale you configure: twelve bytes an entity,
against about ninety-five for the same entity as JSON. Upstream, <code>world.input</code>,
the frame your client already sends when a player moves.</p>
<p>Measured on a forty-entity frame with real UUIDv7 ids: 3795 bytes as JSON on the
WebSocket, 1039 as the binary <code>world.tick</code> wire, <strong>512 as a pose datagram</strong>. That
last number is why four hundred entities fit inside a single 1200-byte datagram
where the same set as JSON is 37 KB.</p>
<p><strong>Never on this plane:</strong> authentication, inventory, economy, chat, match results,
and entity creation and removal. <code>world.tick</code> above all, which is an op-delta
against a baseline that advances on send, so one lost frame corrupts the client's
view permanently.</p>
<p>That selection is a written rule rather than taste: the plane carries only frames
the framework defines every byte of, and only frames that are self-contained per
record.</p>
<h2 id="why-losing-packets-is-fine-here" tabindex="-1">Why losing packets is fine here</h2>
<p>A pose is <strong>absolute</strong>: &quot;entity 5 is at (300, 480)&quot;. Miss one and the next one
50ms later supersedes it completely. Nothing accumulates and nothing goes wrong.</p>
<p>That is the whole reason the plane carries positions and nothing else.</p>
<p>Entities that stop moving stop being mentioned, which would leave a client that
missed the last update wrong forever. Axial refresh fixes that with no acks and
no per-client state: each tick additionally re-sends the slice of entities whose
slot falls in that tick, so nothing is stale for longer than one period.</p>
<h2 id="what-an-attacker-can-do" tabindex="-1">What an attacker can do</h2>
<p>The downlink carries no MAC and no encryption, stated plainly because it is a
real reduction: <em>the datagram plane provides off-path forgery resistance and no
confidentiality or on-path integrity.</em></p>
<p>An attacker needs the connection id <strong>and</strong> the path tag <strong>and</strong> the ability to
deliver to the victim's current network path. With all three they can make one
player's <em>render</em> of other entities wrong for at most one pose interval, after
which the next pose overwrites it. They cannot affect the server, any other
player, the simulation, entity creation or removal, or any non-transform field.</p>
<p>Everything with authority travels only on the TLS WebSocket, in every state.</p>
<h2 id="server-setup" tabindex="-1">Server setup</h2>
<p>Two containers, and two different images. The gateway binds a UDP port and
parses packets from anyone on the internet, so it must not run your game -
enforced by what is in the image rather than by a flag.
<code>ghcr.io/widgrensit/asobi_dgram</code> is a release of the gateway application alone:
no nova, no kura, no shigoto, no Lua, no HTTP listener, and no database driver to
open a pool with.</p>
<p>It used to be one image and a role, and that could not work: OTP starts an
application's dependencies before its start callback, so the pool was already
open by the time the role was read (asobi#513). Setting <code>ASOBI_ROLE=dgram_gw</code> on
the engine image still runs the gateway and still has that flaw. Build your own
with <code>docker build --target gateway</code>.</p>
<pre><code class="language-bash">openssl rand -hex 32 &gt; dgram_secret.txt
printf 'dgram_secret.txt\n' &gt;&gt; .gitignore
</code></pre>
<p>The two roles also need <strong>different Erlang cookies</strong>. They share a network
namespace, so they share a loopback and an EPMD, and a shared cookie means the
container parsing hostile UDP can <code>rpc:call</code> into the one holding your Lua
sandbox and your database credentials. The image ships a public default, so
setting both is not optional:</p>
<pre><code class="language-bash">echo &quot;ERLANG_COOKIE=$(openssl rand -hex 24)&quot;    # engine, in your .env
echo &quot;DGRAM_COOKIE=$(openssl rand -hex 24)&quot;     # gateway, in your .env
</code></pre>
<pre><code class="language-yaml">  asobi:
    image: ghcr.io/widgrensit/asobi:latest
    # ...your existing engine configuration, plus:
    environment:
      # Where to dial the gateway. This is the engine's opt-in: without it
      # nothing is dialled and clients are told the plane is unavailable.
      #
      # Loopback, not a compose service name. The gateway binds its link port on
      # 127.0.0.1 - it carries mint credentials with no transport security of its
      # own - so a gateway on its own compose network is unreachable no matter
      # what you point this at, and the plane degrades to WebSocket for everyone
      # (asobi#511). The two roles share one network namespace instead.
      ASOBI_DGRAM_GATEWAY: &quot;127.0.0.1:7778&quot;
      # What clients are told to send to - your public address, not the
      # container's. Delivered in the mint reply, which is why the plane needs
      # no DNS and no SNI and why a non-standard port costs nothing.
      ASOBI_DGRAM_ENDPOINT: &quot;udp.example.com:7777&quot;
      ASOBI_DGRAM_LINK_SECRET_FILE: /run/secrets/dgram
      ASOBI_DGRAM_POSE_FIELDS: &quot;x:100,y:100,vx:100,vy:100&quot;
      # The plane's precondition: only the binary `world.tick` binds a slot, and
      # no client is served it while this is off - so every pose would be
      # discarded client-side. asobi logs an error at boot and disables poses if
      # the manifest is configured without it.
      ASOBI_BINARY_WIRE: &quot;1&quot;
      ERLANG_COOKIE: ${ERLANG_COOKIE:?set ERLANG_COOKIE in .env}
    ports:
      # The gateway's UDP port, published here because it lives in this
      # container's network namespace.
      - &quot;7777:7777/udp&quot;
    volumes:
      - ./dgram_secret.txt:/run/secrets/dgram:ro

  dgram:
    # Not the engine image with a role set - see above.
    image: ghcr.io/widgrensit/asobi_dgram:latest
    # The engine's network namespace. On Kubernetes this is a second container in
    # the same pod, where it comes for free.
    network_mode: &quot;service:asobi&quot;
    depends_on:
      - asobi
    environment:
      # ASOBI_ROLE and the ports are baked into this image; set here only where
      # you want something other than the defaults.
      ASOBI_DGRAM_PORT: 7777
      ASOBI_DGRAM_LINK_PORT: 7778
      ASOBI_DGRAM_LINK_SECRET_FILE: /run/secrets/dgram
      ASOBI_DGRAM_POSE_FIELDS: &quot;x:100,y:100,vx:100,vy:100&quot;
      # A DIFFERENT cookie from the engine's. One namespace means one loopback,
      # and a shared cookie makes distribution a path from the process parsing
      # internet packets into the one running your game. The node name is already
      # distinct in this image, which the shared EPMD requires.
      ERLANG_COOKIE: ${DGRAM_COOKIE:?set DGRAM_COOKIE in .env}
    volumes:
      - ./dgram_secret.txt:/run/secrets/dgram:ro
    restart: unless-stopped
</code></pre>
<p><strong>The two roles share a network namespace.</strong> That is a <code>network_mode: &quot;service:asobi&quot;</code> sidecar in compose, and two containers in one pod on Kubernetes
(where they already do). The gateway keeps its own environment, its own
filesystem and its own process tree, which is where most of the split lives. What
it does not keep is a private loopback - which is exactly what makes the link
reachable, and also what puts both nodes on one EPMD. <strong>Give them different
<code>ERLANG_COOKIE</code>s</strong>, as below: a shared cookie lets the container parsing hostile
UDP <code>rpc:call</code> into the one running your Lua and holding your database
credentials, and the image default is public.</p>
<p>Open <strong>UDP</strong> 7777 on your firewall. Never publish the link port: it carries mint
credentials and has no transport security of its own, which is why it binds
loopback and why the namespace is shared rather than the port exposed.</p>
<p>The gateway image has no HTTP listener in it, so it does not compete for
<code>ASOBI_PORT</code> and there is no half-booted API answering requests from a node with
no auth subsystem behind it. Its logs are still one JSON object per line, from a
formatter small enough to live in a release with no nova in it.</p>
<p>The engine dials the gateway rather than the other way round, so the gateway
needs no knowledge of where the engine is. The link is deliberately <strong>not</strong>
distributed Erlang, which would have been the obvious answer: dist is
all-or-nothing, so a node that can reach another can call any function in it, and
handing that to the process parsing internet packets gives back most of what the
two-role split is for.</p>
<h3 id="describing-your-transform-fields" tabindex="-1">Describing your transform fields</h3>
<p><code>ASOBI_DGRAM_POSE_FIELDS</code> has no default and the plane stays off without it.
Guessing <code>x</code> and <code>y</code> at some scale would silently pick a precision for a world
that might be a thousand times larger.</p>
<pre><code>ASOBI_DGRAM_POSE_FIELDS: &quot;x:100,y:100,vx:100,vy:100&quot;
</code></pre>
<p>Name and scale, in canonical order. <strong>At most eight fields</strong> - the per-record
bitmask is one byte - and a ninth disables the plane rather than dropping a field
silently. The order is load-bearing: the wire carries no field names, so
reordering this changes what every field on the wire means.</p>
<p><code>scale</code> converts to the <code>int16</code> the wire carries. <code>100</code> gives two decimal places
and a range of about +/-327 world units. A bigger world needs a smaller scale and
coarser steps, which is a trade only your game can make. A value outside the
range <strong>saturates and is counted</strong>, never wraps: wrapping would teleport an
entity across the world, which reads as a game bug, where saturation reads as
what it is.</p>
<p><code>ASOBI_DGRAM_POSE_PERIOD</code> (default 20) is the axial refresh in ticks.</p>
<p>Full variable list in <a href="/docs/configuration#the-datagram-gateway">Configuration</a>.</p>
<h2 id="client-setup" tabindex="-1">Client setup</h2>
<p>Clients opt in per SDK. Nothing else about your game changes: entity callbacks
fire exactly as before and <code>world.tick</code> keeps carrying everything else.</p>
<h3 id="godot" tabindex="-1">Godot</h3>
<pre><code class="language-gdscript">Asobi.realtime.entities = AsobiEntities.new()
Asobi.realtime.request_datagram = true

Asobi.realtime.entities.entity_updated.connect(func(id, state, changed):
    if &quot;x&quot; in changed:
        move_sprite(id, state.x, state.y))

Asobi.realtime.connect_to_server()
</code></pre>
<p><code>AsobiEntities</code> is required, and that is not incidental. Two carriers describe
the same entity and they can disagree, so something has to hold the merge rule:
which <code>world.tick</code> field loses to a fresher position, which wins regardless, and
which frame may never create an entity at all. Putting that in a registry the SDK
owns is the difference between an API and a subtle correctness problem handed to
every game. It is useful on its own too - bind it without the plane and it folds
<code>world.tick</code> into a per-zone entity view with the crossing and keyframe rules
already handled.</p>
<h3 id="defold-and-love" tabindex="-1">Defold and LOVE</h3>
<pre><code class="language-lua">client.realtime.request_datagram = true
client.realtime:connect()
</code></pre>
<p>Both SDKs already keep an entity registry, so the merge happens where it always
did and your <code>entity_updated</code> handlers are unchanged.</p>
<h3 id="sdk-support" tabindex="-1">SDK support</h3>
<table>
<thead>
<tr>
<th>SDK</th>
<th>Binary <code>world.tick</code></th>
<th>Datagram plane</th>
</tr>
</thead>
<tbody>
<tr>
<td>Godot</td>
<td>yes</td>
<td>yes</td>
</tr>
<tr>
<td>Defold</td>
<td>yes</td>
<td>yes</td>
</tr>
<tr>
<td>LOVE</td>
<td>yes</td>
<td>yes</td>
</tr>
<tr>
<td>Dart</td>
<td>yes</td>
<td>not yet</td>
</tr>
<tr>
<td>Unity</td>
<td>yes</td>
<td>not yet</td>
</tr>
<tr>
<td>Unreal</td>
<td>yes</td>
<td>not yet</td>
</tr>
<tr>
<td>JS</td>
<td>n/a</td>
<td>never</td>
</tr>
</tbody>
</table>
<p>The JS SDK has no world-mode WebSocket surface, and browsers have no raw UDP in
any case, so a web export is permanently on the WebSocket. That is an asymmetry
rather than a wound: see below.</p>
<h2 id="when-it-does-not-work-nothing-breaks" tabindex="-1">When it does not work, nothing breaks</h2>
<p>This is the design's whole safety property, and the reason it is safe to switch
on before you have tested every player's network.</p>
<table>
<thead>
<tr>
<th>Situation</th>
<th>What happens</th>
</tr>
</thead>
<tbody>
<tr>
<td>Server has no gateway</td>
<td>The mint answers <code>datagram_unavailable</code>. The client stays on the WebSocket.</td>
</tr>
<tr>
<td>The client did not ask for the binary wire</td>
<td>It mints, and its <strong>input</strong> still travels over UDP. It is not sent poses, because it has no slot table to resolve them against - positions keep coming on <code>world.tick</code>. See below.</td>
</tr>
<tr>
<td>A firewall drops UDP</td>
<td>Three probes over three seconds, then the client gives up to <code>off</code>.</td>
</tr>
<tr>
<td>The path goes quiet for 2s</td>
<td><code>degraded</code>: positions come from <code>world.tick</code> again while the client re-probes in the background.</td>
</tr>
<tr>
<td>The WebSocket reconnects</td>
<td>Back to <code>off</code>, and a fresh mint. A credential is bound to a session.</td>
</tr>
<tr>
<td>A web export</td>
<td>Never opens the plane at all.</td>
</tr>
</tbody>
</table>
<p><strong>The WebSocket carries everything in every state.</strong> There is no state in which
correctness depends on this plane.</p>
<h3 id="if-it-never-leaves-probing" tabindex="-1">If it never leaves probing</h3>
<p>A blocked firewall and a reply that never arrives look identical from the client,
and both end as three probes and a fall back to the WebSocket. Server-side
telemetry cannot tell them apart either: nothing is dropped, so
<code>asobi.dgram.dropped</code> stays at zero in both cases.</p>
<p>Capture on the gateway and compare the ports:</p>
<pre><code>tcpdump -ni any udp port 7777
</code></pre>
<p>Every reply must leave from the port the client sent to. A reply from any other
source port is dropped by NAT on the way back, and filtered by SDKs that
<code>connect()</code> their socket even when it does arrive. Gateways up to and including
v0.92.3 sent from an ephemeral port and hit exactly this; upgrade rather than
reconfigure.</p>
<h3 id="poses-need-the-binary-wire-input-does-not" tabindex="-1">Poses need the binary wire; input does not</h3>
<p>A pose record carries a slot and nothing else, and the only frame that binds a
slot to an entity is an <code>add</code> on the <a href="/docs/protocols/websocket#binary-world-tick">binary
<code>world.tick</code></a>. So a client that connected
without <code>&quot;wire&quot;: &quot;binary&quot;</code> cannot resolve a pose, and the server does not send it
any - it would be dropped client-side and the entity would look frozen with
nothing in either log to say why.</p>
<p>The plane's other half is unaffected: <code>world.input</code> travelling upstream over UDP
resolves a player by <code>conn_id</code>, needs no slots, and works on either wire. So
minting is allowed either way, and a client that wants only the latency win on
its own input can have it.</p>
<p>Every SDK that supports the plane asks for both, so this is not something you
configure - it matters if you are writing a client by hand, or debugging why a
plane that reports <code>on</code> never moves anything.</p>
<p>The client keepalive is not optional and cannot be moved to the server: with a
NAT anywhere in the path a quiet client loses its mapping and the downlink is
blackholed with no signal at all, and only a client-originated packet recreates
it.</p>
<h2 id="checking-it-works" tabindex="-1">Checking it works</h2>
<pre><code>asobi.dgram.link_up          the engine attached to the gateway
asobi.dgram.canary_missed    consecutive &gt;= 2 means the receive loop is wedged
asobi.dgram.dropped          gate=mac is the one to wake up for
asobi.dgram.pose_saturated   your scale is wrong for your world size
</code></pre>
<p>Two log lines say the plane is not working, and both name the cause:</p>
<ul>
<li><code>dgram link unreachable, datagram plane is down</code> - the engine cannot reach the
gateway. Almost always the topology: the link port binds loopback, so the two
roles have to share a network namespace. Every client is answered
<code>datagram_unavailable</code> until this clears.</li>
<li><code>binary world.tick frame refused, falling back to text</code> - a zone's entities do
not fit the binary wire, so the entities that frame introduced get no poses.
The line carries the zone, the distinct field-name count (the cap is 32) and
the widest entity, and it is throttled to one per zone per minute with the
suppressed count attached.</li>
</ul>
<p>The gateway proves itself by sending itself a real datagram every five seconds
and waiting for the reply, so a wedged receive loop fails readiness where a
port-bound check would not. It does <strong>not</strong> prove every shard: the kernel chooses
which one receives the probe, so a healthy canary means at least one is alive. A
single wedged shard shows up as a fraction of players timing out, and
<code>asobi.dgram.recv_failed</code> plus client-side telemetry is where to catch that.</p>
<p>Full event list in <a href="https://hexdocs.pm/asobi/observability.html">Observability</a>.</p>
<h2 id="the-managed-cloud-does-not-have-this" tabindex="-1">The managed cloud does not have this</h2>
<p><a href="https://hexdocs.pm/asobi/cloud.html">asobi cloud</a> is WebSocket-only and will stay that way until its
network topology changes: Hetzner load balancers forward tcp/http/https only, and
the ingress masquerades the client address, so a datagram plane cannot be exposed
there at all.</p>
<p>Self-host and cloud diverge on transport for the first time. Stated here rather
than left for a reader to discover.</p>
<h2 id="further-reading" tabindex="-1">Further reading</h2>
<ul>
<li><a href="/docs/configuration#the-datagram-gateway">Configuration</a> - every variable.</li>
<li><a href="https://hexdocs.pm/asobi/self-hosting.html#adding-the-datagram-plane">Self-hosting</a> - the compose file in
context.</li>
<li><a href="/docs/protocols/websocket#binary-world-tick">WebSocket protocol</a> - the binary
<code>world.tick</code> encoding, which the plane depends on for its slot bindings.</li>
<li>ADR 0012 and ADR 0013 in <code>docs/adr/</code> - the protocol design, why it was
rejected, and why it was reopened.</li>
</ul>
"""}
    ]}.

%% The guide source, served at this page's .md URL. asobi_site_markdown cannot
%% walk the {raw, ...} blob above, and does not need to: this is what that HTML
%% was rendered from.
-spec markdown() -> binary().
markdown() ->
    ~"""
# The datagram plane

Entity **positions** can travel over UDP instead of the WebSocket. One lost
packet then costs one frame of staleness rather than stalling everything behind
a TCP retransmit.

Optional, off by default, and **self-hosting only**. Everything below is safe to
switch on and safe to leave alone.

## What problem it solves

Every frame today goes over one TLS WebSocket, which is TCP. TCP guarantees
order, so a single lost packet stalls everything behind it until it is
retransmitted, typically 100-200ms. For a chat message that is invisible. For
"where is the player standing right now" it is a rubber-band.

## What it carries, and what it never carries

Downstream, exactly one thing: `pose`, the absolute transform state of entities.
`x, y, vx, vy` as `int16` against a scale you configure: twelve bytes an entity,
against about ninety-five for the same entity as JSON. Upstream, `world.input`,
the frame your client already sends when a player moves.

Measured on a forty-entity frame with real UUIDv7 ids: 3795 bytes as JSON on the
WebSocket, 1039 as the binary `world.tick` wire, **512 as a pose datagram**. That
last number is why four hundred entities fit inside a single 1200-byte datagram
where the same set as JSON is 37 KB.

**Never on this plane:** authentication, inventory, economy, chat, match results,
and entity creation and removal. `world.tick` above all, which is an op-delta
against a baseline that advances on send, so one lost frame corrupts the client's
view permanently.

That selection is a written rule rather than taste: the plane carries only frames
the framework defines every byte of, and only frames that are self-contained per
record.

## Why losing packets is fine here

A pose is **absolute**: "entity 5 is at (300, 480)". Miss one and the next one
50ms later supersedes it completely. Nothing accumulates and nothing goes wrong.

That is the whole reason the plane carries positions and nothing else.

Entities that stop moving stop being mentioned, which would leave a client that
missed the last update wrong forever. Axial refresh fixes that with no acks and
no per-client state: each tick additionally re-sends the slice of entities whose
slot falls in that tick, so nothing is stale for longer than one period.

## What an attacker can do

The downlink carries no MAC and no encryption, stated plainly because it is a
real reduction: *the datagram plane provides off-path forgery resistance and no
confidentiality or on-path integrity.*

An attacker needs the connection id **and** the path tag **and** the ability to
deliver to the victim's current network path. With all three they can make one
player's *render* of other entities wrong for at most one pose interval, after
which the next pose overwrites it. They cannot affect the server, any other
player, the simulation, entity creation or removal, or any non-transform field.

Everything with authority travels only on the TLS WebSocket, in every state.

## Server setup

Two containers, and two different images. The gateway binds a UDP port and
parses packets from anyone on the internet, so it must not run your game -
enforced by what is in the image rather than by a flag.
`ghcr.io/widgrensit/asobi_dgram` is a release of the gateway application alone:
no nova, no kura, no shigoto, no Lua, no HTTP listener, and no database driver to
open a pool with.

It used to be one image and a role, and that could not work: OTP starts an
application's dependencies before its start callback, so the pool was already
open by the time the role was read (asobi#513). Setting `ASOBI_ROLE=dgram_gw` on
the engine image still runs the gateway and still has that flaw. Build your own
with `docker build --target gateway`.

```bash
openssl rand -hex 32 > dgram_secret.txt
printf 'dgram_secret.txt\n' >> .gitignore
```

The two roles also need **different Erlang cookies**. They share a network
namespace, so they share a loopback and an EPMD, and a shared cookie means the
container parsing hostile UDP can `rpc:call` into the one holding your Lua
sandbox and your database credentials. The image ships a public default, so
setting both is not optional:

```bash
echo "ERLANG_COOKIE=$(openssl rand -hex 24)"    # engine, in your .env
echo "DGRAM_COOKIE=$(openssl rand -hex 24)"     # gateway, in your .env
```

```yaml
  asobi:
    image: ghcr.io/widgrensit/asobi:latest
    # ...your existing engine configuration, plus:
    environment:
      # Where to dial the gateway. This is the engine's opt-in: without it
      # nothing is dialled and clients are told the plane is unavailable.
      #
      # Loopback, not a compose service name. The gateway binds its link port on
      # 127.0.0.1 - it carries mint credentials with no transport security of its
      # own - so a gateway on its own compose network is unreachable no matter
      # what you point this at, and the plane degrades to WebSocket for everyone
      # (asobi#511). The two roles share one network namespace instead.
      ASOBI_DGRAM_GATEWAY: "127.0.0.1:7778"
      # What clients are told to send to - your public address, not the
      # container's. Delivered in the mint reply, which is why the plane needs
      # no DNS and no SNI and why a non-standard port costs nothing.
      ASOBI_DGRAM_ENDPOINT: "udp.example.com:7777"
      ASOBI_DGRAM_LINK_SECRET_FILE: /run/secrets/dgram
      ASOBI_DGRAM_POSE_FIELDS: "x:100,y:100,vx:100,vy:100"
      # The plane's precondition: only the binary `world.tick` binds a slot, and
      # no client is served it while this is off - so every pose would be
      # discarded client-side. asobi logs an error at boot and disables poses if
      # the manifest is configured without it.
      ASOBI_BINARY_WIRE: "1"
      ERLANG_COOKIE: ${ERLANG_COOKIE:?set ERLANG_COOKIE in .env}
    ports:
      # The gateway's UDP port, published here because it lives in this
      # container's network namespace.
      - "7777:7777/udp"
    volumes:
      - ./dgram_secret.txt:/run/secrets/dgram:ro

  dgram:
    # Not the engine image with a role set - see above.
    image: ghcr.io/widgrensit/asobi_dgram:latest
    # The engine's network namespace. On Kubernetes this is a second container in
    # the same pod, where it comes for free.
    network_mode: "service:asobi"
    depends_on:
      - asobi
    environment:
      # ASOBI_ROLE and the ports are baked into this image; set here only where
      # you want something other than the defaults.
      ASOBI_DGRAM_PORT: 7777
      ASOBI_DGRAM_LINK_PORT: 7778
      ASOBI_DGRAM_LINK_SECRET_FILE: /run/secrets/dgram
      ASOBI_DGRAM_POSE_FIELDS: "x:100,y:100,vx:100,vy:100"
      # A DIFFERENT cookie from the engine's. One namespace means one loopback,
      # and a shared cookie makes distribution a path from the process parsing
      # internet packets into the one running your game. The node name is already
      # distinct in this image, which the shared EPMD requires.
      ERLANG_COOKIE: ${DGRAM_COOKIE:?set DGRAM_COOKIE in .env}
    volumes:
      - ./dgram_secret.txt:/run/secrets/dgram:ro
    restart: unless-stopped
```

**The two roles share a network namespace.** That is a `network_mode:
"service:asobi"` sidecar in compose, and two containers in one pod on Kubernetes
(where they already do). The gateway keeps its own environment, its own
filesystem and its own process tree, which is where most of the split lives. What
it does not keep is a private loopback - which is exactly what makes the link
reachable, and also what puts both nodes on one EPMD. **Give them different
`ERLANG_COOKIE`s**, as below: a shared cookie lets the container parsing hostile
UDP `rpc:call` into the one running your Lua and holding your database
credentials, and the image default is public.

Open **UDP** 7777 on your firewall. Never publish the link port: it carries mint
credentials and has no transport security of its own, which is why it binds
loopback and why the namespace is shared rather than the port exposed.

The gateway image has no HTTP listener in it, so it does not compete for
`ASOBI_PORT` and there is no half-booted API answering requests from a node with
no auth subsystem behind it. Its logs are still one JSON object per line, from a
formatter small enough to live in a release with no nova in it.

The engine dials the gateway rather than the other way round, so the gateway
needs no knowledge of where the engine is. The link is deliberately **not**
distributed Erlang, which would have been the obvious answer: dist is
all-or-nothing, so a node that can reach another can call any function in it, and
handing that to the process parsing internet packets gives back most of what the
two-role split is for.

### Describing your transform fields

`ASOBI_DGRAM_POSE_FIELDS` has no default and the plane stays off without it.
Guessing `x` and `y` at some scale would silently pick a precision for a world
that might be a thousand times larger.

```
ASOBI_DGRAM_POSE_FIELDS: "x:100,y:100,vx:100,vy:100"
```

Name and scale, in canonical order. **At most eight fields** - the per-record
bitmask is one byte - and a ninth disables the plane rather than dropping a field
silently. The order is load-bearing: the wire carries no field names, so
reordering this changes what every field on the wire means.

`scale` converts to the `int16` the wire carries. `100` gives two decimal places
and a range of about +/-327 world units. A bigger world needs a smaller scale and
coarser steps, which is a trade only your game can make. A value outside the
range **saturates and is counted**, never wraps: wrapping would teleport an
entity across the world, which reads as a game bug, where saturation reads as
what it is.

`ASOBI_DGRAM_POSE_PERIOD` (default 20) is the axial refresh in ticks.

Full variable list in [Configuration](https://asobi.dev/docs/configuration#the-datagram-gateway).

## Client setup

Clients opt in per SDK. Nothing else about your game changes: entity callbacks
fire exactly as before and `world.tick` keeps carrying everything else.

### Godot

```gdscript
Asobi.realtime.entities = AsobiEntities.new()
Asobi.realtime.request_datagram = true

Asobi.realtime.entities.entity_updated.connect(func(id, state, changed):
    if "x" in changed:
        move_sprite(id, state.x, state.y))

Asobi.realtime.connect_to_server()
```

`AsobiEntities` is required, and that is not incidental. Two carriers describe
the same entity and they can disagree, so something has to hold the merge rule:
which `world.tick` field loses to a fresher position, which wins regardless, and
which frame may never create an entity at all. Putting that in a registry the SDK
owns is the difference between an API and a subtle correctness problem handed to
every game. It is useful on its own too - bind it without the plane and it folds
`world.tick` into a per-zone entity view with the crossing and keyframe rules
already handled.

### Defold and LOVE

```lua
client.realtime.request_datagram = true
client.realtime:connect()
```

Both SDKs already keep an entity registry, so the merge happens where it always
did and your `entity_updated` handlers are unchanged.

### SDK support

| SDK | Binary `world.tick` | Datagram plane |
|---|---|---|
| Godot | yes | yes |
| Defold | yes | yes |
| LOVE | yes | yes |
| Dart | yes | not yet |
| Unity | yes | not yet |
| Unreal | yes | not yet |
| JS | n/a | never |

The JS SDK has no world-mode WebSocket surface, and browsers have no raw UDP in
any case, so a web export is permanently on the WebSocket. That is an asymmetry
rather than a wound: see below.

## When it does not work, nothing breaks

This is the design's whole safety property, and the reason it is safe to switch
on before you have tested every player's network.

| Situation | What happens |
|---|---|
| Server has no gateway | The mint answers `datagram_unavailable`. The client stays on the WebSocket. |
| The client did not ask for the binary wire | It mints, and its **input** still travels over UDP. It is not sent poses, because it has no slot table to resolve them against - positions keep coming on `world.tick`. See below. |
| A firewall drops UDP | Three probes over three seconds, then the client gives up to `off`. |
| The path goes quiet for 2s | `degraded`: positions come from `world.tick` again while the client re-probes in the background. |
| The WebSocket reconnects | Back to `off`, and a fresh mint. A credential is bound to a session. |
| A web export | Never opens the plane at all. |

**The WebSocket carries everything in every state.** There is no state in which
correctness depends on this plane.

### If it never leaves probing

A blocked firewall and a reply that never arrives look identical from the client,
and both end as three probes and a fall back to the WebSocket. Server-side
telemetry cannot tell them apart either: nothing is dropped, so
`asobi.dgram.dropped` stays at zero in both cases.

Capture on the gateway and compare the ports:

```
tcpdump -ni any udp port 7777
```

Every reply must leave from the port the client sent to. A reply from any other
source port is dropped by NAT on the way back, and filtered by SDKs that
`connect()` their socket even when it does arrive. Gateways up to and including
v0.92.3 sent from an ephemeral port and hit exactly this; upgrade rather than
reconfigure.

### Poses need the binary wire; input does not

A pose record carries a slot and nothing else, and the only frame that binds a
slot to an entity is an `add` on the [binary
`world.tick`](https://asobi.dev/docs/protocols/websocket#binary-world-tick). So a client that connected
without `"wire": "binary"` cannot resolve a pose, and the server does not send it
any - it would be dropped client-side and the entity would look frozen with
nothing in either log to say why.

The plane's other half is unaffected: `world.input` travelling upstream over UDP
resolves a player by `conn_id`, needs no slots, and works on either wire. So
minting is allowed either way, and a client that wants only the latency win on
its own input can have it.

Every SDK that supports the plane asks for both, so this is not something you
configure - it matters if you are writing a client by hand, or debugging why a
plane that reports `on` never moves anything.

The client keepalive is not optional and cannot be moved to the server: with a
NAT anywhere in the path a quiet client loses its mapping and the downlink is
blackholed with no signal at all, and only a client-originated packet recreates
it.

## Checking it works

```
asobi.dgram.link_up          the engine attached to the gateway
asobi.dgram.canary_missed    consecutive >= 2 means the receive loop is wedged
asobi.dgram.dropped          gate=mac is the one to wake up for
asobi.dgram.pose_saturated   your scale is wrong for your world size
```

Two log lines say the plane is not working, and both name the cause:

- `dgram link unreachable, datagram plane is down` - the engine cannot reach the
  gateway. Almost always the topology: the link port binds loopback, so the two
  roles have to share a network namespace. Every client is answered
  `datagram_unavailable` until this clears.
- `binary world.tick frame refused, falling back to text` - a zone's entities do
  not fit the binary wire, so the entities that frame introduced get no poses.
  The line carries the zone, the distinct field-name count (the cap is 32) and
  the widest entity, and it is throttled to one per zone per minute with the
  suppressed count attached.

The gateway proves itself by sending itself a real datagram every five seconds
and waiting for the reply, so a wedged receive loop fails readiness where a
port-bound check would not. It does **not** prove every shard: the kernel chooses
which one receives the probe, so a healthy canary means at least one is alive. A
single wedged shard shows up as a fraction of players timing out, and
`asobi.dgram.recv_failed` plus client-side telemetry is where to catch that.

Full event list in [Observability](https://hexdocs.pm/asobi/observability.html).

## The managed cloud does not have this

[asobi cloud](https://hexdocs.pm/asobi/cloud.html) is WebSocket-only and will stay that way until its
network topology changes: Hetzner load balancers forward tcp/http/https only, and
the ingress masquerades the client address, so a datagram plane cannot be exposed
there at all.

Self-host and cloud diverge on transport for the first time. Stated here rather
than left for a reader to discover.

## Further reading

- [Configuration](https://asobi.dev/docs/configuration#the-datagram-gateway) - every variable.
- [Self-hosting](https://hexdocs.pm/asobi/self-hosting.html#adding-the-datagram-plane) - the compose file in
  context.
- [WebSocket protocol](https://asobi.dev/docs/protocols/websocket#binary-world-tick) - the binary
  `world.tick` encoding, which the plane depends on for its slot bindings.
- ADR 0012 and ADR 0013 in `docs/adr/` - the protocol design, why it was
  rejected, and why it was reopened.
""".
