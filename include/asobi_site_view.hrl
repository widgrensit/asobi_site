%% Compat macros that let the view modules keep their original markup
%% while rendering as plain server-side HTML via asobi_site_html.
%% All forms require a `Bindings' variable in scope, matching the
%% Arizona macros these replace.

-define(html(Elems), Elems).

-define(get(Key), maps:get(Key, Bindings)).
-define(get(Key, Default), maps:get(Key, Bindings, Default)).

-define(each(Fun, Source), lists:map(Fun, Source)).

-define(stateless(Fun, Props), Fun(Props)).
-define(stateless(Mod, Fun, Props), Mod:Fun(Props)).
-define(stateful(Handler, Props), asobi_site_html:render_view(Handler, Props)).

-define(inner_content, maps:get(inner_content, Bindings)).

-define(connected, false).
-define(send(_Msg), ok).
-define(send(_Id, _Msg), ok).
