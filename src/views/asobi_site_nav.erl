-module(asobi_site_nav).
-include_lib("arizona/include/arizona_stateless.hrl").

-export([render/1]).

-type active() :: home | features | sdks | demo | docs | blog | cloud | none.
-type bindings() :: #{active := active()}.

-spec render(bindings()) -> az:template().
render(Bindings) ->
    Links = [
        {~"/#features", ~"Features", {active, features}, true},
        {~"/#sdks", ~"SDKs", {active, sdks}, true},
        {~"/demo", ~"Demo", {active, demo}, true},
        {~"/docs", ~"Docs", {active, docs}, true},
        {~"/blog", ~"Blog", {active, blog}, true},
        {~"/cloud", ~"Cloud", {active, cloud}, true},
        {~"https://discord.gg/vYSfYYyXpu", ~"Discord", {fixed, ~"nav-link-btn"}, false},
        {~"https://github.com/widgrensit/asobi", ~"GitHub", {fixed, ~"nav-github"}, false}
    ],
    ?html(
        {nav, [{class, ~"site-nav"}, {az_hook, ~"Scrollspy"}], [
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
                        fun({Href, Label, ClassSpec, Nav}) ->
                            {a,
                                [
                                    {href, Href},
                                    {class, link_class(ClassSpec, ?get(active))},
                                    {az_navigate, Nav}
                                ],
                                [Label]}
                        end,
                        Links
                    )
                ]}
            ]}
        ]}
    ).

link_class({active, Key}, Key) -> ~"nav-active";
link_class({active, _}, _) -> ~"";
link_class({fixed, Class}, _) -> Class.
