-module(asobi_site_nav).
-include_lib("arizona/include/arizona_stateless.hrl").

-export([render/1]).

-type active() :: home | features | sdks | demo | docs | blog | cloud | none.

-spec render(active()) -> arizona_template:template().
render(Active) ->
    Link = fun(Href, Label, Key) -> link_item(Href, Label, Key, Active) end,
    Features = Link(~"/#features", ~"Features", features),
    Sdks = Link(~"/#sdks", ~"SDKs", sdks),
    Demo = Link(~"/demo", ~"Demo", demo),
    Docs = Link(~"/docs", ~"Docs", docs),
    Blog = Link(~"/blog", ~"Blog", blog),
    Cloud = Link(~"/cloud", ~"Cloud", cloud),
    ?html(
        {nav, [{class, ~"site-nav"}], [
            {'div', [{class, ~"nav-inner"}], [
                {a, [{href, ~"/"}, {class, ~"nav-brand"}], [
                    {span, [{class, ~"brand-icon"}], [<<16#904A/utf8>>]},
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
                    Blog,
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
