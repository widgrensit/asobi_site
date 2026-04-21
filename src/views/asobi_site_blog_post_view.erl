-module(asobi_site_blog_post_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1, handle_info/2]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    ?connected andalso ?send(connected),
    Slug = maps:get(slug, Bindings, ~""),
    Post = asobi_site_blog_posts:by_slug(Slug),
    {Bindings#{post => Post}, #{}}.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {'div', [{class, ~"guide-page blog-post"}], [
                case ?get(post) of
                    {ok, Post} -> ?stateless(post_body, Post);
                    not_found -> ?stateless(not_found_body, #{})
                end
            ]}
        ]}
    ).

-spec handle_info(connected, az:bindings()) -> az:handle_info_ret().
handle_info(connected, Bindings) ->
    case Bindings of
        #{post := {ok, #{title := Title}}} ->
            {Bindings, #{}, [arizona_js:set_title(Title)]};
        #{} ->
            {Bindings, #{}, []}
    end.

post_body(#{
    title := Title,
    lede := Lede,
    date := Date,
    reading_time := ReadingTime,
    tags := Tags,
    body := BodyFun
}) ->
    ?html(
        {'div', [], [
            {'div', [{class, ~"guide-header blog-post-header"}], [
                {p, [{class, ~"blog-breadcrumb"}], [
                    {a, [{href, ~"/blog"}, az_navigate], [~"Blog"]},
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
                    {'div', [{class, ~"blog-card-tags"}], [
                        ?each(fun(T) -> {span, [{class, ~"blog-tag"}], [T]} end, Tags)
                    ]}
                ]}
            ]},
            {article, [{class, ~"blog-body docs-content"}], [?stateless(BodyFun, #{})]},
            {'div', [{class, ~"blog-footer-cta"}], [
                {p, [], [
                    ~"Want the next post in your feed? ",
                    {a, [{href, ~"/blog/rss.xml"}], [~"Subscribe via RSS"]},
                    ~" or join the ",
                    {a, [{href, ~"https://discord.gg/vYSfYYyXpu"}], [~"Discord"]},
                    ~"."
                ]},
                {p, [], [
                    {a, [{href, ~"/blog"}, az_navigate], [~"\x{2190} Back to blog"]}
                ]}
            ]}
        ]}
    ).

not_found_body(_Bindings) ->
    ?html(
        {'div', [{class, ~"guide-header"}], [
            {h1, [], [~"Post not found"]},
            {p, [], [
                ~"That blog post doesn't exist (or has been unpublished). ",
                {a, [{href, ~"/blog"}, az_navigate], [~"Back to the blog index"]},
                ~"."
            ]}
        ]}
    ).
