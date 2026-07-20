-module(asobi_site_docs_changelog_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(
            #{id => ~"docs-changelog", title => ~"Changelog & releases — Asobi docs"},
            Bindings
        ),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Changelog"
            ]},
            {h1, [], [~"Changelog &amp; releases"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Asobi releases continuously - every change that lands on ",
                {code, [], [~"main"]},
                ~" is tagged and published, so the version number moves often and each release is small ",
                ~"and reversible."
            ]},

            {h2, [], [~"Where to read it"]},
            {p, [], [
                ~"The canonical, always-current changelog is the GitHub releases page - each entry has ",
                ~"its notes and the exact diff:"
            ]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"https://github.com/widgrensit/asobi/releases"}], [
                        ~"github.com/widgrensit/asobi/releases"
                    ]}
                ]},
                {li, [], [
                    ~"SDKs and tools tag their own releases in their respective repos under ",
                    {a, [{href, ~"https://github.com/widgrensit"}], [~"github.com/widgrensit"]},
                    ~"."
                ]}
            ]},

            {h2, [], [~"Versioning"]},
            {p, [], [
                ~"Asobi follows semantic versioning while pre-1.0: minor bumps can carry breaking changes, ",
                ~"which are called out in the release notes. Pin a tag in your ",
                {code, [], [~"rebar.config"]},
                ~" (or your SDK's lockfile) and upgrade deliberately. See ",
                {a, [{href, ~"/docs/exit"}, az_navigate], [~"No lock-in"]},
                ~" for how upgrades and downgrades stay in your control."
            ]}
        ]}
    ).
