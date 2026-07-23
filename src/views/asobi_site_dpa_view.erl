-module(asobi_site_dpa_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ~"dpa", title => ~"DPA - Asobi"}, Bindings), #{}}.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {'div', [{class, ~"guide-page"}], [
                {'div', [{class, ~"guide-header"}], [
                    {h1, [], [~"Data Processing Agreement"]},
                    {p, [], [
                        ~"Last updated: 23 July 2026. This DPA forms part of the ",
                        {a, [{href, ~"/cloud-terms"}], [~"Asobi Cloud Terms of Service"]},
                        ~" and applies automatically when you use Asobi Cloud. You (the customer) are the controller of your players' personal data; Widgrensit AB, Sweden, is the processor. If you need a countersigned copy, email ",
                        {a, [{href, ~"mailto:dpa@asobi.dev"}], [~"dpa@asobi.dev"]},
                        ~"."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Scope and duration"]},
                    {p, [], [
                        ~"We process player personal data solely to run your game backend, for as long as your subscription lasts plus the wind-down period below. Categories:"
                    ]},
                    {ul, [], [
                        {li, [], [~"Player accounts, sessions, and identifiers."]},
                        {li, [], [~"Match state, chat, voting, and presence data."]},
                        {li, [], [
                            ~"Wallet / inventory / IAP receipt metadata (not payment card data - IAP is via platform stores; no card data touches Asobi)."
                        ]},
                        {li, [], [~"Aggregated telemetry we need to run the service."]}
                    ]},
                    {p, [], [
                        ~"Your own account and billing data is not covered here: for it we (and Paddle, as merchant of record) act as independent controllers - see the ",
                        {a, [{href, ~"/privacy"}], [~"privacy policy"]},
                        ~"."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Instructions"]},
                    {p, [], [
                        ~"We process player data only on your documented instructions - operating the service as configured by you is the standing instruction - and we tell you if an instruction looks unlawful. Personnel with access are bound by confidentiality."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Sub-processors"]},
                    {p, [], [
                        ~"You authorise the sub-processors below. Any addition will be notified in advance with an objection window."
                    ]},
                    {ul, [], [
                        {li, [], [
                            {strong, [], [~"Hetzner Online "]},
                            ~"(Germany) - compute and S3-compatible object storage; our database runs on this compute (self-managed, no third-party database service)."
                        ]},
                        {li, [], [
                            {strong, [], [~"Equivalent EU provider "]},
                            ~"(Germany, Finland) - fallback compute region if required for capacity."
                        ]},
                        {li, [], [
                            {strong, [], [~"Apple / Google "]},
                            ~"(US) - ",
                            {em, [], [~"only"]},
                            ~" for in-app purchase receipt validation at the platforms that run your game. This is a lawful necessity for validating purchases; no player PII leaves the EU through this path beyond what Apple/Google already hold for their own billing."
                        ]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Location"]},
                    {p, [], [
                        ~"All regular processing in the EU. Primary region: Hetzner, Germany. Backups remain in the EU."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Security"]},
                    {ul, [], [
                        {li, [], [~"TLS 1.2+ in transit."]},
                        {li, [], [~"At-rest encryption for Postgres and object storage."]},
                        {li, [], [~"Role-based access for operators; all access logged."]},
                        {li, [], [
                            ~"Erlang/OTP process isolation - one crashed match cannot read another match's state."
                        ]},
                        {li, [], [
                            ~"Personal data is kept out of operational logs by design; log streams have bounded retention."
                        ]},
                        {li, [], [
                            ~"Breach notification: without undue delay and within 72 hours of discovery, per GDPR Art. 33."
                        ]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Assistance and audits"]},
                    {p, [], [
                        ~"We assist you with data-subject requests (export and erasure of a player's data on your instruction) and with your GDPR Art. 32-36 obligations. We make available the information needed to demonstrate compliance and allow audits, normally satisfied by documentation; on-site audits are by arrangement, at your cost, no more than annually unless a breach occurred."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Data export and deletion"]},
                    {ul, [], [
                        {li, [], [
                            ~"Player-level export and erasure on request (forwarded from controller to processor)."
                        ]},
                        {li, [], [
                            ~"Account-level: at end of contract, data is returned in a portable format and deleted within 30 days."
                        ]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Standard Contractual Clauses"]},
                    {p, [], [
                        ~"Where any transfer to a non-adequate country would occur (currently limited to IAP receipt validation, which is initiated by the platforms themselves), we rely on the EU Commission's SCCs per ",
                        {a, [{href, ~"https://eur-lex.europa.eu/eli/dec_impl/2021/914/oj"}], [
                            ~"Decision 2021/914"
                        ]},
                        ~"."
                    ]}
                ]}
            ]}
        ]}
    ).
