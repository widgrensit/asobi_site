# AGENTS.md - asobi_site

Marketing + documentation site for **asobi.dev** (the asobi game backend).
Public repo `widgrensit/asobi_site`. Erlang/OTP + the Nova web framework,
**server-rendered HTML - no JavaScript framework, no live/WebSocket layer.**

## What this is / is not
- Mostly-static marketing + docs pages, a small blog, an RSS feed.
- Plain Nova SSR. **No Arizona** (removed 2026-05; Arizona is deprecated in
  favour of Nova). No WebSocket, no live updates.
- The only client JS is `priv/static/assets/js/app.js` (scrollspy + scroll
  preservation). Code tabs are pure CSS.

## Request flow
router (fun-routes) -> `asobi_site_controller:page/2` -> `asobi_site_page:render/1`
-> view module -> `asobi_site_html` renders the tuple tree to an HTML iolist
-> `{status, 200, Headers, IoData}`.

- `src/asobi_site_router.erl` - every route. `page/3` and `docs/2` build fun-routes.
- `src/controllers/asobi_site_controller.erl` - `page/2` builds bindings and
  renders page+layout; also `markdown/2`, `heartbeat/1`, `blog_rss/1`,
  `llms_txt/1`, `robots_txt/1` and `sitemap_xml/1`.
- `src/views/asobi_site_page.erl` - wraps each page with the nav + the view.
- `src/views/asobi_site_layout.erl` - the `<html>` shell (head, fonts, analytics,
  footer, `app.js`).
- `src/asobi_site_html.erl` - the tuple->HTML renderer (see below).
- `src/asobi_site_markdown.erl` - its sibling: walks the SAME tuple tree and
  emits Markdown, for the `.md` twin every page serves. Not a converter; there
  is no HTML parsing anywhere.
- `src/asobi_site_llms.erl` - the curated `/llms.txt` index as data.
- `include/asobi_site_view.hrl` - the `?html/?get/?each/?stateless/?stateful`
  macros every view uses.

## The view / markup system
A view is an Erlang module whose `render/1` returns nested tuples:
- `{Tag, Attrs, Children}`, or `{Tag, Attrs}` for void elements (`img`, `br`, ...).
- `Attrs :: [atom() | {atom(), binary() | boolean()}]`.
- Children: `binary()` (escaped as text), `{raw, IoData}` (verbatim, unescaped),
  nested element tuples, or lists of these.
- **Integers are emitted as raw bytes** - only 0-255 (a single char) is valid.
  A bare large integer (e.g. a year `2026`) is an invalid iolist element and
  crashes at reply time. Render numbers as binaries.
- `script` / `style` children are emitted raw (not escaped).

Macros (`include/asobi_site_view.hrl`), kept for parity with the old Arizona views:
- `?html(Elems)` -> `Elems` (identity; just marks a block as markup).
- `?get(Key)` / `?get(Key, Default)` -> `maps:get` on the view's `Bindings`.
- `?each(Fun, List)` -> `lists:map`.
- `?stateless(Mod, Fun, Props)` / `?stateless(Fun, Props)` -> call a render helper.
- `?stateful(Mod, Props)` -> `asobi_site_html:render_view(Mod, Props)`: runs the
  module's `mount/1` (if exported) then `render/1`.
- `az_navigate` / `az_nodiff` attrs are accepted and dropped (Arizona leftovers).

## Adding a page
1. Create `src/views/asobi_site_<name>_view.erl` exporting `render/1` (and
   `mount/1` if it needs to load data).
2. Add a route in `asobi_site_router.erl`:
   `page(~"/path", asobi_site_<name>_view, <active>)` (or `docs/2` for docs pages).
   Both helpers also emit the `/path.md` twin automatically - do not add one.
3. **Index it in `src/asobi_site_llms.erl`**, either as a `{Path, Title,
   Description}` entry under a section or in `exclusions/0` with the reason. CI
   fails otherwise, by design: a `/llms.txt` that silently stops listing new
   pages is worse than none, because an agent reads it as a complete map and
   stops looking.
