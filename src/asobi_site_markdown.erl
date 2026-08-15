%% Renders the same view tuple tree asobi_site_html renders, as Markdown.
%%
%% This is the sibling of asobi_site_html, not a converter: it walks the tree
%% the view modules already return, so there is nothing to keep in sync and no
%% HTML to parse. The one node form it cannot walk is {raw, IoData}, which
%% holds pre-rendered HTML - but that appears only in the generated docs
%% views, and those export markdown/0 carrying the guide source instead. So
%% no page needs an HTML parser to reach Markdown.
%%
%% Unknown tags unwrap to their children rather than crashing or dropping
%% content: silent loss in a file nobody reads is the worst failure here.
%% asobi_site_markdown_SUITE walks every routed view and fails on a tag this
%% module has not been taught, so novelty is caught in CI rather than in prod.
-module(asobi_site_markdown).

-export([render/1, tags/1, known_tags/0]).

-define(SITE, ~"https://asobi.dev").

%% Tags carrying no content in Markdown. Chrome, or a surface only script
%% fills in - a canvas holds a playable demo whose prose sits next to it.
-define(DROP, [script, style, link, meta, title, input, nav, footer, head, source, track, canvas]).

%% Rendered inline, inside a block.
-define(INLINE, [a, strong, b, em, i, code, span, br, img, time, label, button, small, sup, sub]).

%% Containers: no Markdown of their own, recurse into children as blocks.
-define(CONTAINER, [
    'div', section, article, main, aside, figure, header, html, body, tbody, thead, colgroup
]).

-spec render(asobi_site_html:html()) -> iodata().
render(Tree) ->
    tidy(iolist_to_binary(blocks(Tree))).

%%====================================================================
%% Block level
%%====================================================================

blocks(List) when is_list(List) -> group(List, [], []);
%% Pre-rendered HTML. Only generated views carry it, and they export
%% markdown/0 instead, so reaching here means the caller chose the wrong source.
blocks({raw, _}) -> [];
blocks({Tag, Attrs}) -> blocks({Tag, Attrs, []});
blocks(Bin) when is_binary(Bin) -> para(esc(Bin));
blocks({Tag, _Attrs, _Children}) when Tag =:= script; Tag =:= style -> [];
blocks({Tag, Attrs, Children}) -> block(Tag, Attrs, Children);
blocks(Int) when is_integer(Int) -> <<Int>>.

%% Siblings like [{strong,..}, ~" and ", {a,..}] are one sentence, so they must
%% become one paragraph. Rendering each node on its own would break every
%% mixed run in the site into a stack of one-word paragraphs.
group([], [], Acc) ->
    lists:reverse(Acc);
group([], Run, Acc) ->
    lists:reverse([flush(Run) | Acc]);
group([Node | Rest], Run, Acc) ->
    case is_inline(Node) of
        true -> group(Rest, [Node | Run], Acc);
        false when Run =:= [] -> group(Rest, [], [blocks(Node) | Acc]);
        false -> group(Rest, [], [blocks(Node), flush(Run) | Acc])
    end.

flush(Run) -> para(inlines(lists:reverse(Run))).

is_inline(Bin) when is_binary(Bin) -> true;
is_inline({Tag, _Attrs}) -> lists:member(Tag, ?INLINE);
is_inline({Tag, _Attrs, _Children}) -> lists:member(Tag, ?INLINE);
is_inline(_Other) -> false.

block(hr, _Attrs, _Children) ->
    ~"---\n\n";
block(br, _Attrs, _Children) ->
    [];
block(h1, _Attrs, Children) ->
    heading(~"# ", Children);
block(h2, _Attrs, Children) ->
    heading(~"## ", Children);
block(h3, _Attrs, Children) ->
    heading(~"### ", Children);
block(h4, _Attrs, Children) ->
    heading(~"#### ", Children);
block(h5, _Attrs, Children) ->
    heading(~"##### ", Children);
block(h6, _Attrs, Children) ->
    heading(~"###### ", Children);
block(p, Attrs, Children) ->
    case class(Attrs) of
        %% Navigation chrome, not page content.
        ~"docs-breadcrumb" -> [];
        _ -> para(inlines(Children))
    end;
block(ul, _Attrs, Children) ->
    [items(~"- ", Children), ~"\n"];
