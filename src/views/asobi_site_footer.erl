-module(asobi_site_footer).
-include_lib("arizona/include/arizona_stateless.hrl").

-export([render/0]).

-spec render() -> arizona_template:template().
render() ->
    ?html(
        {footer, [{class, ~"site-footer"}], [
            {'div', [{class, ~"footer-inner"}], [
                {'div', [{class, ~"footer-brand"}], [
                    {img,
                        [
                            {src, ~"/assets/img/tanuki.png"},
                            {alt, ~"asobi"},
                            {class, ~"brand-logo brand-logo-lg"},
                            {width, ~"56"},
                            {height, ~"56"}
                        ],
                        []},
                    {span, [{class, ~"brand-text"}], [~"asobi"]},
                    {p, [{class, ~"footer-tagline"}], [
                        ~"Open-source game backend on Erlang/OTP."
                    ]}
                ]},
                {'div', [{class, ~"footer-links"}], [
                    {'div', [{class, ~"footer-col"}], [
                        {h4, [], [~"Product"]},
                        {a, [{href, ~"/"}], [~"Home"]},
                        {a, [{href, ~"/cloud"}], [~"Cloud"]},
                        {a, [{href, ~"/demo"}], [~"Demo"]},
                        {a, [{href, ~"/docs"}], [~"Docs"]}
                    ]},
                    {'div', [{class, ~"footer-col"}], [
                        {h4, [], [~"Community"]},
                        {a, [{href, ~"https://github.com/widgrensit/asobi"}], [~"GitHub"]},
                        {a, [{href, ~"https://discord.gg/vYSfYYyXpu"}], [~"Discord"]}
                    ]},
                    {'div', [{class, ~"footer-col"}], [
                        {h4, [], [~"Legal"]},
                        {a, [{href, ~"/terms"}], [~"Terms"]},
                        {a, [{href, ~"/privacy"}], [~"Privacy"]},
                        {a, [{href, ~"/dpa"}], [~"DPA"]}
                    ]}
                ]}
            ]},
            {'div', [{class, ~"footer-bottom"}], [
                {p, [], [~"Apache 2.0 \x{2014} Widgrensit AB, Sweden"]}
            ]}
        ]}
    ).
