%% Guards for the Markdown twin of every page (llmstxt.org v2).
%%
%% The failure this suite exists to prevent is silent content loss. Unknown
%% tags unwrap to their children rather than crashing, which is the right
%% behaviour in prod and the wrong one to leave unwatched: a page could quietly
%% lose a table or a code sample and nothing would ever say so, because almost
%% nobody reads these files by eye.
%%
%% Route and view helpers live in asobi_site_pages, not here.
-module(asobi_site_markdown_SUITE).
-compile([export_all, nowarn_export_all]).

-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").

-define(MD, ~"text/markdown; charset=utf-8").

all() ->
    [
        every_page_has_a_markdown_twin,
        renders_every_markdown_route,
        no_unknown_tags,
        generated_views_serve_their_guide,
        links_are_absolute,
        no_markup_survives,
        code_blocks_are_fenced,
        formats_a_representative_tree
    ].

rendered() ->
    [
        {element(1, R), asobi_site_pages:body(element(1, R), ?MD)}
     || R <- asobi_site_pages:md_routes()
    ].

%% Every routed page except the dynamic blog-post template, whose path carries
%% a cowboy binding and so cannot take a suffix.
every_page_has_a_markdown_twin(_Config) ->
    Paths = asobi_site_pages:paths(),
    Pages = [
        P
     || P <- Paths,
        is_binary(P),
        not asobi_site_pages:is_md(P),
        not lists:member(P, asobi_site_pages:not_a_page())
    ],
    Missing = [P || P <- Pages, not lists:member(asobi_site_pages:md_path(P), Paths)],
    ?assertEqual([], Missing),
    ?assert(length(asobi_site_pages:md_routes()) >= 90).

%% A page that renders to almost nothing has lost its content to a tag rule,
%% which is exactly the failure the walker must not have.
renders_every_markdown_route(_Config) ->
    Thin = [P || {P, Body} <- rendered(), byte_size(Body) < 200],
    ?assertEqual([], Thin).

%% The load-bearing one. Walk every view's tree and fail on a tag
%% asobi_site_markdown has not been taught, so a new tag is a deliberate
%% decision rather than content that silently stops appearing.
no_unknown_tags(_Config) ->
    Known = asobi_site_markdown:known_tags(),
    Unknown = lists:usort(
        lists:flatten([
            [
                {View, T}
             || T <- asobi_site_markdown:tags(asobi_site_pages:tree(View)),
                not lists:member(T, Known)
            ]
         || View <- asobi_site_pages:views()
        ])
    ),
    ?assertEqual([], Unknown).

generated_views_serve_their_guide(_Config) ->
    Generated = generated(),
    ?assertEqual(32, length(Generated)),
    [
        begin
            Md = V:markdown(),
            ?assertMatch(<<"# ", _/binary>>, Md),
            %% The guide source, not a conversion of the rendered HTML.
            ?assertEqual(nomatch, binary:match(Md, ~"<p>")),
            %% Cross-links were rewritten; nothing repo-relative survives.
            ?assertEqual(nomatch, binary:match(Md, ~"](../")),
            ?assertEqual(nomatch, binary:match(Md, ~"<!-- tabs -->"))
        end
     || V <- Generated
    ].

generated() ->
    [V || V <- asobi_site_pages:views(), erlang:function_exported(V, markdown, 0)].

%% Read out of band, a site-relative link cannot be resolved.
links_are_absolute(_Config) ->
    Bad = [P || {P, Body} <- rendered(), nomatch =/= binary:match(Body, ~"](/")],
    ?assertEqual([], Bad).

%% A soft failure mode: the walker meets a tag it renders as text and ships raw
%% markup, or a double-escaped entity reaches the reader verbatim. Generated
%% pages are exempt: they carry the guide verbatim, and a guide may legitimately
%% show markup inside a fenced sample.
no_markup_survives(_Config) ->
    Markup = [~"<p>", ~"<div", ~"<span", ~"<code>", ~"</a>", ~"&amp;", ~"&quot;", ~"&lt;"],
    Guides = [V:markdown() || V <- generated()],
    Bad = [
        P
     || {P, Body} <- rendered(),
        not lists:member(string:trim(Body, both, "\n"), Guides),
        nomatch =/= binary:match(Body, Markup)
    ],
    ?assertEqual([], Bad).

%% Every fence opens and closes. An odd count means a sample swallowed the rest
%% of the page.
code_blocks_are_fenced(_Config) ->
    Odd = [P || {P, Body} <- rendered(), length(binary:matches(Body, ~"\n```")) rem 2 =/= 0],
    ?assertEqual([], Odd).

%% A worked example, so the rules are pinned rather than merely exercised.
formats_a_representative_tree(_Config) ->
    Tree =
        {'div', [], [
            {h1, [], [~"Title"]},
            {p, [{class, ~"docs-breadcrumb"}], [~"Docs / Thing"]},
            {p, [], [
                {strong, [], [~"Note: "]},
                ~"see the ",
                {a, [{href, ~"/docs/faq"}, az_navigate], [~"FAQ"]},
                ~" and ",
                {code, [], [~"match.lua"]},
                ~"."
            ]},
            {ul, [], [{li, [], [~"one"]}, {li, [], [~"two"]}]},
            {pre, [], [{code, [{class, ~"language-lua"}], [~"function tick(s) return s end"]}]},
            {table, [], [
                {thead, [], [{tr, [], [{th, [], [~"A"]}, {th, [], [~"B"]}]}]},
                {tbody, [], [{tr, [], [{td, [], [~"1"]}, {td, [], [~"2|3"]}]}]}
            ]},
            {'div', [{class, ~"docs-callout docs-callout-info"}], [{p, [], [~"Careful."]}]}
        ]},
    Expected =
        ~"""
        # Title

        **Note:** see the [FAQ](https://asobi.dev/docs/faq) and `match.lua`.

        - one
        - two

        ```lua
        function tick(s) return s end
        ```

        | A | B |
        | --- | --- |
        | 1 | 2\|3 |

        > Careful.
        """,
    ?assertEqual(
        Expected, string:trim(iolist_to_binary(asobi_site_markdown:render(Tree)), trailing, "\n")
    ).
