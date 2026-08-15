-module(asobi_site_controller).

-export([
    page/2,
    markdown/2,
    moved/2,
    heartbeat/1,
    blog_rss/1,
    llms_txt/1,
    robots_txt/1,
    sitemap_xml/1
]).

-define(SITE, ~"https://asobi.dev").

-spec page(cowboy_req:req(), map()) -> {status, 200, map(), iodata()}.
page(Req, Spec) ->
    View = maps:get(view, Spec),
    DocView = maps:get(doc_view, Spec, undefined),
    Bindings = #{
        id => ~"page",
        view => View,
        view_id => atom_to_binary(View, utf8),
        active => maps:get(active, Spec, none),
        slug => slug(Req),
        doc_view => DocView,
        doc_view_id => doc_view_id(DocView),
        active_path => maps:get(active_path, Spec, ~"")
    },
    Content = asobi_site_page:render(Bindings),
    Document = asobi_site_layout:render(#{title => page_title(Bindings), inner_content => Content}),
    Headers = #{~"content-type" => ~"text/html; charset=utf-8"},
    {status, 200, Headers, asobi_site_html:document(Document)}.

%% The .md twin of a page (llmstxt.org v2). Two sources, and which one applies
%% is a property of the view, not a decision made here:
%%
%%   - A generated docs view exports markdown/0 holding the asobi guide it was
%%     built from. Its render/1 body is one opaque {raw, Html} node, so the
%%     tree walker cannot read it - and does not need to, because that HTML was
%%     rendered from exactly this markdown.
%%   - Every other view is a tuple tree all the way down, which
%%     asobi_site_markdown walks directly.
%%
%% ensure_loaded before function_exported for the same reason render_view/2
%% does it: under the release's embedded code loading, function_exported/3
%% answers false for a module that has not been loaded yet.
-spec markdown(cowboy_req:req(), map()) -> {status, integer(), map(), iodata()}.
markdown(_Req, #{view := View}) ->
    _ = code:ensure_loaded(View),
    Body =
        case erlang:function_exported(View, markdown, 0) of
            true -> [View:markdown(), ~"\n"];
            false -> asobi_site_markdown:render(asobi_site_html:render_view(View, #{id => ~"page"}))
        end,
    Headers = #{~"content-type" => ~"text/markdown; charset=utf-8"},
    {status, 200, Headers, Body}.

slug(Req) ->
    maps:get(~"slug", maps:get(bindings, Req, #{}), ~"").

doc_view_id(undefined) -> ~"";
doc_view_id(DocView) -> atom_to_binary(DocView, utf8).

page_title(#{slug := Slug}) when Slug =/= ~"" ->
    case asobi_site_blog_posts:by_slug(Slug) of
        {ok, #{title := Title}} -> <<Title/binary, " - Asobi">>;
        _ -> ~"Asobi"
    end;
page_title(_Bindings) ->
    ~"Asobi".

%% The empty body matters: nova's 3-tuple `{status, Code, Headers}` renders a
%% status page, which would ship an HTML body under a redirect.
-spec moved(cowboy_req:req(), map()) -> {status, 301, map(), binary()}.
moved(_Req, #{location := Location}) ->
    {status, 301, #{~"location" => Location}, ~""}.

-spec heartbeat(cowboy_req:req()) -> {status, integer()}.
heartbeat(_Req) ->
    {status, 200}.

-spec blog_rss(cowboy_req:req()) ->
    {status, integer(), map(), iodata()}.
blog_rss(_Req) ->
    Posts = asobi_site_blog_posts:all(),
    Body = render_rss(Posts),
    Headers = #{~"content-type" => ~"application/rss+xml; charset=utf-8"},
    {status, 200, Headers, Body}.

render_rss(Posts) ->
    Items = [render_item(P) || P <- Posts],
    [#{date := LatestDate} | _] = Posts,
    LastBuild = rfc822_date(LatestDate),
    [
        ~"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n",
        ~"<rss version=\"2.0\" xmlns:atom=\"http://www.w3.org/2005/Atom\">\n",
        ~"<channel>\n",
        ~"<title>Asobi blog</title>\n",
        ~"<link>https://asobi.dev/blog</link>\n",
        ~"<atom:link href=\"https://asobi.dev/blog/rss.xml\" rel=\"self\" type=\"application/rss+xml\" />\n",
        ~"""
        <description>Engineering notes and devlogs from the team building Asobi — an open-source game backend on Erlang/OTP.</description>
        """,
        ~"\n<language>en</language>\n",
        ~"<lastBuildDate>",
        LastBuild,
        ~"</lastBuildDate>\n",
        Items,
        ~"</channel>\n",
        ~"</rss>\n"
    ].

render_item(#{slug := Slug, title := Title, lede := Lede, date := Date, tags := Tags}) ->
    Url = iolist_to_binary([~"https://asobi.dev/blog/", Slug]),
    Categories = [[~"<category>", xml_escape(T), ~"</category>\n"] || T <- Tags],
    [
        ~"<item>\n",
        ~"<title>",
        xml_escape(Title),
        ~"</title>\n",
        ~"<link>",
        Url,
        ~"</link>\n",
        ~"<guid isPermaLink=\"true\">",
        Url,
        ~"</guid>\n",
        ~"<pubDate>",
        rfc822_date(Date),
        ~"</pubDate>\n",
        ~"<description>",
        xml_escape(Lede),
        ~"</description>\n",
        Categories,
        ~"</item>\n"
    ].

rfc822_date(<<Y:4/binary, "-", M:2/binary, "-", D:2/binary>>) ->
    Year = binary_to_integer(Y),
    Month = binary_to_integer(M),
    Day = binary_to_integer(D),
    DayOfWeek = calendar:day_of_the_week(Year, Month, Day),
    WeekdayName = weekday_name(DayOfWeek),
    MonthName = month_name(Month),
    iolist_to_binary(
        io_lib:format("~s, ~2..0B ~s ~B 00:00:00 +0000", [
            WeekdayName, Day, MonthName, Year
        ])
    ).

weekday_name(1) -> "Mon";
weekday_name(2) -> "Tue";
weekday_name(3) -> "Wed";
weekday_name(4) -> "Thu";
weekday_name(5) -> "Fri";
weekday_name(6) -> "Sat";
weekday_name(7) -> "Sun".

month_name(1) -> "Jan";
month_name(2) -> "Feb";
month_name(3) -> "Mar";
month_name(4) -> "Apr";
month_name(5) -> "May";
month_name(6) -> "Jun";
month_name(7) -> "Jul";
month_name(8) -> "Aug";
month_name(9) -> "Sep";
month_name(10) -> "Oct";
month_name(11) -> "Nov";
month_name(12) -> "Dec".

%% /llms.txt - https://llmstxt.org. A curated index for coding agents, not a
%% crawler hint: Google documents that Search ignores this file entirely.
%% Content lives in asobi_site_llms; this only formats it.
-spec llms_txt(cowboy_req:req()) -> {status, integer(), map(), iodata()}.
llms_txt(_Req) ->
    Headers = #{~"content-type" => ~"text/plain; charset=utf-8"},
    {status, 200, Headers, render_llms()}.

render_llms() ->
    [
        ~"# asobi\n\n",
        [[~"> ", Line, ~"\n"] || Line <- asobi_site_llms:summary()],
        ~"\nNotes for agents:\n\n",
        [[~"- ", Note, ~"\n"] || Note <- asobi_site_llms:notes()],
        [render_llms_section(S) || S <- asobi_site_llms:sections()]
    ].

render_llms_section({Heading, Entries}) ->
    [
        ~"\n## ",
        Heading,
        ~"\n\n",
        %% Link the Markdown variant, not the HTML page: an index is only
        %% worth as much as the thing it points at is worth parsing.
        [
            [~"- [", Title, ~"](", ?SITE, Path, ~".md): ", Description, ~"\n"]
         || {Path, Title, Description} <- Entries
        ]
    ].

%% /robots.txt. Deliberately permissive: the only job it does here is point
%% crawlers at the sitemap, which is the one file search engines document
%% consuming. Declaring an AI-training policy is a separate decision.
-spec robots_txt(cowboy_req:req()) -> {status, integer(), map(), iodata()}.
robots_txt(_Req) ->
    Headers = #{~"content-type" => ~"text/plain; charset=utf-8"},
    Body = [
        ~"User-agent: *\n",
        ~"Allow: /\n\n",
        ~"Sitemap: ",
        ?SITE,
        ~"/sitemap.xml\n"
    ],
    {status, 200, Headers, Body}.

%% /sitemap.xml. Derived from the router rather than a second hand-kept list,
%% so a page cannot be added to the site and silently miss the sitemap.
-spec sitemap_xml(cowboy_req:req()) -> {status, integer(), map(), iodata()}.
sitemap_xml(_Req) ->
    Headers = #{~"content-type" => ~"application/xml; charset=utf-8"},
    {status, 200, Headers, render_sitemap()}.

render_sitemap() ->
    [
        ~"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n",
        ~"<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n",
        [sitemap_url(P, undefined) || P <- sitemap_paths()],
        [
            sitemap_url(<<"/blog/", Slug/binary>>, Date)
         || #{slug := Slug, date := Date} <- asobi_site_blog_posts:all()
        ],
        ~"</urlset>\n"
    ].

sitemap_url(Path, Date) ->
    LastMod =
        case Date of
            undefined -> [];
            _ -> [~"<lastmod>", Date, ~"</lastmod>"]
        end,
    [~"<url><loc>", ?SITE, xml_escape(Path), ~"</loc>", LastMod, ~"</url>\n"].

sitemap_paths() ->
    [#{routes := Routes}] = asobi_site_router:routes(prod),
    Paths = [element(1, R) || R <- Routes],
    lists:sort([
        P
     || P <- Paths, is_binary(P), not lists:member(P, non_pages()), not is_markdown(P)
    ]).

%% The .md twin is an alternate representation of a page, not a second page.
%% Listing both would ask every crawler to index the same content twice.
is_markdown(Path) -> binary:longest_common_suffix([Path, ~".md"]) =:= 3.

%% Routed, but not a page a crawler should index: a health probe, a feed, the
%% dynamic blog template (expanded per post above), a 301, and the machine
%% files themselves.
non_pages() ->
    [
        ~"/heartbeat",
        ~"/blog/rss.xml",
        ~"/blog/:slug",
        ~"/docs/erlang/getting-started",
        ~"/llms.txt",
        ~"/robots.txt",
        ~"/sitemap.xml"
    ].

xml_escape(Bin) when is_binary(Bin) ->
    binary:replace(
        binary:replace(
            binary:replace(
                binary:replace(
                    binary:replace(Bin, ~"&", ~"&amp;", [global]),
                    ~"<",
                    ~"&lt;",
                    [global]
                ),
                ~">",
                ~"&gt;",
                [global]
            ),
            ~"\"",
            ~"&quot;",
            [global]
        ),
        ~"'",
        ~"&apos;",
        [global]
    ).
