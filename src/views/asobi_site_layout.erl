-module(asobi_site_layout).
-include_lib("arizona/include/arizona_stateless.hrl").

-export([render/1]).

-spec render(map()) -> arizona_template:template().
render(Bindings) ->
    Prefix = arizona_nova:prefix(),
    ?html([
        ~"<!DOCTYPE html>",
        {html, [{lang, ~"en"}, az_nodiff], [
            {head, [], [
                {meta, [{charset, ~"UTF-8"}], []},
                {meta, [{name, ~"viewport"}, {content, ~"width=device-width, initial-scale=1.0"}],
                    []},
                {title, [], [maps:get(title, Bindings, ~"Asobi")]},
                {meta,
                    [
                        {name, ~"description"},
                        {content, ~"Open-source multiplayer game backend built on Erlang/OTP."}
                    ],
                    []},
                %% Fonts — self-hosted (Fraunces, Instrument Sans, JetBrains Mono)
                %% via priv/static/assets/fonts. No cross-border requests.
                {link, [{rel, ~"stylesheet"}, {href, ~"/assets/css/fonts.css"}], []},
                {link, [{rel, ~"stylesheet"}, {href, ~"/assets/css/app.css"}], []},
                {link, [{rel, ~"icon"}, {href, ~"/assets/img/favicon.ico"}, {sizes, ~"any"}], []},
                {link,
                    [
                        {rel, ~"icon"},
                        {type, ~"image/png"},
                        {sizes, ~"32x32"},
                        {href, ~"/assets/img/icon-32.png"}
                    ],
                    []},
                {link,
                    [
                        {rel, ~"icon"},
                        {type, ~"image/png"},
                        {sizes, ~"192x192"},
                        {href, ~"/assets/img/icon-192.png"}
                    ],
                    []},
                {link, [{rel, ~"apple-touch-icon"}, {href, ~"/assets/img/icon-180.png"}], []},
                {meta, [{name, ~"theme-color"}, {content, ~"#fbf6ec"}], []},
                {meta, [{property, ~"og:type"}, {content, ~"website"}], []},
                {meta, [{property, ~"og:title"}, {content, maps:get(title, Bindings, ~"Asobi")}],
                    []},
                {meta,
                    [
                        {property, ~"og:description"},
                        {content, ~"Open-source multiplayer game backend built on Erlang/OTP."}
                    ],
                    []},
                {meta, [{property, ~"og:image"}, {content, ~"/assets/img/logo-head.png"}], []},
                {meta, [{name, ~"twitter:card"}, {content, ~"summary_large_image"}], []},
                {meta, [{name, ~"twitter:image"}, {content, ~"/assets/img/logo-head.png"}], []},
                %% Plausible Analytics (Estonia-based, data hosted in EU, no cookies).
                %% Per-site script ID encodes the domain; no `data-domain` attribute.
                {script,
                    [
                        {'async', ~""},
                        {src, ~"https://plausible.io/js/pa-0ZKJIXgHGED3w2z7Fnpd2.js"}
                    ],
                    []},
                {script, [], [
                    ~"window.plausible=window.plausible||function(){(plausible.q=plausible.q||[]).push(arguments)},",
                    ~"plausible.init=plausible.init||function(i){plausible.o=i||{}};",
                    ~"plausible.init();"
                ]}
            ]},
            {body, [], [
                ?inner_content,
                ?stateless(asobi_site_footer, render, #{}),
                {script, [{type, ~"module"}], [
                    ~"import { connect } from '",
                    Prefix,
                    ~"/assets/js/arizona.min.js'; connect('",
                    Prefix,
                    ~"/ws');"
                ]}
            ]}
        ]}
    ]).
