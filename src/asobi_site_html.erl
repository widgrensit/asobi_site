-module(asobi_site_html).
-moduledoc "Renders nested element tuples to an HTML iolist (server-side, no Arizona).".

-export([document/1, render/1, render_view/2]).
-export_type([html/0]).

-type html() ::
    binary()
    | integer()
    | {raw, iodata()}
    | {atom(), [attr()]}
    | {atom(), [attr()], html()}
    | [html()].
-type attr() :: atom() | {atom(), binary() | boolean()}.

-define(VOID, [area, base, br, col, embed, hr, img, input, link, meta, param, source, track, wbr]).
-define(RAW_TAGS, [script, style]).

-spec document(html()) -> iolist().
document(Tree) ->
    [<<"<!DOCTYPE html>\n">>, render(Tree)].

-spec render(html()) -> iolist().
render(Bin) when is_binary(Bin) ->
    esc_text(Bin);
render(Int) when is_integer(Int) ->
    Int;
render({raw, IoData}) ->
    IoData;
render({Tag, Attrs}) when is_atom(Tag), is_list(Attrs) ->
    render({Tag, Attrs, []});
render({Tag, Attrs, Children}) when is_atom(Tag) ->
    Name = atom_to_binary(Tag, utf8),
    Open = [$<, Name, attrs(Attrs), $>],
    case lists:member(Tag, ?VOID) of
        true ->
            Open;
        false ->
            Inner =
                case lists:member(Tag, ?RAW_TAGS) of
                    true -> raw(Children);
                    false -> render(Children)
                end,
            [Open, Inner, <<"</">>, Name, $>]
    end;
render(List) when is_list(List) ->
    [render(Node) || Node <- List].

-spec render_view(module(), map()) -> html().
render_view(Mod, Props) ->
    Bindings =
        case erlang:function_exported(Mod, mount, 1) of
            true ->
                {Mounted, _State} = Mod:mount(Props),
                Mounted;
            false ->
                Props
        end,
    Mod:render(Bindings).

raw(Bin) when is_binary(Bin) -> Bin;
raw(Int) when is_integer(Int) -> Int;
raw({raw, IoData}) -> IoData;
raw(List) when is_list(List) -> [raw(Node) || Node <- List].

attrs(Attrs) ->
    [attr(Attr) || Attr <- Attrs].

attr(az_navigate) -> [];
attr(az_nodiff) -> [];
attr({az_navigate, _}) -> [];
attr({az_nodiff, _}) -> [];
attr({az_hook, Value}) -> [<<" data-hook=\"">>, esc_attr(Value), $"];
attr({_Name, false}) -> [];
attr({Name, true}) -> [$\s, atom_to_binary(Name, utf8)];
attr({Name, Value}) -> [$\s, atom_to_binary(Name, utf8), <<"=\"">>, esc_attr(Value), $"];
attr(Name) when is_atom(Name) -> [$\s, atom_to_binary(Name, utf8)].

esc_text(Bin) -> esc(Bin, fun esc_text_char/1, <<>>).

esc_attr(Value) when is_binary(Value) -> esc(Value, fun esc_attr_char/1, <<>>);
esc_attr(Value) -> esc_attr(iolist_to_binary(Value)).

esc(<<>>, _Fun, Acc) -> Acc;
esc(<<C, Rest/binary>>, Fun, Acc) -> esc(Rest, Fun, <<Acc/binary, (Fun(C))/binary>>).

esc_text_char($<) -> <<"&lt;">>;
esc_text_char($>) -> <<"&gt;">>;
esc_text_char($&) -> <<"&amp;">>;
esc_text_char(C) -> <<C>>.

esc_attr_char($&) -> <<"&amp;">>;
esc_attr_char($") -> <<"&quot;">>;
esc_attr_char(C) -> <<C>>.
