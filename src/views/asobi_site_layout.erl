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
                %% Fonts — preconnect then stylesheet for fastest paint.
                {link, [{rel, ~"preconnect"}, {href, ~"https://fonts.googleapis.com"}], []},
                {link,
                    [
                        {rel, ~"preconnect"},
                        {href, ~"https://fonts.gstatic.com"},
                        {crossorigin, ~""}
                    ],
                    []},
                {link,
                    [
                        {rel, ~"stylesheet"},
                        {href,
                            ~"https://fonts.googleapis.com/css2?family=Fraunces:ital,opsz,wght,SOFT@0,9..144,300..900,0..100;1,9..144,300..900,0..100&family=Instrument+Sans:ital,wght@0,400..700;1,400..700&family=JetBrains+Mono:ital,wght@0,400..700;1,400..700&display=swap"}
                    ],
                    []},
                {link, [{rel, ~"stylesheet"}, {href, ~"/assets/css/app.css"}], []},
                {link, [{rel, ~"icon"}, {href, ~"/assets/favicon.ico"}], []},
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
