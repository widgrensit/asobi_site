-module(asobi_site_terms_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"terms", title => ~"Terms of Service \x{2014} Asobi"}, Bindings), #{}}.

-spec render(map()) -> arizona_template:template().
render(Bindings) ->
    Nav = asobi_site_nav:render(none),
    Footer = asobi_site_footer:render(),
    ?html(
        {'div', [{id, ?get(id)}], [
            Nav,
            {'div', [{class, ~"guide-page"}], [
                {'div', [{class, ~"guide-header"}], [
                    {h1, [], [~"Terms of Service"]},
                    {p, [], [
                        ~"Full terms will be published before Asobi Cloud exits closed beta. ",
                        ~"This page is a placeholder."
                    ]}
                ]},
                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Open-source core"]},
                    {p, [], [
                        ~"The Asobi library itself is released under the Apache 2.0 license ",
                        ~"and governed by that license, not by these terms. See the ",
                        {a, [{href, ~"https://github.com/widgrensit/asobi/blob/main/LICENSE"}], [
                            ~"LICENSE file"
                        ]},
                        ~" in the repository."
                    ]},
                    {h2, [], [~"Hosted service"]},
                    {p, [], [
                        ~"Asobi Cloud is in closed beta. Beta participants are covered by a ",
                        ~"separate beta agreement communicated at onboarding."
                    ]},
                    {h2, [], [~"Contact"]},
                    {p, [], [
                        ~"Questions? ",
                        {a, [{href, ~"mailto:legal@asobi.dev"}], [~"legal@asobi.dev"]}
                    ]}
                ]}
            ]},
            Footer
        ]}
    ).