4. `test/asobi_site_router_SUITE.erl` renders every route to a binary, and
   `asobi_site_markdown_SUITE` checks the Markdown twin - keep both green. If
   the new page uses an HTML tag no page used before, `no_unknown_tags` will
   fail; teach `asobi_site_markdown` how to render it.

## Blog
- `src/views/asobi_site_blog_posts.erl` - posts are Erlang data. `all/0`
  (date-descending) and `by_slug/1` (`{ok, Post} | not_found`). Post bodies are
  render functions.
- `asobi_site_blog_post_view` has a `mount/1` that loads the post by slug into
  bindings before `render/1`.

## Gotchas (learned the hard way - read before touching deploy or rendering)
- **The Dockerfile must `COPY include`.** Views `-include("asobi_site_view.hrl")`;
  `rebar3 as prod release` fails with "can't find include file" if `include/`
  is not copied into the builder stage.
- **`render_view/2` calls `code:ensure_loaded(Mod)` before
  `erlang:function_exported(Mod, mount, 1)`.** `function_exported/3` returns
  false for a not-yet-loaded module, so without the ensure_loaded the `mount/1`
  probe is skipped and data-loading pages 500. Do not remove it.
- **Path bindings are BINARY keys** in Nova fun-routes:
  `maps:get(~"slug", maps:get(bindings, Req, #{}), ~"")` - not
  `cowboy_req:binding(slug, Req)`.
- **The release runs in embedded code-loading mode**, so every app module must be
  listed in the `.app`. Keep `{modules, []}` in `asobi_site.app.src` and let
  rebar3 auto-populate it from `src/` at build time; a module missing from the
  `.app` raises `undef` at runtime, not a compile error.
- **elp's parser cannot read a backslash escape inside a `~""` sigil**
  (`~"\\"`, `~"\n{3,}"`). It reports the whole function as a syntax error and
  silently drops that module from lint coverage. Use `$\\` character literals
  or a plain `"..."` string there instead.
- **A local `rebar3 compile` cannot catch a missing Dockerfile `COPY`.** When the
  deploy is the problem, build and run the real release image
  (`docker build` + `docker run`, then curl the pages), not just `rebar3 compile`.

## Commands
```
rebar3 compile
rebar3 ct                       # includes asobi_site_router_SUITE (renders all routes)
rebar3 fmt                      # erlfmt; CI runs rebar3 fmt --check
rebar3 xref
rebar3 dialyzer
rebar3 as prod release          # the release the Docker image builds
docker build -t asobi_site .    # full multi-stage release image
docker run -d -p 8090:8080 asobi_site && curl -s localhost:8090/   # smoke test
```

## Conventions
- erlfmt formatting. `~"..."` binary sigil, not `<<"...">>`. `?LOG_*` macros with
  `#{...}` map reports. OTP `json` module (never thoas/jiffy).
- British English in user-facing copy. No em dashes - ASCII hyphen only.
- Conventional commits (`feat:`, `fix:`, `docs:`, ...). Always branch + PR; CI runs
  on `Taure/erlang-ci`. Never push to `main`.

## Deploy (summary; full detail in DEPLOY.md)
Hetzner k3s, same cluster as asobi_saas. Manifests in `deploy/k8s/`. Pushing to
`main` runs `docker-publish.yml`, which pushes the image to GHCR - and that IS
the deploy artifact, but publishing it does not roll it. **There is no
auto-deploy**: merging to `main` does not update prod. Roll it yourself, or prod
silently goes stale:

```
kubectl --kubeconfig ~/.kube/asobi.yaml -n asobi rollout restart deploy/asobi-site
```

The site moved off Clever Cloud on 2026-07-23 and the Clever application is
deleted; ignore any older instruction to trigger a Clever redeploy.
