-module(asobi_site_docs_page).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {Bindings, #{}}.

-spec render(az:bindings()) -> az:template().
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
