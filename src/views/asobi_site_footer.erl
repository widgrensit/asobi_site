-module(asobi_site_footer).
-include_lib("arizona/include/arizona_stateless.hrl").

-export([render/0]).

-spec render() -> arizona_template:template().
render() ->
    ?html(
        {footer, [{class, ~"site-footer"}], [
            {'div', [{class, ~"footer-inner"}], [
                {'div', [{class, ~"footer-brand"}], [
                    {a, [{href, ~"/"}, {class, ~"footer-brand-link"}], [
                        {img, [
                            {src, ~"/assets/img/logo-mark.png"},
                            {alt, ~""},
                            {class, ~"brand-logo"},
                            {width, ~"56"},
                            {height, ~"56"},
                            {'aria-hidden', ~"true"}
                        ]},
                        {span, [{class, ~"brand-text"}], [~"asobi"]}
                    ]},
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
                        {a, [{href, ~"https://discord.gg/vYSfYYyXpu"}], [~"Discord"]},
                        {a, [{href, ~"/blog"}], [~"Blog"]},
                        {a, [{href, ~"/blog/rss.xml"}], [~"RSS"]}
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
