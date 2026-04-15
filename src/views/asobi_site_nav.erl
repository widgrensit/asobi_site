-module(asobi_site_nav).
-include_lib("arizona/include/arizona_stateless.hrl").

-export([render/1]).

-type active() :: home | features | sdks | demo | docs | cloud | none.

-spec render(active()) -> arizona_template:template().
render(Active) ->
    Link = fun(Href, Label, Key) -> link_item(Href, Label, Key, Active) end,
    Features = Link(~"/#features", ~"Features", features),
    Sdks = Link(~"/#sdks", ~"SDKs", sdks),
    Demo = Link(~"/demo", ~"Demo", demo),
    Docs = Link(~"/docs", ~"Docs", docs),
    Cloud = Link(~"/cloud", ~"Cloud", cloud),
    ?html(
        {nav, [{class, ~"site-nav"}], [
            {'div', [{class, ~"nav-inner"}], [
                {a, [{href, ~"/"}, {class, ~"nav-brand"}], [
                    {img,
                        [
                            {src, ~"/assets/img/tanuki.png"},
                            {alt, ~"asobi"},
                            {class, ~"brand-logo"},
                            {width, ~"36"},
                            {height, ~"36"}
                        ],
                        []},
                    {span, [{class, ~"brand-text"}], [~"asobi"]}
                ]},
                {input, [{type, ~"checkbox"}, {id, ~"nav-toggle"}, {class, ~"nav-toggle"}], []},
                {label, [{for, ~"nav-toggle"}, {class, ~"nav-hamburger"}, {'aria-label', ~"Menu"}],
                    [{span, [], []}, {span, [], []}, {span, [], []}]},
                {'div', [{class, ~"nav-links"}], [
                    Features,
                    Sdks,
                    Demo,
                    Docs,
                    Cloud,
                    {a, [{href, ~"https://discord.gg/vYSfYYyXpu"}, {class, ~"nav-link-btn"}], [
                        ~"Discord"
                    ]},
                    {a, [{href, ~"https://github.com/widgrensit/asobi"}, {class, ~"nav-github"}], [
                        ~"GitHub"
                    ]}
                ]}
            ]}
        ]}
    ).

link_item(Href, Label, Key, Active) ->
    Class =
        case Key of
            Active -> ~"nav-active";
            _ -> ~""
        end,
    ?html({a, [{href, Href}, {class, Class}], [Label]}).
