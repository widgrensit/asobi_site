-module(asobi_site_docs_coming_soon_view).
-include_lib("arizona/include/arizona_stateless.hrl").

%% Shared "coming soon" page for docs routes whose content isn't written yet.
%% Each wrapper view calls render_with/4 with its title, breadcrumb, active
%% sidebar path, and an external guide URL to send readers to meanwhile.

-export([render_with/4]).

-spec render_with(binary(), binary(), binary(), [binary()]) -> arizona_template:template().
render_with(ActivePath, Title, Blurb, GuideLinks) ->
    Links = [guide_link(L) || L <- GuideLinks],
    Content = ?html(
        {'div', [], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}], [~"Docs"]},
                ~" / ",
                Title
            ]},
            {h1, [], [Title]},
            {p, [{class, ~"docs-lede"}], [Blurb]},

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"This page is coming soon. "]},
                    ~"In the meantime, the material is covered in the asobi repo guides:"
                ]},
                {ul, [], Links}
            ]},

            {p, [], [
                ~"Want to help? ",
                {a,
                    [
                        {href, ~"https://github.com/widgrensit/asobi_site/issues/new"}
                    ],
                    [~"Open an issue"]},
                ~" with what you'd most like to see here, or ",
                {a, [{href, ~"https://discord.gg/vYSfYYyXpu"}], [~"ask in Discord"]},
                ~"."
            ]}
        ]}
    ),
    asobi_site_docs_shell:render(ActivePath, Content).

guide_link(Url) ->
    ?html({li, [], [{a, [{href, Url}], [Url]}]}).
