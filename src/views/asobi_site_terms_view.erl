-module(asobi_site_terms_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"terms", title => ~"Terms of Service - Asobi"}, Bindings), #{}}.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {'div', [{class, ~"guide-page"}], [
                {'div', [{class, ~"guide-header"}], [
                    {h1, [], [~"Terms of Service"]},
                    {p, [], [
                        ~"Last updated: 23 July 2026. These terms cover the use of the ",
                        {code, [], [~"asobi.dev"]},
                        ~" website. The open-source Asobi library is covered by its licence; the hosted service is covered by the ",
                        {a, [{href, ~"/cloud-terms"}], [~"Asobi Cloud Terms of Service"]},
                        ~"."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Provider"]},
                    {p, [], [
                        ~"The site is operated by Widgrensit AB, Sweden. Contact: ",
                        {a, [{href, ~"mailto:legal@asobi.dev"}], [~"legal@asobi.dev"]},
                        ~"."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Open-source library"]},
                    {p, [], [
                        ~"The Asobi library, runtime, and client SDKs are released under the ",
                        {a,
                            [
                                {href, ~"https://github.com/widgrensit/asobi/blob/main/LICENSE"}
                            ],
                            [~"Apache 2.0 license"]},
                        ~" and governed by it. Nothing on this website modifies or overrides the Apache 2.0 license. If you distribute or use the library, the Apache 2.0 terms are what apply."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Website use"]},
                    {p, [], [
                        ~"You may read, link to, and share pages on ",
                        {code, [], [~"asobi.dev"]},
                        ~" freely. Don't attempt to break the site, probe it for vulnerabilities without a coordinated disclosure arrangement, or use it to attack third parties. Automated scraping is fine in moderation; please don't DDoS us."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Asobi Cloud"]},
                    {p, [], [
                        ~"Use of the hosted service is governed by the ",
                        {a, [{href, ~"/cloud-terms"}], [~"Asobi Cloud Terms of Service"]},
                        ~" together with the ",
                        {a, [{href, ~"/dpa"}], [~"DPA"]},
                        ~" and the ",
                        {a, [{href, ~"/refunds"}], [~"refund policy"]},
                        ~" - not by these website terms."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"No warranty"]},
                    {p, [], [
                        ~"The site is provided \x{201C}as is\x{201D}, without warranty of availability, fitness for any particular purpose, or accuracy of content. We try hard to keep it up and accurate, but we make no legal guarantees."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Liability"]},
                    {p, [], [
                        ~"To the extent permitted by law, Widgrensit AB is not liable for indirect, incidental, consequential, or punitive damages arising from use of the site. Our total liability for direct damages, if any, is limited to 100 EUR."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Governing law"]},
                    {p, [], [
                        ~"Swedish law applies. Disputes that cannot be resolved by email go to the competent Swedish courts."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Changes"]},
                    {p, [], [
                        ~"We may update these terms as the project evolves. Changes take effect the moment they're published on this page; the \x{201C}last updated\x{201D} date at the top tells you when."
                    ]}
                ]}
            ]}
        ]}
    ).
