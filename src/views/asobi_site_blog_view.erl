-module(asobi_site_blog_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {Bindings, #{}}.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {'div', [{class, ~"guide-page blog-index"}], [
                {'div', [{class, ~"guide-header"}], [
                    {h1, [], [~"Blog"]},
                    {p, [], [
                        ~"Engineering notes, devlogs, and comparisons from the team building Asobi. ",
                        ~"Subscribe via ",
                        {a, [{href, ~"/blog/rss.xml"}], [~"RSS"]},
                        ~" or follow the ",
                        {a, [{href, ~"https://github.com/widgrensit/asobi"}], [~"GitHub repo"]},
                        ~"."
                    ]}
                ]},
                {'div', [{class, ~"blog-list"}], [
                    ?each(fun post_card/1, asobi_site_blog_posts:all())
                ]}
            ]}
        ]}
    ).

post_card(#{
    slug := Slug,
    title := Title,
    lede := Lede,
    date := Date,
    reading_time := ReadingTime,
    tags := Tags
}) ->
    Href = [~"/blog/", Slug],
    ?html(
        {article, [{class, ~"blog-card"}], [
            {'div', [{class, ~"blog-card-meta"}], [
                {time, [{datetime, Date}], [Date]},
                {span, [{class, ~"blog-card-sep"}], [~"\x{2022}"]},
                {span, [{class, ~"blog-reading-time"}], [ReadingTime]}
            ]},
            {h2, [{class, ~"blog-card-title"}], [
                {a, [{href, Href}, az_navigate], [Title]}
            ]},
            {p, [{class, ~"blog-card-lede"}], [Lede]},
            {'div', [{class, ~"blog-card-tags"}], [
                ?each(fun(T) -> {span, [{class, ~"blog-tag"}], [T]} end, Tags)
            ]},
            {a, [{href, Href}, {class, ~"blog-card-link"}, az_navigate], [~"Read \x{2192}"]}
        ]}
    ).
