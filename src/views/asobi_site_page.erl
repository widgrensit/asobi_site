-module(asobi_site_page).
-include_lib("arizona/include/arizona_view.hrl").

-export([mount/2, render/1, handle_info/2]).

-spec mount(az:bindings(), az:request()) -> az:mount_ret().
mount(Bindings, Req) ->
    %% Project URL path bindings (e.g. `:slug` from `/blog/:slug`) into
    %% Bindings so the embedded view can pick them up via `?get(Key)`.
    {PathBs, _Req1} = arizona_req:bindings(Req),
    ?connected andalso ?send(connected),
    {maps:merge(PathBs, Bindings), #{}}.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    View = ?get(view),
    true = is_atom(View),
    ?html(
        {'div', [{id, ?get(id)}], [
            ?stateless(asobi_site_nav, render, #{active => ?get(active)}),
            %% Forward all parent bindings; only `view_id` is tracked as a
            %% dep. Fine here: every nav remounts the page handler, so the
            %% child always gets fresh Bindings.
            ?stateful(View, Bindings#{id => ?get(view_id)})
        ]}
    ).

-spec handle_info(connected, az:bindings()) -> az:handle_info_ret().
handle_info(connected, Bindings) ->
    {Bindings, #{}, [arizona_js:set_title(~"Asobi")]}.
