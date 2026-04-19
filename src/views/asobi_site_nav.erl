-module(asobi_site_nav).
-include_lib("arizona/include/arizona_stateless.hrl").

-export([render/1]).

-type active() :: home | features | sdks | demo | docs | blog | cloud | none.

-spec render(active()) -> arizona_template:template().
render(Active) ->
    Links = [
        {~"/#features", ~"Features", active_class(features, Active), false},
        {~"/#sdks", ~"SDKs", active_class(sdks, Active), false},
        {~"/demo", ~"Demo", active_class(demo, Active), true},
        {~"/docs", ~"Docs", active_class(docs, Active), true},
        {~"/blog", ~"Blog", active_class(blog, Active), true},
        {~"/cloud", ~"Cloud", active_class(cloud, Active), true},
        {~"https://discord.gg/vYSfYYyXpu", ~"Discord", ~"nav-link-btn", false},
        {~"https://github.com/widgrensit/asobi", ~"GitHub", ~"nav-github", false}
    ],
    ?html(
        {nav, [{class, ~"site-nav"}], [
            {'div', [{class, ~"nav-inner"}], [
                {a,
                    [
                        {href, ~"/"},
                        {class, ~"nav-brand"},
                        {'aria-label', ~"Asobi \x{2014} home"},
                        az_navigate
                    ],
                    [
                        {img, [
                            {src, ~"/assets/img/logo-full.png"},
                            {alt, ~"Asobi"},
                            {class, ~"brand-logo"}
                        ]}
                    ]},
                {input, [{type, ~"checkbox"}, {id, ~"nav-toggle"}, {class, ~"nav-toggle"}], []},
                {label, [{for, ~"nav-toggle"}, {class, ~"nav-hamburger"}, {'aria-label', ~"Menu"}],
                    [{span, [], []}, {span, [], []}, {span, [], []}]},
                {'div', [{class, ~"nav-links"}], [
                    ?each(
                        fun({Href, Label, Class, Nav}) ->
                            {a, [{href, Href}, {class, Class}, {az_navigate, Nav}], [Label]}
                        end,
                        Links
                    )
                ]}
            ]}
        ]}
    ).

active_class(Key, Key) -> ~"nav-active";
active_class(_, _) -> ~"".
