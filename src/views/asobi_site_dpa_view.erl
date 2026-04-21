-module(asobi_site_dpa_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {maps:merge(#{id => ~"dpa", title => ~"DPA \x{2014} Asobi"}, Bindings), #{}}.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {'div', [{class, ~"guide-page"}], [
                {'div', [{class, ~"guide-header"}], [
                    {h1, [], [~"Data Processing Agreement"]},
                    {p, [], [
                        ~"A DPA covers us acting as a ",
                        {em, [], [~"processor"]},
                        ~" for your player/user data. This page summarises what the Asobi Cloud DPA will contain; the marketing site you are reading now doesn't process your user data and doesn't need a DPA."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"When this applies"]},
                    {p, [], [
                        ~"Only when you host your game on ",
                        {strong, [], [~"Asobi Cloud"]},
                        ~" (currently in closed beta). At that point you are the controller of your players' personal data; Widgrensit AB is the processor, handling storage and real-time traffic on your behalf."
                    ]},
                    {p, [], [
                        ~"If you self-host the open-source Asobi library, you remain the sole controller and processor \x{2014} no DPA is needed with us because we never see your data."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Scope"]},
                    {ul, [], [
                        {li, [], [~"Player accounts, sessions, and identifiers."]},
                        {li, [], [~"Match state, chat, voting, and presence data."]},
                        {li, [], [
                            ~"Wallet / inventory / IAP receipt metadata (not payment card data \x{2014} IAP is via platform stores; no card data touches Asobi)."
                        ]},
                        {li, [], [~"Aggregated telemetry we need to run the service."]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Sub-processors"]},
                    {p, [], [
                        ~"EU-only, minimal list. Any addition will be notified in advance with an objection window."
                    ]},
                    {ul, [], [
                        {li, [], [
                            {strong, [], [~"Clever Cloud "]},
                            ~"(France) \x{2014} compute, managed Postgres, S3-compatible object storage."
                        ]},
                        {li, [], [
                            {strong, [], [~"Hetzner or equivalent EU provider "]},
                            ~"(Germany, Finland) \x{2014} fallback compute region if required for capacity."
                        ]},
                        {li, [], [
                            {strong, [], [~"Apple / Google "]},
                            ~"(US) \x{2014} ",
                            {em, [], [~"only"]},
                            ~" for in-app purchase receipt validation at the platforms that run your game. This is a lawful necessity for validating purchases; no player PII leaves the EU through this path beyond what Apple/Google already hold for their own billing."
                        ]}
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Location"]},
                    {p, [], [
                        ~"All regular processing in the EU. Primary region: Clever Cloud Paris. Backups remain in the EU."
                    ]}
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Security"]},
                    {ul, [], [
                        {li, [], [~"TLS 1.2+ in transit."]},
                        {li, [], [~"At-rest encryption for Postgres and object storage."]},
                        {li, [], [~"Role-based access for operators; all access logged."]},
                        {li, [], [
                            ~"Erlang/OTP process isolation \x{2014} one crashed match cannot read another match's state."
                        ]},
                        {li, [], [
                            ~"Breach notification: within 72 hours of discovery, per GDPR Art. 33."
                        ]}
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
                ]},

                {'div', [{class, ~"guide-section"}], [
                    {h2, [], [~"Request a copy of the draft DPA"]},
                    {p, [], [
                        ~"Beta participants and evaluators can email ",
                        {a, [{href, ~"mailto:dpa@asobi.dev"}], [~"dpa@asobi.dev"]},
                        ~". The finalised, countersignable DPA will publish here when Asobi Cloud enters general availability."
                    ]}
                ]}
            ]}
        ]}
    ).
