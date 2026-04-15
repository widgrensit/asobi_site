-module(asobi_site_privacy_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"privacy", title => ~"Privacy Policy \x{2014} Asobi"}, Bindings), #{}}.

-spec render(map()) -> arizona_template:template().
render(Bindings) ->
    Nav = asobi_site_nav:render(none),
    Footer = asobi_site_footer:render(),
    ?html(
        {'div', [{id, ?get(id)}], [
            Nav,
            {'div', [{class, ~"guide-page"}], [
                {'div', [{class, ~"guide-header"}], [
                    {h1, [], [~"Privacy Policy"]},
                    {p, [], [
                        ~"Full policy coming before Asobi Cloud exits closed beta. ",
                        ~"Until then, this page is a placeholder describing what the full ",
                        ~"policy will cover."
                    ]}
                ]},
                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"What we will collect"]},
                    {p, [], [
                        ~"Beta signup form: email, studio/project name, engine, stage, current backend. ",
                        ~"Used only to contact you about the beta and onboarding. No tracking, no third-party sharing."
                    ]},
                    {h2, [], [~"Analytics"]},
                    {p, [], [
                        ~"This site uses Plausible Analytics, hosted in the EU. No cookies, ",
                        ~"no personal data, aggregate page views only."
                    ]},
                    {h2, [], [~"Contact"]},
                    {p, [], [
                        ~"Questions? ",
                        {a, [{href, ~"mailto:privacy@asobi.dev"}], [~"privacy@asobi.dev"]}
                    ]}
                ]}
            ]},
            Footer
        ]}
    ).
