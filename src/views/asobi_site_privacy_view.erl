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
                        ~"Widgrens IT AB, org.nr 559241-2752, Uppsala, Sweden. Contact: ",
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

                    {h3, [], [~"Beta signup form"]},
                    {p, [], [
                        ~"The /cloud page links out to a ",
                        {strong, [], [~"Tally"]},
                        ~" form (Belgian company, EU-hosted) for the Asobi Cloud beta waitlist. If you choose to submit it we collect: email, studio or project name, target engine, development stage, current backend, and an optional free-text description."
                    ]},
                    {p, [], [
                        {strong, [], [~"Lawful basis: "]},
                        ~"performance of pre-contract steps you asked for (Art. 6(1)(b)) and/or consent (Art. 6(1)(a)). We use this information only to contact you about the beta and onboarding. We do not share it with advertisers, brokers, or any third party outside the processors listed below."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Where data lives"]},
                    {p, [], [
                        ~"Everything is in the EU. The processors we use:"
                    ]},
                    {ul, [], [
                        {li, [], [
                            {strong, [], [~"Hetzner "]},
                            ~"(Germany) - website hosting."
                        ]},
                        {li, [], [
                            {strong, [], [~"Plausible Analytics "]},
                            ~"(Estonia, servers in the EU) - aggregate analytics."
                        ]},
                        {li, [], [
                            {strong, [], [~"Tally "]},
                            ~"(Belgium) - beta signup form, via link-out (no embed on asobi.dev)."
                        ]}
                    ]},
                    {p, [], [
                        ~"There are no Google, Cloudflare, AWS, or other non-EU services in the user-facing request path. Fonts are self-hosted."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Cookies and local storage"]},
                    {p, [], [
                        ~"The site sets ",
                        {strong, [], [~"no cookies"]},
                        ~" and writes nothing to localStorage or sessionStorage. No cookie banner is shown because there is nothing to consent to."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Retention"]},
                    {ul, [], [
                        {li, [], [
                            ~"Analytics: retained by Plausible for the lifetime of our account (no raw identifiers kept - the daily hash cannot be reversed beyond 24 hours)."
                        ]},
                        {li, [], [
                            ~"Beta form submissions: retained until the Asobi Cloud beta ends, or sooner on request."
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
