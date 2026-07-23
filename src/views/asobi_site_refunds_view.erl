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
                        ~"Last updated: 23 July 2026. This policy applies to Asobi Cloud subscriptions. Payments are processed by Paddle as merchant of record; approved refunds are issued by Paddle to your original payment method."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"First payment"]},
                    {p, [], [
                        ~"If Asobi Cloud isn't for you, we refund your first subscription payment in full when you ask within 14 days of it - no questions asked."
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
                        ~"Duplicate or incorrect charges are refunded in full. If a material outage on our side kept your environment down for an extended period, contact us and we will put it right - typically with a credit or partial refund for the affected period."
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
