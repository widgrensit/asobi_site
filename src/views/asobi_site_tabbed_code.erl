%% @doc Reusable pure-CSS tab switcher for code snippets.
%%
%% Use via `?stateless/3' from any view:
%%
%% ```
%% ?stateless(asobi_site_tabbed_code, render, #{
%%     id => ~"lb-submit",
%%     tabs => [
%%         #{label => ~"Lua",    lang => ~"lua",    body => LuaBody},
%%         #{label => ~"Erlang", lang => ~"erlang", body => ErlBody}
%%     ]
%% })
%% '''
%%
%% Each instance needs a unique `id' — used as the radio group `name'
%% so multiple tab groups on the same page don't interfere.
%%
%% Up to 7 tabs are styled by `.tabbed-code' CSS (enough for the 7-SDK
%% homepage hero). Add more rules in `app.css' if more are needed.
-module(asobi_site_tabbed_code).
-include_lib("arizona/include/arizona_stateless.hrl").

-export([render/1, lua_erlang/3]).

-type tab() :: #{label := binary(), lang := binary(), body := binary()}.
-type bindings() :: #{id := binary(), tabs := [tab(), ...]}.

-spec render(bindings()) -> az:template().
render(Bindings) ->
    Id = ?get(id),
    Tabs = ?get(tabs),
    %% Tag each tab with its 1-based index so labels line up with inputs
    %% and panels for the :nth-of-type CSS rules.
    Indexed = lists:zip(lists:seq(1, length(Tabs)), Tabs),
    ?html(
        {'div', [{class, ~"tabbed-code"}], [
            ?each(fun({N, _Tab}) -> radio(Id, N) end, Indexed),
            {'div', [{class, ~"tabbed-code-labels"}, {role, ~"tablist"}], [
                ?each(
                    fun({N, #{label := Label}}) ->
                        {label, [{for, input_id(Id, N)}], [Label]}
                    end,
                    Indexed
                )
            ]},
            {'div', [{class, ~"tabbed-code-panels"}], [
                ?each(
                    fun({_, #{lang := Lang, body := Body}}) ->
                        {pre, [{class, ~"tabbed-code-panel"}], [
                            {code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}
                        ]}
                    end,
                    Indexed
                )
            ]}
        ]}
    ).

%% The first radio is checked by default so one tab is visible before
%% any user interaction.
radio(Id, 1) ->
    ?html(
        {input,
            [
                {type, ~"radio"},
                {name, Id},
                {id, input_id(Id, 1)},
                {checked, true}
            ],
            []}
    );
radio(Id, N) ->
    ?html(
        {input,
            [
                {type, ~"radio"},
                {name, Id},
                {id, input_id(Id, N)}
            ],
            []}
    ).

input_id(Id, N) ->
    iolist_to_binary([Id, $-, integer_to_binary(N)]).

%% @doc Shortcut for the common two-tab Lua/Erlang layout used across
%% the `/docs/*' pages. Returns a stateless descriptor that views can
%% drop directly into their `?html/1' tree.
-spec lua_erlang(Id :: binary(), LuaBody :: binary(), ErlBody :: binary()) ->
    arizona_template:stateless_descriptor().
lua_erlang(Id, LuaBody, ErlBody) ->
    ?stateless(?MODULE, render, #{
        id => Id,
        tabs => [
            #{label => ~"Lua", lang => ~"lua", body => LuaBody},
            #{label => ~"Erlang", lang => ~"erlang", body => ErlBody}
        ]
    }).
