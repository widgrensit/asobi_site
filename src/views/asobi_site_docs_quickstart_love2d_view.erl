-module(asobi_site_docs_quickstart_love2d_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-qs-love2d", title => ~"LÖVE quickstart — Asobi docs"},
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
                ~" / Quick start - LÖVE"
            ]},
            {h1, [], [~"Quick start - LÖVE"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Connect a LÖVE (Love2D) game to a running Asobi server in about five minutes. ",
                ~"No server yet? Run the ",
                {a, [{href, ~"/docs/quickstart"}, az_navigate], [~"server quickstart"]},
                ~" first - it gives you a backend on localhost:8084 with a ",
                {code, [], [~"default"]},
                ~" match mode."
            ]},

            {h2, [], [~"1. Vendor the SDK"]},
            {p, [], [
                ~"The SDK is pure Lua with no compiled modules - copy the ",
                {code, [], [~"asobi/"]},
                ~" folder into your project next to ",
                {code, [], [~"main.lua"]},
                ~". Its transport uses luasocket, which LÖVE already bundles, so there is nothing to install."
            ]},
            code(
                ~"text",
                ~"""
my_game/
├── main.lua
├── conf.lua
└── asobi/          <- copy this whole dir
"""
            ),
            {p, [], [
                ~"Then ",
                {code, [], [~"local asobi = require(\"asobi\")"]},
                ~"."
            ]},

            {h2, [], [~"2. Connect in love.load, pump in love.update"]},
            {p, [], [
                ~"Guest auth is a blocking HTTP call - do it in ",
                {code, [], [~"love.load"]},
                ~", not the game loop. The WebSocket is non-blocking: you ",
                {strong, [], [~"must"]},
                ~" call ",
                {code, [], [~"realtime:update()"]},
                ~" every frame or no callbacks fire."
            ]},
            code(
                ~"lua",
                ~"""
local asobi = require("asobi")
local client, matched = nil, false

function love.load()
  client = asobi.new({host = "localhost", port = 8084})

  -- device_secret = base64 of >= 32 CSPRNG bytes, generated once and persisted
  -- by you; device_id = any stable per-install id.
  local _, err = asobi.auth.guest(client, my_device_id, my_device_secret)
  if err then error("guest auth failed: " .. err.error) end

  -- Bind callbacks BEFORE queueing.
  client.realtime:on("match_matched", function(p) matched = true end)
  client.realtime:on("match_state", function(state)
    local me = (state.players or {})[client.player_id]
    -- render me.x, me.y
  end)

  assert(client.realtime:connect())
  client.realtime:add_to_matchmaker({mode = "default"})
end

function love.update(dt)
  client.realtime:update()          -- MUST pump every frame
  if matched then
    client.realtime:send_match_input({move_x = 0, move_y = 0})
  end
end

function love.quit()
  client.realtime:disconnect()
end
"""
            ),

            {h2, [], [~"Core API"]},
            {ul, [], [
                {li, [], [{code, [], [~"asobi.new({host, port = 8084, use_ssl = false})"]}]},
                {li, [], [
                    {code, [], [~"asobi.auth.guest(client, device_id, device_secret)"]},
                    ~" -> ",
                    {code, [], [~"(data, err)"]},
                    ~" (synchronous)."
                ]},
                {li, [], [
                    {code, [], [~"client.realtime:connect()"]},
                    ~" / ",
                    {code, [], [~"add_to_matchmaker({mode = \"default\"})"]},
                    ~" / ",
                    {code, [], [~"send_match_input(input)"]},
                    ~"."
                ]},
                {li, [], [
                    {code, [], [~"client.realtime:on(event, fn)"]},
                    ~" - callback-based; e.g. ",
                    {code, [], [~"\"match_matched\""]},
                    ~", ",
                    {code, [], [~"\"match_state\""]},
                    ~"."
                ]},
                {li, [], [
                    {code, [], [~"client.realtime:update()"]},
                    ~" - the pump; callbacks only fire while it runs."
                ]}
            ]},

            {h2, [], [~"Gotchas"]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Pump every frame. "]},
                    ~"Nothing is received and no ",
                    {code, [], [~":on"]},
                    ~" callback fires unless ",
                    {code, [], [~"realtime:update()"]},
                    ~" runs in ",
                    {code, [], [~"love.update"]},
                    ~"."
                ]},
                {li, [], [
                    {strong, [], [~"Auth blocks the frame. "]},
                    ~"Guest/login are synchronous luasocket calls - run them at startup or on a deliberate action, never in the loop."
                ]},
                {li, [], [
                    {strong, [], [~"Plain ws:// only out of the box. "]},
                    ~"LÖVE bundles luasocket but not luasec - for ",
                    {code, [], [~"wss://"]},
                    ~" you need luasec on the path and ",
                    {code, [], [~"use_ssl = true"]},
                    ~"."
                ]}
            ]},

            {h2, [], [~"What's next"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/lua"}, az_navigate], [~"Full LÖVE / Lua client reference"]}
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/protocols/websocket"}, az_navigate], [
                        ~"WebSocket protocol"
                    ]}
                ]},
                {li, [], [{a, [{href, ~"/docs/authentication"}, az_navigate], [~"Authentication"]}]}
            ]}
        ]}
    ).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
