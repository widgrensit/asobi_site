-module(asobi_site_controller).

-export([heartbeat/1, blog_rss/1]).

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
