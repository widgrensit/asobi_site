-module(asobi_site_blog_post_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    Slug = maps:get(slug, Bindings, ~""),
    Title =
        case asobi_site_blog_posts:by_slug(Slug) of
            {ok, #{title := T}} -> <<T/binary, " \x{2014} Asobi blog"/utf8>>;
            not_found -> ~"Not found \x{2014} Asobi blog"
        end,
    {maps:merge(#{id => ~"blog-post", title => Title}, Bindings), #{}}.

-spec render(map()) -> arizona_template:template().
render(Bindings) ->
    Nav = asobi_site_nav:render(blog),
    Footer = asobi_site_footer:render(),
    Slug = maps:get(slug, Bindings, ~""),
    Body =
        case asobi_site_blog_posts:by_slug(Slug) of
            {ok, Post} -> post_body(Post);
            not_found -> not_found_body()
        end,
    ?html(
        {'div', [{id, ?get(id)}], [
            Nav,
            {'div', [{class, ~"guide-page blog-post"}], [Body]},
            Footer
        ]}
    ).

post_body(#{
    title := Title,
    lede := Lede,
    date := Date,
    reading_time := ReadingTime,
    tags := Tags,
    body := BodyFun
}) ->
    TagEls = [{span, [{class, ~"blog-tag"}], [T]} || T <- Tags],
    Content = BodyFun(),
    ?html(
        {'div', [], [
            {'div', [{class, ~"guide-header blog-post-header"}], [
                {p, [{class, ~"blog-breadcrumb"}], [
                    {a, [{href, ~"/blog"}], [~"Blog"]},
                    ~" / ",
                    Date
                ]},
                {h1, [], [Title]},
                {p, [{class, ~"blog-lede"}], [Lede]},
                {'div', [{class, ~"blog-post-meta"}], [
                    {time, [{datetime, Date}], [Date]},
                    {span, [{class, ~"blog-card-sep"}], [~"\x{2022}"]},
                    {span, [{class, ~"blog-reading-time"}], [ReadingTime]},
                    {span, [{class, ~"blog-card-sep"}], [~"\x{2022}"]},
                    {'div', [{class, ~"blog-card-tags"}], TagEls}
                ]}
            ]},
            {article, [{class, ~"blog-body docs-content"}], [Content]},
            {'div', [{class, ~"blog-footer-cta"}], [
                {p, [], [
                    ~"Want the next post in your feed? ",
                    {a, [{href, ~"/blog/rss.xml"}], [~"Subscribe via RSS"]},
                    ~" or join the ",
                    {a, [{href, ~"https://discord.gg/vYSfYYyXpu"}], [~"Discord"]},
                    ~"."
                ]},
                {p, [], [
                    {a, [{href, ~"/blog"}], [~"\x{2190} Back to blog"]}
                ]}
            ]}
        ]}
    ).

not_found_body() ->
    ?html(
        {'div', [{class, ~"guide-header"}], [
            {h1, [], [~"Post not found"]},
            {p, [], [
                ~"That blog post doesn't exist (or has been unpublished). ",
                {a, [{href, ~"/blog"}], [~"Back to the blog index"]},
                ~"."
            ]}
        ]}
    ).
