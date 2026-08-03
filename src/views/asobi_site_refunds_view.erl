-module(asobi_site_refunds_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"refunds", title => ~"Refund Policy - Asobi"}, Bindings), #{}}.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {'div', [{class, ~"guide-page"}], [
                {'div', [{class, ~"guide-header"}], [
                    {h1, [], [~"Refund Policy"]},
                    {p, [], [
                        ~"Last updated: 25 July 2026. This policy applies to Asobi Cloud subscriptions. Payments are processed by Paddle as merchant of record; approved refunds are issued by Paddle to your original payment method."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Provider"]},
                    {p, [], [
                        ~"Asobi Cloud is operated by Widgrens IT AB, org.nr 559241-2752, Melongatan 15, 754 49 Uppsala, Sweden. VAT no. SE559241275201. Contact: ",
                        {a, [{href, ~"mailto:legal@asobi.dev"}], [~"legal@asobi.dev"]},
                        ~"."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"First payment"]},
                    {p, [], [
                        ~"If Asobi Cloud isn't for you, we refund your first subscription payment in full when you ask within 14 days of it - no questions asked. This applies once per account, to the first payment for your first environment, whatever its size."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Renewals and cancellation"]},
                    {p, [], [
                        ~"Subscriptions renew monthly. Cancel any time from the billing portal; cancellation takes effect at the end of the current billing period, and we do not issue partial refunds for unused time. If a renewal charged when you had already cancelled, we refund it."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Billing errors and outages"]},
                    {p, [], [
                        ~"Duplicate or incorrect charges are refunded in full. If a fault on our side kept your environment unavailable for more than 24 cumulative hours in a calendar month, contact us and we will put it right - with a credit or partial refund proportionate to the downtime, at minimum. Shorter interruptions (maintenance, deploys) are part of normal operation and not refundable."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"How to request a refund"]},
                    {p, [], [
                        ~"Reply to your Paddle receipt, or email ",
                        {a, [{href, ~"mailto:billing@asobi.dev"}], [~"billing@asobi.dev"]},
                        ~" with your account email and the transaction reference. Refund timing to your payment method is per Paddle's processing times."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Statutory rights"]},
                    {p, [], [
                        ~"Nothing in this policy limits rights you have under applicable law."
                    ]}
                ]}
            ]}
        ]}
    ).
