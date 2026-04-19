-module(asobi_site_page).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {Bindings, #{}}.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            ?stateless(asobi_site_nav, render, #{active => ?get(active)}),
            ?stateful(?get(view), #{id => ?get(view_id)})
        ]}
    ).