block(ol, _Attrs, Children) ->
    [items(ordered, Children), ~"\n"];
block(pre, _Attrs, Children) ->
    fence(Children);
block(blockquote, _Attrs, Children) ->
    quote(blocks(Children));
block(table, _Attrs, Children) ->
    table(Children);
block(details, _Attrs, Children) ->
    blocks(Children);
block(summary, _Attrs, Children) ->
    para([~"**", inlines(Children), ~"**"]);
block(figcaption, _Attrs, Children) ->
    para([~"*", inlines(Children), ~"*"]);
%% A video has no Markdown form. Link the file and keep the fallback <img>,
%% which the views supply for browsers that cannot play it.
block(video, Attrs, Children) ->
    Sources = [attr(src, A) || {source, A, _} <- collect(source, Children)],
    Src =
        case [S || S <- Sources, S =/= undefined] of
            [First | _] -> First;
            [] -> attr(poster, Attrs, ~"")
        end,
    para([~"[Video](", url(Src), ~")"]);
block('div', Attrs, Children) ->
    case class(Attrs) of
        ~"tabbed-code" -> tabs(Children);
        <<"docs-callout", _/binary>> -> quote(blocks(Children));
        _ -> blocks(Children)
    end;
block(Tag, Attrs, Children) ->
    case {lists:member(Tag, ?DROP), lists:member(Tag, ?INLINE)} of
        {true, _} -> [];
        {_, true} -> para(inline(Tag, Attrs, Children));
        %% Containers and anything unrecognised: keep the content.
        _ -> blocks(Children)
    end.

heading(Prefix, Children) ->
    para([Prefix, inlines(Children)]).

para([]) -> [];
para(Content) -> [Content, ~"\n\n"].

items(Marker, Children) ->
    Lis = [C || C <- lists:flatten([Children]), element(1, C) =:= li],
    [item(Marker, N, C) || {N, C} <- lists:enumerate(Lis)].

item(Marker, N, {li, _Attrs, Children}) ->
    Bullet =
        case Marker of
            ordered -> [integer_to_binary(N), ~". "];
            _ -> Marker
        end,
    %% A list item may hold blocks (a nested list, a fenced sample). Render
    %% them, then indent every continuation line under the bullet.
    Body = iolist_to_binary(blocks(Children)),
    case trim(Body) of
        ~"" ->
            [];
        Trimmed ->
            %% No blank line between items: a loose list renders every entry
            %% wrapped in its own paragraph, which reads as separate thoughts.
            [First | Rest] = binary:split(Trimmed, ~"\n", [global]),
            [Bullet, First, ~"\n", [indent(L) || L <- Rest]]
    end.

indent(~"") -> ~"\n";
indent(Line) -> [~"  ", Line, ~"\n"].

quote(Content) ->
    case trim(iolist_to_binary(Content)) of
        ~"" ->
            [];
        Trimmed ->
            Lines = binary:split(Trimmed, ~"\n", [global]),
            [[quote_line(L) || L <- Lines], ~"\n"]
    end.

quote_line(~"") -> ~">\n";
quote_line(Line) -> [~"> ", Line, ~"\n"].

%%====================================================================
%% Code blocks
%%====================================================================

%% <pre><code class="language-lua"> is the only shape the views produce.
fence(Children) ->
    case [C || C <- lists:flatten([Children]), is_tuple(C), element(1, C) =:= code] of
        [{code, Attrs, Body} | _] -> fence(language(Attrs), text(Body));
        _ -> fence(~"", text(Children))
    end.

fence(Lang, Body) ->
    Trimmed = trim(Body),
    Ticks = ticks(Trimmed),
    [Ticks, Lang, ~"\n", Trimmed, ~"\n", Ticks, ~"\n\n"].

%% A sample containing a fence of its own needs a longer one around it.
ticks(Body) ->
    case binary:match(Body, ~"```") of
        nomatch -> ~"```";
        _ -> ~"````"
    end.

language(Attrs) ->
    case class(Attrs) of
        <<"language-", Lang/binary>> -> Lang;
        _ -> ~""
    end.

