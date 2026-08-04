-module(asobi_site_docs_erlang_api_view).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {
        maps:merge(#{id => ~"docs-erlang-api", title => ~"Erlang API — Asobi docs"}, Bindings),
        #{}
    }.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Erlang / API"
            ]},
            {h1, [], [~"Erlang API reference"]},
            {p, [{class, ~"docs-lede"}], [
                ~"These docs are Lua-first, because that is how most games are built on Asobi. ",
                ~"But Asobi is a plain Erlang/OTP library underneath, and you can use it directly ",
                ~"from Erlang (or any BEAM language) without writing any Lua."
            ]},

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"When to use Erlang over Lua: "]},
                    ~"you want behaviour-level control (supervision trees, custom match state machines, direct ",
                    {code, [], [~"gen_statem"]},
                    ~" handling), or you are embedding Asobi in an existing Erlang application. Writing a game? Stay on the ",
                    {a, [{href, ~"/docs/lua/api"}, az_navigate], [~"Lua API"]},
                    ~"."
                ]}
            ]},

            {h2, [], [~"Start an Erlang project"]},
            {p, [], [
                ~"The setup steps - the ",
                {code, [], [~"rebar.config"]},
                ~" dependency, the ",
                {code, [], [~"sys.config"]},
                ~" keys Nova, kura and shigoto need, and a minimal ",
                {code, [], [~"asobi_match"]},
                ~" module - are in the ",
                external_link(
                    ~"https://hexdocs.pm/asobi/getting-started.html#erlang-otp",
                    ~"Erlang OTP section of the getting-started guide"
                ),
                ~". That guide ships inside the library, so it is version-matched to the release you depend on. ",
                ~"A working project is in ",
                external_link(
                    ~"https://github.com/widgrensit/asobi/tree/main/examples/erlang-match",
                    ~"examples/erlang-match"
                ),
                ~"."
            ]},
            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Asobi is a game backend you write in Lua. "]},
                    ~"Erlang is a supported way in, not the main road: the tutorials, samples and CLI ",
                    ~"all assume Lua, and the Lua runtime ships inside the same application, so you ",
                    ~"take it as a dependency either way. If you are writing a game rather than ",
                    ~"embedding the library, start at the ",
                    {a, [{href, ~"/docs/quickstart"}, az_navigate], [~"quick start"]},
                    ~"."
                ]}
            ]},

            {h2, [], [~"Reference"]},
            {p, [], [
                ~"The full Erlang API reference is published on HexDocs: every public module carries ",
                {code, [], [~"-moduledoc"]},
                ~"/",
                {code, [], [~"-doc"]},
                ~" attributes, rendered at ",
                {a, [{href, ~"https://hexdocs.pm/asobi"}], [~"hexdocs.pm/asobi"]},
                ~". The source lives on the ",
                {a, [{href, ~"https://github.com/widgrensit/asobi"}], [~"asobi repository"]},
                ~"."
            ]},

            {h2, [], [~"The modules you will use"]},
            {ul, [], [
                module(
                    ~"asobi_match",
                    ~"the game behaviour every mode implements (init/join/leave/handle_input/tick/get_state) - the Lua adapter implements it on your behalf"
                ),
                module(
                    ~"asobi_match_server",
                    ~"the gen_statem that drives a match's lifecycle and broadcasts state"
                ),
                module(~"asobi_matchmaker", ~"queues and pairing strategies"),
                module(~"asobi_world_server", ~"persistent, zoned worlds"),
                module(~"asobi_zone", ~"spatial partitions within a world"),
                module(~"asobi_spatial", ~"in-memory spatial queries")
            ]},

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/lua/api"}, az_navigate], [~"Lua API reference"]},
                    ~" - the ",
                    {code, [], [~"game.*"]},
                    ~" surface most games use."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/concepts"}, az_navigate], [~"Core concepts"]},
                    ~" - matches, worlds, zones, voting, phases."
                ]},
                {li, [], [
                    {a, [{href, ~"/docs/self-host"}, az_navigate], [~"Self-host"]},
                    ~" - run the runtime yourself."
                ]}
            ]}
        ]}
    ).

module(Name, Desc) ->
    ?html({li, [], [{code, [], [Name]}, ~" - ", Desc]}).

external_link(Href, Text) ->
    ?html({a, [{href, Href}], [Text]}).
