-module(asobi_site_page).
-include("asobi_site_view.hrl").

-export([render/1]).

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    View = ?get(view),
    true = is_atom(View),
    ?html(
        {'div', [{id, ?get(id)}], [
            ?stateless(asobi_site_nav, render, #{active => ?get(active)}),
            ?stateful(View, #{
                id => ?get(view_id),
                slug => ?get(slug, ~""),
                doc_view => ?get(doc_view, undefined),
                doc_view_id => ?get(doc_view_id, ~""),
                active_path => ?get(active_path, ~"")
            })
        ]}
    ).