%% Tabbed code degrades to labelled stacked fences, which is exactly what the
%% same content already looks like on hexdocs, where the <!-- tabs --> markers
%% are invisible comments.
tabs(Children) ->
    Labels = [inlines(C) || {label, _A, C} <- collect(label, Children)],
    Panels = [fence(C) || {pre, _A, C} <- collect(pre, Children)],
    case {Labels, Panels} of
        {_, []} -> blocks(Children);
        %% One tab is not a choice; the label is noise.
        {_, [Only]} -> Only;
        {[], _} -> Panels;
        _ -> [[~"**", L, ~"**\n\n", P] || {L, P} <- zip_short(Labels, Panels)]
    end.

zip_short([A | As], [B | Bs]) -> [{A, B} | zip_short(As, Bs)];
zip_short(_, _) -> [].

collect(Tag, Node) ->
    lists:reverse(collect(Tag, Node, [])).

collect(Tag, List, Acc) when is_list(List) ->
    lists:foldl(fun(N, A) -> collect(Tag, N, A) end, Acc, List);
collect(Tag, {Tag, _Attrs, _Children} = Node, Acc) ->
    [Node | Acc];
collect(Tag, {_Other, _Attrs, Children}, Acc) ->
    collect(Tag, Children, Acc);
collect(_Tag, _Node, Acc) ->
    Acc.

%%====================================================================
%% Tables
%%====================================================================

table(Children) ->
    case [row(R) || R <- collect(tr, Children)] of
        [] ->
            [];
        [Header | Body] ->
            Width = length(Header),
            [
                row_line(Header),
                row_line(lists:duplicate(Width, ~"---")),
                [row_line(pad(R, Width)) || R <- Body],
                ~"\n"
            ]
    end.

row({tr, _Attrs, Children}) ->
    [cell(C) || C <- lists:flatten([Children]), is_cell(C)].

is_cell(C) when is_tuple(C) -> element(1, C) =:= td orelse element(1, C) =:= th;
is_cell(_) -> false.

%% A pipe inside a cell would end the cell; an embedded newline would end the
%% row. Neither survives a GFM table, so neutralise both.
cell({_Tag, _Attrs, Children}) ->
    Flat = binary:replace(trim(iolist_to_binary(inlines(Children))), ~"\n", ~" ", [global]),
    binary:replace(Flat, ~"|", ~"\\|", [global]).

pad(Row, Width) when length(Row) >= Width -> lists:sublist(Row, Width);
pad(Row, Width) -> Row ++ lists:duplicate(Width - length(Row), ~"").

row_line(Cells) ->
    [~"| ", lists:join(~" | ", Cells), ~" |\n"].

%%====================================================================
%% Inline level
%%====================================================================

inlines(List) when is_list(List) -> [inlines(N) || N <- List];
inlines({raw, _}) -> [];
inlines({Tag, Attrs}) -> inlines({Tag, Attrs, []});
inlines(Bin) when is_binary(Bin) -> esc(Bin);
inlines(Int) when is_integer(Int) -> <<Int>>;
inlines({Tag, Attrs, Children}) -> inline(Tag, Attrs, Children).

inline(code, _Attrs, Children) ->
    case trim(text(Children)) of
        ~"" -> ~"";
        Body -> [~"`", Body, ~"`"]
    end;
inline(Tag, _Attrs, Children) when Tag =:= strong; Tag =:= b ->
    emphasis(~"**", inlines(Children));
inline(Tag, _Attrs, Children) when Tag =:= em; Tag =:= i ->
    emphasis(~"*", inlines(Children));
inline(a, Attrs, Children) ->
    case {trim(iolist_to_binary(inlines(Children))), attr(href, Attrs)} of
        {~"", _} -> ~"";
        {Text, undefined} -> Text;
        {Text, Href} -> [~"[", Text, ~"](", url(Href), ~")"]
    end;
inline(img, Attrs, _Children) ->
    case attr(src, Attrs) of
        undefined -> ~"";
        Src -> [~"![", attr(alt, Attrs, ~""), ~"](", url(Src), ~")"]
    end;
inline(br, _Attrs, _Children) ->
    ~"\n";
inline(Tag, Attrs, Children) ->
    case lists:member(Tag, ?DROP) of
        true -> [];
        false -> block_or_inline(Tag, Attrs, Children)
    end.

