-module(asobi_site_docs_page).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {Bindings, #{}}.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    DocView = ?get(doc_view),
    true = is_atom(DocView),
    ?html(
        {'div', [{id, ?get(id)}, {class, ~"docs-root"}], [
            {'div', [{class, ~"docs-shell"}], [
                ?stateless(asobi_site_docs_sidebar, render, #{
                    active_path => ?get(active_path)
                }),
                {main, [{class, ~"docs-main"}], [
                    {'div', [{class, ~"docs-content"}], [
                        ?stateful(DocView, #{id => ?get(doc_view_id)})
                    ]}
                ]}
            ]}
        ]}
    ).
