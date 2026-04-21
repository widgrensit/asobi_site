-module(asobi_site_layout).
-include_lib("arizona/include/arizona_stateless.hrl").

-export([render/1]).

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    Prefix = arizona_nova:prefix(),
    ?html([
        ~"<!DOCTYPE html>",
        {html, [{lang, ~"en"}, az_nodiff], [
            {head, [], [
                {meta, [{charset, ~"UTF-8"}], []},
                {meta, [{name, ~"viewport"}, {content, ~"width=device-width, initial-scale=1.0"}],
                    []},
                {title, [], [maps:get(title, Bindings, ~"Asobi")]},
                {meta,
                    [
                        {name, ~"description"},
                        {content, ~"Open-source multiplayer game backend built on Erlang/OTP."}
                    ],
                    []},
                %% Fonts — self-hosted (Fraunces, Instrument Sans, JetBrains Mono)
                %% via priv/static/assets/fonts. No cross-border requests.
                {link, [{rel, ~"stylesheet"}, {href, ~"/assets/css/fonts.css"}], []},
                {link, [{rel, ~"stylesheet"}, {href, ~"/assets/css/app.css"}], []},
                {link, [{rel, ~"icon"}, {href, ~"/assets/img/favicon.ico"}, {sizes, ~"any"}], []},
                {link,
                    [
                        {rel, ~"icon"},
                        {type, ~"image/png"},
                        {sizes, ~"32x32"},
                        {href, ~"/assets/img/icon-32.png"}
                    ],
                    []},
                {link,
                    [
                        {rel, ~"icon"},
                        {type, ~"image/png"},
                        {sizes, ~"192x192"},
                        {href, ~"/assets/img/icon-192.png"}
                    ],
                    []},
                {link, [{rel, ~"apple-touch-icon"}, {href, ~"/assets/img/icon-180.png"}], []},
                {meta, [{name, ~"theme-color"}, {content, ~"#fbf6ec"}], []},
                {meta, [{property, ~"og:type"}, {content, ~"website"}], []},
                {meta, [{property, ~"og:title"}, {content, maps:get(title, Bindings, ~"Asobi")}],
                    []},
                {meta,
                    [
                        {property, ~"og:description"},
                        {content, ~"Open-source multiplayer game backend built on Erlang/OTP."}
                    ],
                    []},
                {meta, [{property, ~"og:image"}, {content, ~"/assets/img/og-image.png"}], []},
                {meta, [{name, ~"twitter:card"}, {content, ~"summary_large_image"}], []},
                {meta, [{name, ~"twitter:image"}, {content, ~"/assets/img/og-image.png"}], []},
                %% Plausible Analytics (Estonia-based, data hosted in EU, no cookies).
                %% Per-site script ID encodes the domain; no `data-domain` attribute.
                {script,
                    [
                        {'async', ~""},
                        {src, ~"https://plausible.io/js/pa-0ZKJIXgHGED3w2z7Fnpd2.js"}
                    ],
                    []},
                {script, [], [
                    ~"window.plausible=window.plausible||function(){(plausible.q=plausible.q||[]).push(arguments)},",
                    ~"plausible.init=plausible.init||function(i){plausible.o=i||{}};",
                    ~"plausible.init();"
                ]}
            ]},
            {body, [], [
                ?inner_content,
                ?stateless(asobi_site_footer, render, #{}),
                {script, [{type, ~"module"}], [
                    ~"import { hooks, connect } from '",
                    Prefix,
                    ~"""
                    /assets/js/arizona.min.js';
                    hooks.PreserveScroll = {
                        mounted() {
                            const key = 'az-scroll:' + (this.el.dataset.scrollKey || this.el.id || 'default');
                            const saved = sessionStorage.getItem(key);
                            if (saved !== null) this.el.scrollTop = parseInt(saved, 10) || 0;
                            this._key = key;
                        },
                        destroyed() {
                            if (this._key) sessionStorage.setItem(this._key, this.el.scrollTop.toString());
                        },
                    };
                    hooks.Scrollspy = {
                        mounted() {
                            const nav = this.el;
                            const links = new Map();
                            nav.querySelectorAll('a[href^="/#"]').forEach(a => {
                                const id = a.getAttribute('href').slice(2);
                                if (id) links.set(id, a);
                            });
                            if (links.size === 0) return;
                            this._active = null;
                            const setActive = id => {
                                if (this._active === id) return;
                                if (this._active) links.get(this._active)?.classList.remove('nav-active');
                                this._active = id;
                                if (id) links.get(id)?.classList.add('nav-active');
                            };
                            const visible = new Map();
                            this._observer = new IntersectionObserver(entries => {
                                for (const e of entries) {
                                    const id = e.target.id;
                                    if (e.isIntersecting) visible.set(id, e.intersectionRatio);
                                    else visible.delete(id);
                                }
                                let best = null, bestRatio = 0;
                                for (const [id, ratio] of visible) {
                                    if (ratio > bestRatio) { best = id; bestRatio = ratio; }
                                }
                                setActive(best);
                            }, { threshold: [0, 0.25, 0.5, 0.75, 1] });
                            for (const id of links.keys()) {
                                const section = document.getElementById(id);
                                if (section) this._observer.observe(section);
                            }
                        },
                        destroyed() {
                            this._observer?.disconnect();
                        },
                    };
                    connect('
                    """,
                    Prefix,
                    ~"/ws');"
                ]}
            ]}
        ]}
    ]).
