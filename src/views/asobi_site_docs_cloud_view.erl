-module(asobi_site_docs_cloud_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(#{id => ~"docs-cloud", title => ~"Cloud — Asobi docs"}, Bindings),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Cloud"
            ]},
            {h1, [], [~"Cloud hosting"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Managed Asobi is live at ",
                {a, [{href, ~"https://console.asobi.dev"}], [~"console.asobi.dev"]},
                ~". Sign up, create an environment, and deploy your Lua with the ",
                {code, [], [~"asobi"]},
                ~" CLI. EU-hosted, open-source core so you can self-host any time."
            ]},

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"The golden path. "]},
                    ~"Sign in on the console, run ",
                    {code, [], [~"asobi login"]},
                    ~", then ",
                    {code, [], [~"asobi create prod"]},
                    ~" and ",
                    {code, [], [~"asobi deploy prod game/"]},
                    ~". See the ",
                    {a, [{href, ~"/docs/quickstart"}, az_navigate], [~"quick start"]},
                    ~" for the full walk-through."
                ]}
            ]},

            {'div', [{class, ~"docs-cta-row"}], [
                {a, [{href, ~"https://console.asobi.dev"}, {class, ~"btn btn-primary"}], [
                    ~"Open the console \x{2192}"
                ]},
                {a, [{href, ~"/docs/self-host"}, {class, ~"btn btn-secondary"}, az_navigate], [
                    ~"Or self-host"
                ]}
            ]}
        ]}
    ).
