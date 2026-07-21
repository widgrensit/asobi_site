-module(asobi_site_docs_learn_identity_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{
                id => ~"docs-learn-identity",
                title => ~"Who is the player: guest vs account - Asobi docs"
            },
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
                ~" / Learn / Who is the player: guest vs account"
            ]},
            {h1, [], [~"Who is the player: guest vs account"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Give the player an identity without a sign-up form, and confirm the same identity survives a restart."
            ]},

            {p, [], [
                ~"In ",
                {a, [{href, ~"/docs/learn/connect"}, az_navigate], [~"step 3"]},
                ~" you connected and read back a ",
                {code, [], [~"player_id"]},
                ~". That id came from a token. This step is about where the token comes from, and the cheapest way to get one."
            ]},

            {h2, [], [~"You do not have to register"]},
            {p, [], [
                ~"A player does not need a username and password to start. Guest auth mints a real ",
                {code, [], [~"player_id"]},
                ~" on first launch from a device-held secret, with no credentials and no form. The same device resumes the same player on every later launch."
            ]},
            {p, [], [
                ~"The client owns one secret. On first run it generates a ",
                {code, [], [~"device_secret"]},
                ~" (at least 32 bytes from a cryptographic RNG, base64-encoded) plus a stable ",
                {code, [], [~"device_id"]},
                ~", and stores both in secure device storage. It posts them to ",
                {code, [], [~"POST /api/v1/auth/guest"]},
                ~"; the server stores only a salted, peppered HMAC of the secret, never the secret itself, and returns a token pair. Later launches post the same pair and resume the same player (create-or-resume). Treat ",
                {code, [], [~"device_secret"]},
                ~" like a password: generate it once, keep it on the device, never log or transmit it elsewhere."
            ]},
            {p, [], [
                ~"This is still server-authoritative. The client presents intent (a device secret); the server decides identity and hands back the token that every other call is bound to."
            ]},

            {h2, [], [~"When to upgrade to a full account"]},
            {p, [], [
                ~"A guest is only as safe as the secret on that one device. Lose the device, lose the account. Upgrade when the player has something worth protecting or wants it on more than one device:"
            ]},
            {ul, [], [
                {li, [], [~"The player wants to keep progress across a reinstall or a new device."]},
                {li, [], [
                    ~"You want a recoverable login (username and password, or a linked provider)."
                ]},
                {li, [], [
                    ~"The stakes rise: purchases, competitive standing, anything you would not want lost with a wiped phone."
                ]}
            ]},
            {p, [], [
                {code, [], [~"POST /api/v1/auth/guest/upgrade"]},
                ~" (authenticated with the guest's own token) claims the guest with a username and password. The ",
                {code, [], [~"player_id"]},
                ~", progress, wallets, and inventory are all preserved; the device secret is revoked. Only an unclaimed guest may upgrade. Every SDK below exposes this as ",
                {code, [], [~"upgrade_guest"]},
                ~" / ",
                {code, [], [~"upgradeGuest"]},
                ~" / ",
                {code, [], [~"UpgradeGuest"]},
                ~"."
            ]},
            {p, [], [
                ~"See the ",
                {a, [{href, ~"/docs/authentication"}, az_navigate], [~"Authentication guide"]},
                ~" for the full flow, error table, and abuse controls. The design rationale is ",
                {strong, [], [~"ADR 0002"]},
                ~" (registration is open, not required) and ",
                {strong, [], [~"ADR 0004"]},
                ~" (the game declares guest auth, the operator peppers it)."
            ]},

            {h2, [], [~"Enabling guest auth (server, Lua-first)"]},
            {p, [], [
                ~"Guest auth is opt-in and fails closed. Endpoints return ",
                {code, [], [~"403 guest_auth_disabled"]},
                ~" until two independent parties agree: the game declares the toggle, and the operator supplies a pepper. Either half alone leaves it off."
            ]},
            {p, [], [
                ~"The game half is one Lua global. Put it in ",
                {code, [], [~"match.lua"]},
                ~" for a single-mode game, or in ",
                {code, [], [~"config.lua"]},
                ~" for a multi-mode game (deployment-wide globals live in the manifest, not the per-mode scripts):"
            ]},
            code(
                ~"lua",
                ~"""
guest_auth = true
"""
            ),
            {p, [], [
                ~"The operator half differs by deployment. This is the only place the two paths diverge."
            ]},
            {p, [], [
                {strong, [], [~"Cloud."]},
                ~" Declare ",
                {code, [], [~"guest_auth = true"]},
                ~" and nothing else. Each environment is provisioned with a stable per-environment pepper automatically, so the same bundle is off in dev (no pepper yet) and on in prod. You never handle the secret."
            ]},
            {p, [], [
                {strong, [], [~"Self-hosted."]},
                ~" You own both halves. Declare ",
                {code, [], [~"guest_auth = true"]},
                ~" in Lua, and supply the pepper yourself. There is no ",
                {code, [], [~"ASOBI_GUEST_AUTH"]},
                ~" env var; the pepper is the switch. Provide it via the env var on the ",
                {code, [], [~"asobi_lua"]},
                ~" image:"
            ]},
            code(
                ~"bash",
                ~"""
ASOBI_GUEST_VERIFIER_PEPPER=<at-least-32-random-bytes>
"""
            ),
            {p, [], [
                ~"Or, when you build a release from source, via ",
                {code, [], [~"sys.config"]},
                ~" (a key-id to pepper map, so you can rotate while old guests still resume):"
            ]},
            code(
                ~"erlang",
                ~"""
{asobi, [
    {guest_verifier_pepper, #{<<"v1">> => <<"a-32-byte-or-longer-secret......">>}},
    {guest_verifier_key_id, <<"v1">>}
]}
"""
            ),
            {p, [], [
                ~"Keep the pepper in a secret manager, never in the bundle. See ",
                {a, [{href, ~"/docs/configuration"}, az_navigate], [~"Configuration"]},
                ~" for the optional abuse and retention controls (",
                {code, [], [~"guest_unlinked_cap"]},
                ~", ",
                {code, [], [~"guest_reap_after"]},
                ~")."
            ]},

            {h2, [], [~"Signing in as a guest (client)"]},
            {p, [], [
                ~"One call per SDK, below. The signature is identical on cloud and self-hosted; only the base server URL you built the client with differs (",
                {code, [], [~"http://localhost:8084"]},
                ~" self-hosted, your environment URL on cloud). In every case you generate and persist ",
                {code, [], [~"device_id"]},
                ~" and ",
                {code, [], [~"device_secret"]},
                ~" yourself once, then pass the same pair on every launch. The response carries ",
                {code, [], [~"created: true"]},
                ~" on the first call and omits it on a resume; the ",
                {code, [], [~"player_id"]},
                ~" is the same both times."
            ]},
            ?stateless(asobi_site_tabbed_code, render, #{
                id => ~"learn-identity",
                tabs => [
                    #{
                        label => ~"Defold",
                        lang => ~"lua",
                        body =>
                            ~"""
-- Auth is callback-style.
local asobi = require("asobi.client")
local client = asobi.create("localhost", 8084)

client.auth.guest(client, device_id, device_secret, function(data, err)
    if err then print("guest sign-in failed: " .. tostring(err.error)) return end
    print("guest " .. tostring(data.player_id) .. " created=" .. tostring(data.created))
end)

-- Upgrade later with client.auth.upgrade_guest(client, "chosen_name", "pass1234", cb)
"""
                    },
                    #{
                        label => ~"Godot",
                        lang => ~"gdscript",
                        body =>
                            ~"""
# Auth is await-style on the Asobi autoload.
Asobi.host = "localhost"
Asobi.port = 8084

var resp := await Asobi.auth.guest(device_id, device_secret)
if resp.has("error"):
    push_error("guest sign-in failed: %s" % resp.error)
else:
    print("guest %s created=%s" % [resp.player_id, resp.get("created", false)])

# Generate the secret once, e.g. Marshalls.raw_to_base64(bytes), and persist it.
# Upgrade with await Asobi.auth.upgrade_guest("player1", "secret123")
"""
                    },
                    #{
                        label => ~"Unity",
                        lang => ~"csharp",
                        body =>
                            ~"""
// Async Task on client.Auth.
var client = new AsobiClient("localhost", port: 8084);

var resp = await client.Auth.GuestAsync(deviceId, deviceSecret);
Debug.Log($"guest {resp.player_id} created={resp.created}");

// Upgrade with await client.Auth.UpgradeGuestAsync("player1", "secret123")
"""
                    },
                    #{
                        label => ~"Unreal",
                        lang => ~"cpp",
                        body =>
                            ~"""
// Callback delegate on UAsobiAuth.
UAsobiClient* Client = NewObject<UAsobiClient>();
Client->SetBaseUrl(TEXT("http://localhost:8084"));

UAsobiAuth* Auth = NewObject<UAsobiAuth>();
Auth->Init(Client);

Auth->Guest(DeviceId, DeviceSecret, OnGuest);

// OnGuest is an FOnAsobiAuthResponse; the returned tokens are stored on the client automatically.
// Upgrade with Auth->UpgradeGuest(TEXT("player1"), TEXT("secret"), OnUpgrade)
"""
                    },
                    #{
                        label => ~"Dart",
                        lang => ~"dart",
                        body =>
                            ~"""
// Async Future on client.auth.
final client = AsobiClient('localhost', port: 8084);

final auth = await client.auth.guest(deviceId, deviceSecret);
print('guest ${auth.playerId}');

// The typed AuthResponse exposes playerId but not created, so detect a resume here
// by matching playerId across launches (exactly the checkpoint below).
// Upgrade with await client.auth.upgradeGuest('player1', 'secret123')
"""
                    },
                    #{
                        label => ~"JS",
                        lang => ~"typescript",
                        body =>
                            ~"""
// Async, params object with raw wire field names.
const sdk = new Asobi({ baseUrl: "http://localhost:8084" });

const session = await sdk.auth.guest({ device_id: deviceId, device_secret: deviceSecret });
console.log(`guest ${session.player_id} created=${session.created}`);

// guest() stores the returned tokens exactly like login(), so the rest of the SDK is authenticated immediately.
// Upgrade with await sdk.auth.upgradeGuest({ username: "alice", password: "s3cret-password" })
"""
                    },
                    #{
                        label => ~"LÖVE",
                        lang => ~"lua",
                        body =>
                            ~"""
-- Blocking, returns data, err.
local asobi = require("asobi")
local client = asobi.new({host = "localhost", port = 8084})

local data, err = asobi.auth.guest(client, device_id, device_secret)
if err then error("guest auth failed: " .. err.error) end
print("guest " .. tostring(data.player_id) .. " created=" .. tostring(data.created))

-- Auth is blocking, so call it at startup, not inside love.update.
-- Upgrade with asobi.auth.upgrade_guest(client, "chosen_name", "pass1234")
"""
                    }
                ]
            }),

            checkpoint([
                {p, [], [~"Prove the same identity survives a restart."]},
                {ol, [], [
                    {li, [], [
                        ~"First run: generate a ",
                        {code, [], [~"device_id"]},
                        ~" and ",
                        {code, [], [~"device_secret"]},
                        ~", store both on the device, and call ",
                        {code, [], [~"guest(...)"]},
                        ~". Log the ",
                        {code, [], [~"player_id"]},
                        ~"; ",
                        {code, [], [~"created"]},
                        ~" is ",
                        {code, [], [~"true"]},
                        ~"."
                    ]},
                    {li, [], [~"Stop the client completely."]},
                    {li, [], [
                        ~"Second run: read the stored ",
                        {code, [], [~"device_id"]},
                        ~" and ",
                        {code, [], [~"device_secret"]},
                        ~" back, call ",
                        {code, [], [~"guest(...)"]},
                        ~" again with the same pair. Log the ",
                        {code, [], [~"player_id"]},
                        ~"."
                    ]}
                ]},
                {p, [], [
                    ~"You see the pass when the two ",
                    {code, [], [~"player_id"]},
                    ~" values match and the second response has no ",
                    {code, [], [~"created"]},
                    ~" field. If instead you get ",
                    {code, [], [~"403 guest_auth_disabled"]},
                    ~", the server half is missing: check that ",
                    {code, [], [~"guest_auth = true"]},
                    ~" is declared, and (self-hosted) that ",
                    {code, [], [~"ASOBI_GUEST_VERIFIER_PEPPER"]},
                    ~" is set. If a resume returns ",
                    {code, [], [~"401 invalid_device_secret"]},
                    ~", the client is not persisting the same secret between runs."
                ]}
            ]),

            nextstep(
                ~"/docs/learn/storage",
                ~"Step 5 - Storing data: the storage API, not SQL",
                ~"Now that a player has a durable id, give them something durable to keep."
            )
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).

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
