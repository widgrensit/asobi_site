-module(asobi_site_docs_cloud_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(#{id => ~"docs-cloud", title => ~"Cloud — Asobi docs"}, Bindings),
        #{}
    }.

-spec render(map()) -> arizona_template:template().
render(Bindings) ->
    Content = ?html(
        {'div', [], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Cloud"
            ]},
            {h1, [], [~"Cloud hosting"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Managed Asobi is in private beta. Join the waitlist for early access, pricing, and the hosting-specific docs that will live here."
            ]},

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Not ready yet. "]},
                    ~"These docs cover deployment, environments, scaling, and billing \x{2014} all of which will land alongside the beta."
                ]}
            ]},

            {'div', [{class, ~"docs-cta-row"}], [
                {a, [{href, ~"/cloud"}, {class, ~"btn btn-primary"}, az_navigate], [
                    ~"Join the waitlist \x{2192}"
                ]},
                {a, [{href, ~"/docs/self-host"}, {class, ~"btn btn-secondary"}, az_navigate], [
                    ~"Self-host in the meantime"
                ]}
            ]}
        ]}
    ),
    asobi_site_docs_shell:render(maps:get(id, Bindings), ~"/docs/cloud", Content).
