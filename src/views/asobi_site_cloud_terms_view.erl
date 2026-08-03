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
                        ~"Last updated: 25 July 2026. These terms govern your use of Asobi Cloud - the hosted service at ",
                        {code, [], [~"console.asobi.dev"]},
                        ~" and the game-backend environments we run for you. The ",
                        {a, [{href, ~"/terms"}], [~"website terms"]},
                        ~" cover the asobi.dev website; the open-source library is governed by the Apache 2.0 licence."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Provider"]},
                    {p, [], [
                        ~"Asobi Cloud is operated by Widgrens IT AB, org.nr 559241-2752, Melongatan 15, 754 49 Uppsala, Sweden. Contact: ",
                        {a, [{href, ~"mailto:legal@asobi.dev"}], [~"legal@asobi.dev"]},
                        ~"."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"The service"]},
                    {p, [], [
                        ~"We provision and operate hosted environments that run the game backends you deploy. Each environment is a monthly subscription, priced as shown at checkout. We manage the infrastructure; you manage your game."
                    ]},
                    {p, [], [
                        ~"Asobi Cloud is offered to businesses and professionals for use in their trade or profession, not to consumers. By subscribing you confirm you are acting for business purposes."
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
                    ]},
                    {p, [], [
                        ~"You will indemnify us against third-party claims, and resulting damages and reasonable costs, arising from your game or other content you deploy - including claims that it infringes someone's rights or violates applicable law - except to the extent the claim is caused by us."
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
                    ]},
                    {h3, [], [~"Reporting illegal content"]},
                    {p, [], [
                        ~"Anyone can report content hosted on Asobi Cloud they believe is illegal by emailing ",
                        {a, [{href, ~"mailto:abuse@asobi.dev"}], [~"abuse@asobi.dev"]},
                        ~" with the location of the content, why it is considered illegal, and contact details. ",
                        {a, [{href, ~"mailto:abuse@asobi.dev"}], [~"abuse@asobi.dev"]},
                        ~" is also our point of contact for authorities and for service recipients under the EU Digital Services Act (Regulation (EU) 2022/2065); communication can be in English or Swedish. We review reports promptly and act where warranted - typically by asking the responsible customer to remove the content, or by restricting or removing it ourselves in clear cases. When we restrict content or an account on these grounds, we tell the affected customer what we did and why, and they can object by replying. We do not use automated content moderation."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Sanctions and export control"]},
                    {p, [], [
                        ~"You may not use the service if you are, or act for, a person or entity subject to EU, UN, UK, or US sanctions, or established in a jurisdiction to which providing the service would violate applicable sanctions or export-control law (including Russia and Belarus). We may suspend or terminate the service immediately where required to comply with such law."
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
                        ~"You can switch to another provider, to your own on-premises infrastructure, or to self-hosting the open-source library, or simply stop using the service - at any time. In line with the EU Data Act (Regulation (EU) 2023/2854):"
                    ]},
                    {ul, [], [
                        {li, [], [
                            ~"You initiate switching or exit by notice from the console or to ",
                            {a, [{href, ~"mailto:legal@asobi.dev"}], [~"legal@asobi.dev"]},
                            ~". No notice period applies beyond the current billing period (never more than the 2-month maximum the Data Act allows)."
                        ]},
                        {li, [], [
                            ~"We complete switching within a transitional period of 30 calendar days from your requested date, during which the service keeps running and we assist with the migration. If completing within 30 days is technically unfeasible for your environment, we will tell you within 14 working days, explain why, and propose an alternative period of at most 7 months. You may extend the transitional period once."
                        ]},
                        {li, [], [
                            ~"We charge no switching, egress, or exit fees of any kind."
                        ]},
                        {li, [], [
                            ~"Your exportable data (game data, configuration, and metadata) is provided in open, machine-readable formats (SQL/CSV/JSON), during the subscription and for 30 days after it ends."
                        ]},
                        {li, [], [
                            ~"Instead of export you can ask us to erase your data at the end of the contract; otherwise it is deleted after the 30-day export window."
                        ]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Backups"]},
                    {p, [], [
                        ~"We take daily backups of environment databases and retain them for 14 days, stored within the EU."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Disclaimer and liability"]},
                    {p, [], [
                        ~"The service is provided \"as is\", without warranties beyond those that cannot be excluded. To the extent permitted by law, neither party is liable for indirect or consequential loss, and our total liability under these terms is capped at the fees you paid us in the 12 months before the claim arose. We are liable for loss of data only to the extent it results from our failure to keep the backup commitment above. Nothing in these terms limits liability that cannot be limited under applicable law, or the indemnities in these terms."
                    ]},
                    {p, [], [
                        ~"Claims under these terms must be notified to us within 6 months of when you became aware (or ought to have become aware) of the grounds for the claim; defects in the service should be reported within 90 days of appearing."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Force majeure"]},
                    {p, [], [
                        ~"Neither party is liable for failure to perform (other than payment obligations) caused by circumstances beyond its reasonable control - such as natural disasters, war, terrorism, labour conflicts, general internet or power failures, acts of authorities, or failures of upstream providers that could not reasonably have been mitigated - for as long as the circumstance persists. If it persists for more than 60 days, either party may terminate affected subscriptions without penalty."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Assignment"]},
                    {p, [], [
                        ~"We may assign this agreement, including the data processing agreement, to an affiliate or in connection with a merger, reorganisation, or transfer of the business it relates to, and will notify you of any such assignment. You may not assign it without our consent, not to be unreasonably withheld."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Changes"]},
                    {p, [], [
                        ~"We may update these terms. For material changes we will give at least 30 days' notice by email or in the console; continued use after that constitutes acceptance."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"General"]},
                    {p, [], [
                        ~"These terms, the documents they incorporate, and your order at checkout are the entire agreement between us for Asobi Cloud. If a provision is held invalid, the rest remains in effect. Not enforcing a provision is not a waiver of it. Formal notices to us go to ",
                        {a, [{href, ~"mailto:legal@asobi.dev"}], [~"legal@asobi.dev"]},
                        ~"; notices to you go to the email on your account. Provisions that by their nature survive termination (including payment obligations, indemnities, liability limits, and the export window) survive it."
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
