-module(asobi_site_privacy_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"privacy", title => ~"Privacy Policy - Asobi"}, Bindings), #{}}.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {'div', [{class, ~"guide-page"}], [
                {'div', [{class, ~"guide-header"}], [
                    {h1, [], [~"Privacy Policy"]},
                    {p, [], [
                        ~"Last updated: 25 July 2026. This page tells you exactly what ",
                        {code, [], [~"asobi.dev"]},
                        ~" and the Asobi Cloud console at ",
                        {code, [], [~"console.asobi.dev"]},
                        ~" collect, why, where the data lives, and what you can ask us to do with it."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Controller"]},
                    {p, [], [
                        ~"Widgrens IT AB, org.nr 559241-2752, Melongatan 15, 754 49 Uppsala, Sweden. VAT no. SE559241275201. Contact: ",
                        {a, [{href, ~"mailto:privacy@asobi.dev"}], [~"privacy@asobi.dev"]},
                        ~"."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"What we collect and why"]},
                    {h3, [], [~"Website analytics"]},
                    {p, [], [
                        ~"Aggregate page-view statistics via ",
                        {strong, [], [~"Plausible Analytics"]},
                        ~" (EU-hosted, Estonian company). Plausible does not use cookies and does not store raw IP addresses or User-Agent strings. ",
                        ~"It generates a daily-rotating hash from ",
                        {code, [], [~"salt + domain + ip + user_agent"]},
                        ~" and discards the salt every 24 hours. What is recorded: page URL (without query strings), HTTP referrer, coarse device type, and country derived from IP."
                    ]},
                    {p, [], [
                        {strong, [], [~"Lawful basis: "]},
                        ~"legitimate interest (Art. 6(1)(f) GDPR) - measuring traffic with the least privacy-invasive tool we could find. No cookies means no consent banner is required under the ePrivacy Directive."
                    ]},

                    {h3, [], [~"Access request form"]},
                    {p, [], [
                        ~"Asobi Cloud is invite-only. The access request form at ",
                        {code, [], [~"console.asobi.dev"]},
                        ~" is hosted by us, on our own infrastructure. If you choose to submit it we collect: email address, your name or studio name, target engine, and an optional free-text note, plus whether the request is pending, invited, declined, or joined."
                    ]},
                    {p, [], [
                        {strong, [], [~"Lawful basis: "]},
                        ~"performance of pre-contract steps you asked for (Art. 6(1)(b)) and/or consent (Art. 6(1)(a)). We use this information only to decide on and act on your access request, and to contact you about onboarding. We do not share it with advertisers, brokers, or any third party outside the processors listed below."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Where data lives"]},
                    {p, [], [
                        ~"Everything we host is in the EU. The asobi.dev website, the console at ",
                        {code, [], [~"console.asobi.dev"]},
                        ~", and the databases and backups behind them all run on Hetzner in Germany. Our processors:"
                    ]},
                    {ul, [], [
                        {li, [], [
                            {strong, [], [~"Hetzner "]},
                            ~"(Germany) - website, console, database, and backup hosting."
                        ]},
                        {li, [], [
                            {strong, [], [~"Plausible Analytics "]},
                            ~"(Estonia, servers in the EU) - aggregate analytics for the website."
                        ]}
                    ]},
                    {p, [], [
                        ~"Browsing asobi.dev calls no Google, Cloudflare, or AWS service. Fonts are self-hosted, and the Plausible script is the only request your browser makes to anyone but us."
                    ]},

                    {h3, [], [~"Two companies we do not host"]},
                    {p, [], [
                        ~"Using the console brings in two companies outside that set. Each is an independent controller for the data you give it directly, under its own privacy policy - not a processor acting on our instructions:"
                    ]},
                    {ul, [], [
                        {li, [], [
                            {strong, [], [~"GitHub "]},
                            ~"- your identity provider. Signing in to the console sends your browser to GitHub, which then returns the account data listed under Asobi Cloud console accounts below. See ",
                            {a,
                                [
                                    {href,
                                        ~"https://docs.github.com/en/site-policy/privacy-policies"}
                                ],
                                [
                                    ~"GitHub's privacy statement"
                                ]},
                            ~"."
                        ]},
                        {li, [], [
                            {strong, [], [~"Paddle "]},
                            ~"- merchant of record for Asobi Cloud subscriptions. Checkout and payment happen at Paddle; card details never reach us. See ",
                            {a, [{href, ~"https://www.paddle.com/legal/privacy"}], [
                                ~"Paddle's privacy policy"
                            ]},
                            ~"."
                        ]}
                    ]},
                    {p, [], [
                        ~"Neither is involved in browsing asobi.dev, and neither receives your players' data. Sub-processors for the game backends we run for you are listed in the ",
                        {a, [{href, ~"/dpa"}, az_navigate], [~"Data Processing Agreement"]},
                        ~"."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Cookies and local storage"]},
                    {p, [], [
                        ~"The asobi.dev website sets ",
                        {strong, [], [~"no cookies"]},
                        ~" and writes nothing to localStorage or sessionStorage. No cookie banner is shown because there is nothing to consent to. The console sets strictly necessary session cookies only - see Asobi Cloud console accounts below."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Retention"]},
                    {ul, [], [
                        {li, [], [
                            ~"Analytics: retained by Plausible for the lifetime of our account (no raw identifiers kept - the daily hash cannot be reversed beyond 24 hours)."
                        ]},
                        {li, [], [
                            ~"Access requests: kept until the request is decided and, if you go on to join, for as long as the resulting account exists. Deleted sooner on request."
                        ]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Your rights"]},
                    {p, [], [
                        ~"Under the GDPR you can ask us to:"
                    ]},
                    {ul, [], [
                        {li, [], [~"Confirm what personal data we hold about you (access)."]},
                        {li, [], [~"Correct inaccuracies (rectification)."]},
                        {li, [], [~"Delete the data (erasure)."]},
                        {li, [], [~"Export it (portability)."]},
                        {li, [], [~"Object to its processing, or withdraw consent you gave."]}
                    ]},
                    {p, [], [
                        ~"Email ",
                        {a, [{href, ~"mailto:privacy@asobi.dev"}], [~"privacy@asobi.dev"]},
                        ~" and we'll respond within 30 days. You can also lodge a complaint with your local supervisory authority (IMY in Sweden)."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"No profiling"]},
                    {p, [], [
                        ~"We don't profile visitors, don't build advertising audiences, and don't make any automated decisions about you. There is no cross-site tracking."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Asobi Cloud console accounts"]},
                    {p, [], [
                        ~"If you use the Asobi Cloud console we process, as controller:"
                    ]},
                    {ul, [], [
                        {li, [], [
                            {strong, [], [~"Account data "]},
                            ~"- your GitHub username, display name, email address, and avatar, received from GitHub when you sign in (GitHub is your identity provider; we never see your GitHub password). Plus your team membership and role."
                        ]},
                        {li, [], [
                            {strong, [], [~"Contract records "]},
                            ~"- which terms version you accepted, when, and by whom."
                        ]},
                        {li, [], [
                            {strong, [], [~"Billing state "]},
                            ~"- your subscription and payment status, received from Paddle. Paddle is the merchant of record and an independent controller of your purchase and payment data (card details never reach us) - see ",
                            {a, [{href, ~"https://www.paddle.com/legal/privacy"}], [
                                ~"Paddle's privacy policy"
                            ]},
                            ~"."
                        ]},
                        {li, [], [
                            {strong, [], [~"Operational logs "]},
                            ~"- security-relevant console actions, with bounded retention."
                        ]}
                    ]},
                    {p, [], [
                        {strong, [], [~"Lawful bases: "]},
                        ~"performing our contract with you (Art. 6(1)(b) GDPR) for account, contract, and billing data; legal obligations (Art. 6(1)(c), e.g. bookkeeping) for transaction records; and our legitimate interest in securing the service (Art. 6(1)(f)) for logs."
                    ]},
                    {p, [], [
                        {strong, [], [~"Cookies: "]},
                        ~"the console sets strictly necessary session cookies to keep you signed in - nothing else, no tracking. The marketing site still sets none at all."
                    ]},
                    {p, [], [
                        {strong, [], [~"Retention: "]},
                        ~"account data for the life of your account plus the 30-day wind-down; records we must keep under Swedish bookkeeping law for 7 years; logs per their bounded retention windows."
                    ]},
                    {p, [], [
                        ~"Your players' personal data is a separate matter: there the game studio is the controller and we are the processor under the ",
                        {a, [{href, ~"/dpa"}, az_navigate], [~"Data Processing Agreement"]},
                        ~"."
                    ]}
                ]}
            ]}
        ]}
    ).
