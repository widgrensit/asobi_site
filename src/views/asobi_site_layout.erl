-module(asobi_site_layout).
-include_lib("arizona/include/arizona_stateless.hrl").

-export([render/1]).

-spec render(map()) -> term().
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
                {link, [{rel, ~"stylesheet"}, {href, ~"/assets/css/app.css"}], []},
                {link, [{rel, ~"icon"}, {href, ~"/assets/favicon.ico"}], []},
                %% Plausible Analytics (Estonia-based, data hosted in EU, no cookies).
                %% `data-domain` must match the domain Plausible is configured for.
                {script,
                    [
                        {defer, ~""},
                        {'data-domain', ~"asobi.dev"},
                        {src, ~"https://plausible.io/js/script.js"}
                    ],
                    []}
            ]},
            {body, [], [
                ?inner_content,
                {script, [{type, ~"module"}], [
                    <<"import { connect } from '">>,
                    Prefix,
                    <<"/assets/js/arizona.min.js'; connect('">>,
                    Prefix,
                    <<"/ws');">>
                ]}
            ]}
        ]}
    ]).
