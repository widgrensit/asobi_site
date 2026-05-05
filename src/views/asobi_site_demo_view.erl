-module(asobi_site_demo_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {maps:merge(#{id => ~"demo"}, Bindings), #{}}.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}, {class, ~"demo-page"}], [
            {section, [{class, ~"demo-hero"}], [
                {'div', [{class, ~"demo-hero-inner"}], [
                    {span, [{class, ~"hero-badge"}], [~"Live demo"]},
                    {h1, [{class, ~"hero-title"}], [
                        ~"Edit. Save. ",
                        {em, [], [~"Live."]}
                    ]},
                    {p, [{class, ~"hero-subtitle"}], [
                        ~"Edit your match logic in Lua. The running match picks up the change on the next tick. No restart, no reconnect, no kicked players."
                    ]}
                ]}
            ]},

            {section, [{class, ~"section"}], [
                {'div', [{class, ~"section-inner"}], [
                    {'div', [{class, ~"demo-video-wrap"}], [
                        {video,
                            [
                                {autoplay, ~"autoplay"},
                                {muted, ~"muted"},
                                {loop, ~"loop"},
                                {playsinline, ~"playsinline"},
                                {preload, ~"auto"},
                                {class, ~"demo-video"},
                                {poster, ~"/assets/media/hotreload-demo.gif"}
                            ],
                            [
                                {source,
                                    [
                                        {src, ~"/assets/media/hotreload-demo.mp4"},
                                        {type, ~"video/mp4"}
                                    ],
                                    []},
                                {img,
                                    [
                                        {src, ~"/assets/media/hotreload-demo.gif"},
                                        {alt,
                                            ~"Editing match.lua — the cube changes color while connected"}
                                    ],
                                    []}
                            ]}
                    ]}
                ]}
            ]},

            {section, [{class, ~"section section-dark"}], [
                {'div', [{class, ~"section-inner"}], [
                    {h2, [{class, ~"section-title"}], [~"Run it locally"]},
                    {p, [{class, ~"section-subtitle"}], [
                        ~"Three containers, about 90 seconds. Postgres, asobi_lua, and an nginx proxy on localhost:3000."
                    ]},
                    {'div', [{class, ~"demo-arch"}], [
                        {'div', [{class, ~"arch-step"}], [
                            {'div', [{class, ~"arch-num"}], [~"1"]},
                            {'div', [{class, ~"arch-content"}], [
                                {h3, [], [~"Clone and start"]},
                                {pre, [], [
                                    {code, [], [
                                        ~"git clone https://github.com/widgrensit/asobi\ncd asobi/examples/hotreload-demo\ndocker compose up"
                                    ]}
                                ]}
                            ]}
                        ]},
                        {'div', [{class, ~"arch-step"}], [
                            {'div', [{class, ~"arch-num"}], [~"2"]},
                            {'div', [{class, ~"arch-content"}], [
                                {h3, [], [~"Open the page"]},
                                {p, [], [
                                    ~"Visit ",
                                    {code, [], [~"http://localhost:3000"]},
                                    ~". A cube appears. Drive it with WASD."
                                ]}
                            ]}
                        ]},
                        {'div', [{class, ~"arch-step"}], [
                            {'div', [{class, ~"arch-num"}], [~"3"]},
                            {'div', [{class, ~"arch-content"}], [
                                {h3, [], [~"Edit while connected"]},
                                {p, [], [
                                    ~"Open ",
                                    {code, [], [~"lua/match.lua"]},
                                    ~". Change ",
                                    {code, [], [~"cube_color"]},
                                    ~" or ",
                                    {code, [], [~"cube_size"]},
                                    ~" and save. The browser updates on the next tick."
                                ]}
                            ]}
                        ]}
                    ]}
                ]}
            ]},

            {section, [{class, ~"section"}], [
                {'div', [{class, ~"section-inner community-section"}], [
                    {h2, [{class, ~"section-title"}], [~"Build your own"]},
                    {p, [{class, ~"section-subtitle"}], [
                        ~"Implement the ",
                        {code, [], [~"asobi_match"]},
                        ~" behaviour in Erlang, or write game logic in Lua. Both hot-reload."
                    ]},
                    {'div', [{class, ~"hero-actions"}], [
                        {a, [{href, ~"/#get-started"}, {class, ~"btn btn-primary"}, az_navigate], [
                            ~"Get started"
                        ]},
                        {a,
                            [
                                {href, ~"https://github.com/widgrensit/asobi"},
                                {class, ~"btn btn-secondary"}
                            ],
                            [~"View on GitHub"]}
                    ]}
                ]}
            ]}
        ]}
    ).
