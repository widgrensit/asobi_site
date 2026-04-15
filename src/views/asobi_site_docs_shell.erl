-module(asobi_site_docs_shell).
-include_lib("arizona/include/arizona_stateless.hrl").

%% Shared shell for all /docs/* pages. Renders the site nav + docs sidebar
%% + a content container. Each doc view calls `render/2` with its active
%% path and content template.

-export([render/2]).

-spec render(binary(), arizona_template:template()) -> arizona_template:template().
render(ActivePath, Content) ->
    L = fun(Href, Label) -> sidebar_link(Href, Label, ActivePath) end,

    %% Get started
    Overview = L(~"/docs", ~"Overview"),
    Quickstart = L(~"/docs/quickstart", ~"Quick start"),
    Concepts = L(~"/docs/concepts", ~"Core concepts"),

    %% Tutorials
    TicTacToe = L(~"/docs/tutorials/tic-tac-toe", ~"Tic-tac-toe (Lua + Erlang)"),

    %% Protocols & auth
    WsProto = L(~"/docs/protocols/websocket", ~"WebSocket"),
    RestProto = L(~"/docs/protocols/rest", ~"REST API"),
    Auth = L(~"/docs/authentication", ~"Authentication"),

    %% Gameplay systems
    Matchmaking = L(~"/docs/matchmaking", ~"Matchmaking"),
    World = L(~"/docs/world-server", ~"World server"),
    Voting = L(~"/docs/voting", ~"Voting"),

    %% Commerce
    Economy = L(~"/docs/economy", ~"Economy & IAP"),
    Leaderboards = L(~"/docs/leaderboards", ~"Leaderboards & tournaments"),

    %% Lua reference
    LuaApi = L(~"/docs/lua/api", ~"game.* API"),
    LuaCallbacks = L(~"/docs/lua/callbacks", ~"Callbacks"),
    LuaCookbook = L(~"/docs/lua/cookbook", ~"Cookbook"),
    LuaBots = L(~"/docs/lua/bots", ~"Bots"),

    %% Erlang reference
    ErlangApi = L(~"/docs/erlang/api", ~"Erlang API"),

    %% Ops & deploy
    SelfHost = L(~"/docs/self-host", ~"Self-host"),
    Clustering = L(~"/docs/clustering", ~"Clustering"),
    Configuration = L(~"/docs/configuration", ~"Configuration"),
    Performance = L(~"/docs/performance", ~"Performance"),
    Cloud = L(~"/docs/cloud", ~"Cloud (coming soon)"),

    Nav = asobi_site_nav:render(docs),
    ?html(
        {'div', [{class, ~"docs-root"}], [
            Nav,
            {'div', [{class, ~"docs-shell"}], [
                {aside, [{class, ~"docs-sidebar"}], [
                    {nav, [{class, ~"docs-nav"}], [
                        {'div', [{class, ~"docs-nav-section"}], [
                            {h3, [], [~"Get started"]},
                            Overview,
                            Quickstart,
                            Concepts
                        ]},
                        {'div', [{class, ~"docs-nav-section"}], [
                            {h3, [], [~"Tutorials"]},
                            TicTacToe
                        ]},
                        {'div', [{class, ~"docs-nav-section"}], [
                            {h3, [], [~"Protocols & auth"]},
                            WsProto,
                            RestProto,
                            Auth
                        ]},
                        {'div', [{class, ~"docs-nav-section"}], [
                            {h3, [], [~"Gameplay systems"]},
                            Matchmaking,
                            World,
                            Voting
                        ]},
                        {'div', [{class, ~"docs-nav-section"}], [
                            {h3, [], [~"Commerce"]},
                            Economy,
                            Leaderboards
                        ]},
                        {'div', [{class, ~"docs-nav-section"}], [
                            {h3, [], [~"Lua reference"]},
                            LuaApi,
                            LuaCallbacks,
                            LuaCookbook,
                            LuaBots
                        ]},
                        {'div', [{class, ~"docs-nav-section"}], [
                            {h3, [], [~"Erlang reference"]},
                            ErlangApi
                        ]},
                        {'div', [{class, ~"docs-nav-section"}], [
                            {h3, [], [~"Operate"]},
                            SelfHost,
                            Configuration,
                            Clustering,
                            Performance,
                            Cloud
                        ]}
                    ]}
                ]},
                {main, [{class, ~"docs-main"}], [
                    {'div', [{class, ~"docs-content"}], [Content]}
                ]}
            ]}
        ]}
    ).

sidebar_link(Href, Label, Active) ->
    Class =
        case Href of
            Active -> ~"docs-nav-link active";
            _ -> ~"docs-nav-link"
        end,
    ?html({a, [{href, Href}, {class, Class}], [Label]}).
