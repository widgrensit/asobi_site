-module(asobi_site_docs_shell).
-include_lib("arizona/include/arizona_stateless.hrl").

%% Shared shell for all /docs/* pages. Renders the site nav + docs sidebar
%% + a content container. Each doc view calls `render/2` with its active
%% path and content template.

-export([render/2]).

-spec render(binary(), arizona_template:template()) -> arizona_template:template().
render(ActivePath, Content) ->
    %% Compute link classes outside the template (Arizona parse transform
    %% cannot spread a variable list inside a literal tree).
    L = fun(Href, Label) -> sidebar_link(Href, Label, ActivePath) end,
    Overview = L(~"/docs", ~"Overview"),
    Quickstart = L(~"/docs/quickstart", ~"Quick start"),
    Concepts = L(~"/docs/concepts", ~"Core concepts"),
    TicTacToe = L(~"/docs/tutorials/tic-tac-toe", ~"Tic-tac-toe (Lua)"),
    LuaApi = L(~"/docs/lua/api", ~"game.* API"),
    LuaCallbacks = L(~"/docs/lua/callbacks", ~"Game module callbacks"),
    LuaCookbook = L(~"/docs/lua/cookbook", ~"Cookbook"),
    ErlangApi = L(~"/docs/erlang/api", ~"Erlang API"),
    SelfHost = L(~"/docs/self-host", ~"Self-host"),
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
                            {h3, [], [~"Lua reference"]},
                            LuaApi,
                            LuaCallbacks,
                            LuaCookbook
                        ]},
                        {'div', [{class, ~"docs-nav-section"}], [
                            {h3, [], [~"Erlang reference"]},
                            ErlangApi
                        ]},
                        {'div', [{class, ~"docs-nav-section"}], [
                            {h3, [], [~"Deploy"]},
                            SelfHost,
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
