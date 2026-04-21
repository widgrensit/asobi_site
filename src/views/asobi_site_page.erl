-module(asobi_site_page).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1, handle_info/2]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    ?connected andalso ?send(connected),
    {Bindings, #{}}.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            ?stateless(asobi_site_nav, render, #{active => ?get(active)}),
            ?stateful(?get(view), #{
                id => ?get(view_id),
                %% Route extras forwarded to the child view (workaround for
                %% arizona not supporting arbitrary route-binding passthrough).
                slug => ?get(slug, ~""),
                doc_view => ?get(doc_view, undefined),
                doc_view_id => ?get(doc_view_id, ~""),
                active_path => ?get(active_path, ~"")
            })
        ]}
    ).

-spec handle_info(connected, az:bindings()) -> az:handle_info_ret().
handle_info(connected, Bindings) ->
    {Bindings, #{}, [arizona_js:set_title(~"Asobi")]}.