%% A block tag met in inline position (a <p> inside a <li>, say). Render it as
%% a block and let the caller's indentation handle it.
block_or_inline(Tag, Attrs, Children) ->
    case lists:member(Tag, ?INLINE) orelse lists:member(Tag, ?CONTAINER) of
        true -> inlines(Children);
        false -> blocks({Tag, Attrs, Children})
    end.

%% Views routinely write {strong, [], [~"Prerequisites: "]} with the separating
%% space inside the tag. HTML does not care; Markdown does - "**bold **" is not
%% emphasis at all under the right-flanking rule - so surrounding whitespace
%% has to move outside the markers rather than be trimmed away.
emphasis(Marker, Content) ->
    case hoist(iolist_to_binary(Content)) of
        {_Lead, ~"", _Trail} -> ~"";
        {Lead, Body, Trail} -> [Lead, Marker, Body, Marker, Trail]
    end.

hoist(Bin) ->
    Body = trim(Bin),
    case Body of
        ~"" ->
            {~"", ~"", ~""};
        _ ->
            [Lead, Rest] = binary:split(Bin, Body),
            {Lead, Body, Rest}
    end.

%% Links must be absolute: fetched out of band, a site-relative path cannot be
%% resolved. In-page anchors stay as they are.
url(<<"/", _/binary>> = Path) -> <<?SITE/binary, Path/binary>>;
url(Href) -> Href.

%%====================================================================
%% Text and escaping
%%====================================================================

%% Verbatim text, for code blocks: no Markdown escaping, no tag rendering.
text(List) when is_list(List) -> iolist_to_binary([text(N) || N <- List]);
text(Bin) when is_binary(Bin) -> Bin;
text(Int) when is_integer(Int) -> <<Int>>;
text({raw, _}) -> ~"";
text({_Tag, _Attrs}) -> ~"";
text({_Tag, _Attrs, Children}) -> text(Children).

%% Only the characters that would change the structure. Underscores are left
%% alone deliberately: intra-word underscores carry no meaning in CommonMark,
%% and asobi's prose is full of handle_input and world_server.
%% Character literals rather than ~"\\" sigils: elp's parser cannot read a
%% backslash escape inside the binary sigil and reports the whole function as a
%% syntax error, which costs real lint coverage of this module.
esc(Bin) ->
    lists:foldl(fun esc_char/2, Bin, [$\\, $`, $*, $[, $]]).

esc_char(Char, Bin) ->
    binary:replace(Bin, <<Char>>, <<$\\, Char>>, [global]).

trim(Bin) -> string:trim(Bin, both, "\s\t\n\r").

class(Attrs) -> attr(class, Attrs, ~"").

attr(Key, Attrs) -> attr(Key, Attrs, undefined).

attr(Key, Attrs, Default) ->
    case lists:keyfind(Key, 1, [A || A <- Attrs, is_tuple(A)]) of
        {Key, Value} when is_binary(Value) -> Value;
        _ -> Default
    end.

%% Collapse the runs of blank lines the block rules leave behind, and end the
%% document with exactly one newline.
tidy(Bin) ->
    Collapsed = re:replace(Bin, "\n{3,}", "\n\n", [global, {return, binary}]),
    <<(trim(Collapsed))/binary, "\n">>.

%%====================================================================
%% CI support
%%====================================================================

%% Every tag this module has been taught. A tag outside this set still
%% renders (unknown tags unwrap to their children), but the suite fails so
%% the decision is made deliberately rather than discovered later.
-spec known_tags() -> [atom()].
known_tags() ->
    lists:usort(
        [h1, h2, h3, h4, h5, h6, p, ul, ol, li, pre, blockquote, table, tr, th, td] ++
            [details, summary, figcaption, hr, raw, video] ++
            ?DROP ++ ?INLINE ++ ?CONTAINER
    ).

%% Every tag actually present in a tree, for the coverage assertion.
-spec tags(asobi_site_html:html()) -> [atom()].
tags(Tree) -> lists:usort(tags(Tree, [])).

tags(List, Acc) when is_list(List) ->
    lists:foldl(fun tags/2, Acc, List);
tags({raw, _}, Acc) ->
    [raw | Acc];
tags({Tag, _Attrs}, Acc) ->
    [Tag | Acc];
tags({Tag, _Attrs, Children}, Acc) ->
    tags(Children, [Tag | Acc]);
tags(_Other, Acc) ->
    Acc.
