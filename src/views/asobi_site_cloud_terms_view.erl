-module(asobi_site_cloud_terms_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(#{id => ~"cloud-terms", title => ~"Cloud Terms of Service - Asobi"}, Bindings),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {'div', [{class, ~"guide-page"}], [
                {'div', [{class, ~"guide-header"}], [
                    {h1, [], [~"Asobi Cloud Terms of Service"]},
                    {p, [], [
                        ~"Last updated: 23 July 2026. These terms govern your use of Asobi Cloud - the hosted service at ",
                        {code, [], [~"console.asobi.dev"]},
                        ~" and the game-backend environments we run for you. The ",
                        {a, [{href, ~"/terms"}], [~"website terms"]},
                        ~" cover the asobi.dev website; the open-source library is governed by the Apache 2.0 licence."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Provider"]},
                    {p, [], [
                        ~"Asobi Cloud is operated by Widgrensit AB, Sweden. Contact: ",
                        {a, [{href, ~"mailto:legal@asobi.dev"}], [~"legal@asobi.dev"]},
                        ~"."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"The service"]},
                    {p, [], [
                        ~"We provision and operate hosted environments that run the game backends you deploy. Each environment is a monthly subscription, priced as shown at checkout. We manage the infrastructure; you manage your game."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Your account"]},
                    {p, [], [
                        ~"You sign in with a supported identity provider and are responsible for activity under your account, including keeping deploy keys and other credentials confidential. Tell us promptly at ",
                        {a, [{href, ~"mailto:security@asobi.dev"}], [~"security@asobi.dev"]},
                        ~" if you suspect a compromise."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Billing"]},
                    {ul, [], [
                        {li, [], [
                            ~"Payments are handled by Paddle as merchant of record. Paddle is the seller for your checkout and issues your invoices and receipts; card details never touch Asobi."
                        ]},
                        {li, [], [
                            ~"Subscriptions renew monthly until cancelled. You can cancel any time from the billing portal; cancellation takes effect at the end of the current billing period."
                        ]},
                        {li, [], [
                            ~"Refunds are handled per the ",
                            {a, [{href, ~"/refunds"}], [~"refund policy"]},
                            ~"."
                        ]},
                        {li, [], [
                            ~"If payment fails and is not resolved, we may suspend your environments after notice."
                        ]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Your content"]},
                    {p, [], [
                        ~"Your game code, bundles, assets, and data remain yours. You grant us the licence needed to host, run, store, and transmit them solely to provide the service. You are responsible for having the rights to what you deploy and for your game's own compliance with applicable law."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Player data"]},
                    {p, [], [
                        ~"For your players' personal data you are the controller and we are the processor, under the ",
                        {a, [{href, ~"/dpa"}], [~"data processing agreement"]},
                        ~", which forms part of these terms."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Acceptable use"]},
                    {p, [], [~"You must not use Asobi Cloud to:"]},
                    {ul, [], [
                        {li, [], [~"host unlawful or infringing content, or malware;"]},
                        {li, [], [
                            ~"attack, probe, or interfere with the service, other tenants, or third parties;"
                        ]},
                        {li, [], [
                            ~"mine cryptocurrency or run workloads unrelated to operating a game backend;"
                        ]},
                        {li, [], [~"resell the service without a separate agreement with us."]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Availability and support"]},
                    {p, [], [
                        ~"We run the service with reasonable skill and care but do not guarantee uninterrupted availability, and maintenance may cause short interruptions. Support is provided on a reasonable-efforts basis via email and Discord."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Suspension and termination"]},
                    {p, [], [
                        ~"We may suspend or terminate your account for non-payment, breach of these terms, or a security risk - with notice where practicable. You may stop using the service and cancel at any time. After termination your environments stop; you have 30 days to export your data, after which it is deleted."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Switching and data egress"]},
                    {p, [], [
                        ~"You can export your game data at any time while subscribed and during the 30-day window after termination, and we charge no switching or egress fees. For customers in the EU, the EU Data Act (Regulation (EU) 2023/2854) provides additional switching rights; contact ",
                        {a, [{href, ~"mailto:legal@asobi.dev"}], [~"legal@asobi.dev"]},
                        ~" to exercise them. If you self-host the open-source library instead, your data never passes through us at all."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Disclaimer and liability"]},
                    {p, [], [
                        ~"The service is provided \"as is\", without warranties beyond those that cannot be excluded. To the extent permitted by law, neither party is liable for indirect or consequential loss, and our total liability under these terms is capped at the fees you paid us in the 12 months before the claim arose. Nothing in these terms limits liability that cannot be limited under applicable law."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Changes"]},
                    {p, [], [
                        ~"We may update these terms. For material changes we will give at least 30 days' notice by email or in the console; continued use after that constitutes acceptance."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Governing law"]},
                    {p, [], [
                        ~"These terms are governed by Swedish law, and disputes are resolved by the Swedish courts."
                    ]}
                ]}
            ]}
        ]}
    ).
