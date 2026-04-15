-module(asobi_site_dpa_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"dpa", title => ~"DPA \x{2014} Asobi"}, Bindings), #{}}.

-spec render(map()) -> arizona_template:template().
render(Bindings) ->
    Nav = asobi_site_nav:render(none),
    Footer = asobi_site_footer:render(),
    ?html(
        {'div', [{id, ?get(id)}], [
            Nav,
            {'div', [{class, ~"guide-page"}], [
                {'div', [{class, ~"guide-header"}], [
                    {h1, [], [~"Data Processing Addendum"]},
                    {p, [], [
                        ~"EU Standard Contractual Clauses. Available on request ahead of the ",
                        ~"public DPA publication."
                    ]}
                ]},
                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"What the DPA will cover"]},
                    {p, [], [
                        ~"Controller/processor roles, sub-processor list (EU-only), ",
                        ~"data location (France, Clever Cloud), breach notification SLA (72h), ",
                        ~"data export and deletion, SCCs per EU Commission Decision 2021/914."
                    ]},
                    {h2, [], [~"Request a copy"]},
                    {p, [], [
                        ~"Beta customers and evaluators can request the draft DPA at ",
                        {a, [{href, ~"mailto:dpa@asobi.dev"}], [~"dpa@asobi.dev"]},
                        ~"."
                    ]}
                ]}
            ]},
            Footer
        ]}
    ).
