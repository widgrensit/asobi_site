-module(asobi_site_footer).
-include_lib("arizona/include/arizona_stateless.hrl").

-export([render/1]).

-spec render(az:bindings()) -> az:template().
render(_Bindings) ->
    ?html(
        {footer, [{class, ~"site-footer"}], [
            {'div', [{class, ~"footer-inner"}], [
                {'div', [{class, ~"footer-brand"}], [
                    {a, [{href, ~"/"}, {class, ~"footer-brand-link"}], [
                        {img, [
                            {src, ~"/assets/img/logo-full.png"},
                            {alt, ~"Asobi"},
                            {class, ~"brand-logo"}
                        ]}
                    ]},
                    {p, [{class, ~"footer-tagline"}], [
                        ~"Open-source game backend on Erlang/OTP."
                    ]}
                ]},
                {'div', [{class, ~"footer-links"}], [
                    {'div', [{class, ~"footer-col"}], [
                        {h4, [], [~"Product"]},
                        {a, [{href, ~"/"}, az_navigate], [~"Home"]},
                        {a, [{href, ~"/cloud"}, az_navigate], [~"Cloud"]},
                        {a, [{href, ~"/demo"}, az_navigate], [~"Demo"]},
                        {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]}
                    ]},
                    {'div', [{class, ~"footer-col"}], [
                        {h4, [], [~"Community"]},
                        {a, [{href, ~"https://github.com/widgrensit/asobi"}], [~"GitHub"]},
                        {a, [{href, ~"https://discord.gg/vYSfYYyXpu"}], [~"Discord"]},
                        {a, [{href, ~"/blog"}, az_navigate], [~"Blog"]},
                        {a, [{href, ~"/blog/rss.xml"}], [~"RSS"]}
                    ]},
                    {'div', [{class, ~"footer-col"}], [
                        {h4, [], [~"Legal"]},
                        {a, [{href, ~"/terms"}, az_navigate], [~"Terms"]},
                        {a, [{href, ~"/privacy"}, az_navigate], [~"Privacy"]},
                        {a, [{href, ~"/dpa"}, az_navigate], [~"DPA"]}
                    ]}
                ]}
            ]},
            {'div', [{class, ~"footer-bottom"}], [
                {p, [], [~"Apache 2.0 \x{2014} Widgrensit AB, Sweden"]}
            ]}
        ]}
    ).
