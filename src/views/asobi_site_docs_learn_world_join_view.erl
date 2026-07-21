-module(asobi_site_docs_learn_world_join_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-learn-world-join", title => ~"Connect to a world - Asobi docs"},
            Bindings
        ),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Learn / Connect to a world"
            ]},
            {h1, [], [~"Connect to a world"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Join the world you created in the previous step and receive its initial snapshot."
            ]},

            {p, [], [
                ~"In ",
                {a, [{href, ~"/docs/learn/world-create"}, az_navigate], [~"step 10"]},
                ~" you created a world and confirmed it exists. A world is a persistent, zoned space; a match is an ephemeral session. Now a client enters it."
            ]},
            {p, [], [
                ~"The server stays authoritative. The client sends ",
                {code, [], [~"world.join"]},
                ~" as intent; the server decides placement, subscribes you to the 3x3 zone neighbourhood around your spawn, and pushes state. You never move your own dot; you ask, and the server broadcasts."
            ]},

            {h2, [], [~"The one thing that trips people up"]},
            {p, [], [
                ~"The ",
                {strong, [], [~"first"]},
                ~" ",
                {code, [], [~"world.tick"]},
                ~" you receive after ",
                {code, [], [~"world.joined"]},
                ~" is the initial full snapshot: every entity in your zone neighbourhood, each sent with op ",
                {code, [], [~"\"a\""]},
                ~" (added, full state). Every later tick carries only deltas."
            ]},
            {p, [], [
                ~"So register the ",
                {code, [], [~"world.tick"]},
                ~" handler ",
                {strong, [], [~"before"]},
                ~" you call join. If you join first and wire the handler afterwards, the snapshot has already gone and you are left reconstructing the world from deltas."
            ]},
            {p, [], [~"Order, in every SDK:"]},
            {ol, [], [
                {li, [], [
                    ~"Register the ",
                    {code, [], [~"world.tick"]},
                    ~" handler (this catches the snapshot)."
                ]},
                {li, [], [
                    ~"Register the ",
                    {code, [], [~"world.joined"]},
                    ~" handler (world metadata: id, mode, tick rate)."
                ]},
                {li, [], [~"Call join."]}
            ]},
            {p, [], [
                {code, [], [~"world.joined"]},
                ~" is the acknowledgement; the snapshot arrives as the first ",
                {code, [], [~"world.tick"]},
                ~". Two separate events, both needed."
            ]},

            {h2, [], [~"Cloud vs self-hosted"]},
            {p, [], [
                ~"Identical on both. The only difference is the base server URL you configured your client with back in ",
                {a, [{href, ~"/docs/learn/install-sdk"}, az_navigate], [~"step 2"]},
                ~":"
            ]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Cloud"]},
                    ~": the environment URL from console.asobi.dev, connecting to ",
                    {code, [], [~"/ws"]},
                    ~"."
                ]},
                {li, [], [
                    {strong, [], [~"Self-hosted"]},
                    ~": your own host on port 8084, e.g. ",
                    {code, [], [~"ws://your-host:8084/ws"]},
                    ~"."
                ]}
            ]},
            {p, [], [~"Every call below is byte-for-byte the same on both paths."]},

            {h2, [], [~"Per-SDK"]},
            {p, [], [
                ~"You are already connected (",
                {code, [], [~"session.connected"]},
                ~", ",
                {a, [{href, ~"/docs/learn/connect"}, az_navigate], [~"step 3"]},
                ~") and you have a ",
                {code, [], [~"world_id"]},
                ~" from the world you created. Wire the two handlers, then join. Register handlers on the same realtime object you connected with."
            ]},

            ?stateless(asobi_site_tabbed_code, render, #{
                id => ~"learn-world-join",
                tabs => [
                    #{
                        label => ~"Defold",
                        lang => ~"lua",
                        body =>
                            ~"""
-- rt = client.realtime. Callbacks via rt:on(mapped_name, fn); the wire world.tick maps to "world_tick".
rt:on("world_tick", function(frame)
	print("snapshot/delta, tick=" .. tostring(frame.tick))
end)

rt:on("world_joined", function(info)
	print("joined world " .. tostring(info.world_id))
end)

rt:join_world(world_id, function(ok, err)
	if not ok then print("join failed: " .. tostring(err)) end
end)
"""
                    },
                    #{
                        label => ~"Godot",
                        lang => ~"gdscript",
                        body =>
                            ~"""
# Asobi.realtime autoload. Signals use underscores; connect them before world_join.
Asobi.realtime.world_tick.connect(_on_world_tick)
Asobi.realtime.world_joined.connect(_on_world_joined)
Asobi.realtime.world_join(world_id)

func _on_world_tick(payload: Dictionary) -> void:
	print("tick ", payload.get("tick"))

func _on_world_joined(payload: Dictionary) -> void:
	print("joined ", payload.get("world_id"))
"""
                    },
                    #{
                        label => ~"Unity",
                        lang => ~"csharp",
                        body =>
                            ~"""
// Events on client.Realtime; handlers get the raw JSON envelope string, which you parse. WorldJoinAsync returns a Task<string> ack.
client.Realtime.OnWorldTick += rawJson => Debug.Log($"tick: {rawJson}");
client.Realtime.OnWorldJoined += rawJson => Debug.Log($"joined: {rawJson}");

string ack = await client.Realtime.WorldJoinAsync(worldId);
"""
                    },
                    #{
                        label => ~"Unreal",
                        lang => ~"cpp",
                        body =>
                            ~"""
// Dynamic multicast delegates on UAsobiWebSocket. Handlers must be UFUNCTIONs. OnWorldTick delivers the tick number and the updates as a JSON string; OnWorldJoined delivers a typed FAsobiWorldInfo.
WebSocket->OnWorldTick.AddDynamic(this, &UMyClass::HandleWorldTick);
WebSocket->OnWorldJoined.AddDynamic(this, &UMyClass::HandleWorldJoined);
WebSocket->WorldJoin(WorldId);

// UFUNCTION() void HandleWorldTick(int64 Tick, const FString& UpdatesJson);
// UFUNCTION() void HandleWorldJoined(const FAsobiWorldInfo& Info);
"""
                    },
                    #{
                        label => ~"Dart",
                        lang => ~"dart",
                        body =>
                            ~"""
// Broadcast streams on client.realtime. onWorldTick yields a typed WorldTick; onWorldJoined yields a Map. joinWorld returns a Future<Map>.
client.realtime.onWorldTick.stream.listen((WorldTick tick) {
  print('tick ${tick.tick}');
});

client.realtime.onWorldJoined.stream.listen((Map<String, dynamic> info) {
  print('joined ${info['world_id']}');
});

await client.realtime.joinWorld(worldId);
"""
                    },
                    #{
                        label => ~"JS",
                        lang => ~"typescript",
                        body =>
                            ~"""
// asobi.websocket(...) uses raw wire event names (dots). Join is an awaited RPC via send.
ws.on("world.tick", (payload) => console.log("tick", payload.tick));
ws.on("world.joined", (payload) => console.log("joined", payload.world_id));

const reply = await ws.send("world.join", { world_id });
"""
                    },
                    #{
                        label => ~"LÖVE",
                        lang => ~"lua",
                        body =>
                            ~"""
-- client.realtime with mapped callback names, one callback per event. LOVE needs a manual pump: call client.realtime:update() every frame from love.update, or no callbacks fire.
client.realtime:on("world_tick", function(frame)
	print("tick " .. tostring(frame.tick))
end)

client.realtime:on("world_joined", function(info)
	print("joined " .. tostring(info.world_id))
end)

client.realtime:join_world(world_id)

-- in love.update(dt):
--   client.realtime:update()
"""
                    }
                ]
            }),

            {h3, [], [~"No id yet?"]},
            {p, [], [
                ~"If you have not created a world explicitly, swap join for ",
                {code, [], [~"find_or_create"]},
                ~" (",
                {code, [], [~"find_or_create_world"]},
                ~" / ",
                {code, [], [~"world_find_or_create"]},
                ~" / ",
                {code, [], [~"WorldFindOrCreateAsync"]},
                ~" / ",
                {code, [], [~"WorldFindOrCreate"]},
                ~" / ",
                {code, [], [~"findOrCreateWorld"]},
                ~" / ",
                {code, [], [~"ws.send(\"world.find_or_create\", {mode})"]},
                ~"). It drops you into the first world with capacity, or makes one, and auto-joins. ",
                {code, [], [~"world.joined"]},
                ~" and the snapshot arrive exactly the same way."
            ]},
            {p, [], [
                ~"See the ",
                {a, [{href, ~"/docs/world-server"}, az_navigate], [~"world-server guide"]},
                ~" for zones, interest management, and terrain; the ",
                {a, [{href, ~"/docs/protocols/websocket"}, az_navigate], [
                    ~"websocket protocol reference"
                ]},
                ~" for the full ",
                {code, [], [~"world.*"]},
                ~" envelope shapes."
            ]},

            checkpoint([
                {p, [], [~"Run your client. In the log you should see, in order:"]},
                {ol, [], [
                    {li, [], [
                        {code, [], [~"world.joined"]},
                        ~" firing with your ",
                        {code, [], [~"world_id"]},
                        ~"."
                    ]},
                    {li, [], [
                        ~"A first ",
                        {code, [], [~"world.tick"]},
                        ~" whose updates list every entity in your zone, each with op ",
                        {code, [], [~"\"a\""]},
                        ~"."
                    ]}
                ]},
                {p, [], [
                    ~"That first tick is your initial snapshot. If you see ",
                    {code, [], [~"world.joined"]},
                    ~" but never a tick, check that the ",
                    {code, [], [~"world.tick"]},
                    ~" handler was registered before you called join (and, on LOVE, that ",
                    {code, [], [~":update()"]},
                    ~" is being pumped)."
                ]}
            ]),

            nextstep(
                ~"/docs/learn/world-run",
                ~"Step 12: Run a world",
                ~"Send world.input, and watch world.tick deltas (op a/u/r) move the dot for everyone in the zone."
            )
        ]}
    ).

checkpoint(Children) ->
    ?html(
        {'div', [{class, ~"docs-callout docs-callout-success"}], [
            {p, [], [{strong, [], [~"Checkpoint"]}]} | Children
        ]}
    ).

nextstep(Href, Label, Blurb) ->
    ?html(
        {'div', [{class, ~"docs-next"}], [
            {p, [], [
                {strong, [], [~"Next: "]},
                {a, [{href, Href}, az_navigate], [Label]}
            ]},
            {p, [], [Blurb]}
        ]}
    ).
