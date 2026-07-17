// Generate an asobi_site docs view module from a guide markdown file.
//
// The site hand-writes its docs as Erlang views; this renders one from a guide
// instead, so a single source (the guide) feeds both hexdocs and asobi.dev.
// See docs/adr/0003 in the asobi repo.
//
// Dual-surface conventions the guides use:
//   - Callout:  > #### Title {: .info}       (ex_doc admonition; .info .warning
//               > body                         .error .tip .neutral)
//               On hexdocs this is a native admonition; here it becomes a
//               <div class="docs-callout">.
//   - Tabs:     <!-- tabs -->                 (HTML comments vanish on hexdocs,
//               **Lua**                         leaving labelled stacked code;
//               ```lua ... ```                  here they become the pure-CSS
//               **C#**                          .tabbed-code switcher)
//               ```csharp ... ```
//               <!-- /tabs -->
//
// Callouts and tab groups are lifted to placeholders before markdown-it runs,
// then their generated HTML is spliced back in, so the whole page stays one
// {raw, Binary} node and the generated module is trivial to diff.
//
// Usage: node gen-doc-view.mjs <guide.md> <module> <id> <title> <breadcrumb> <slug>
//   slug is the tab-group id prefix + must be unique per page.
import fs from 'node:fs';
import MarkdownIt from 'markdown-it';
import anchor from 'markdown-it-anchor';

const [, , mdPath, moduleName, pageId, title, breadcrumb, slug] = process.argv;
const src = fs.readFileSync(mdPath, 'utf8');

const CALLOUT_CLASSES = new Set(['info', 'warning', 'error', 'tip', 'neutral']);
const htmlEscape = s =>
  s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

const md = new MarkdownIt({ html: false, linkify: false, typographer: false });
md.use(anchor, {
  slugify: s => s.toLowerCase().trim().replace(/[^\w\s-]/g, '').replace(/\s+/g, '-'),
});
// A second instance for callout bodies: no heading anchors.
const mdInline = new MarkdownIt({ html: false, linkify: false, typographer: false });

// --- lift tab groups and callouts to placeholders -------------------------

const blocks = [];
const place = html => {
  const token = `@@BLOCK${blocks.length}@@`;
  blocks.push(html);
  return `\n\n${token}\n\n`;
};

function tabGroupHtml(inner, groupIndex) {
  // inner is the markdown between the <!-- tabs --> markers: label lines
  // (**Label**) each followed by a fenced code block.
  const re = /\*\*(.+?)\*\*\s*\n+```([a-z0-9#+]*)\n([\s\S]*?)```/gi;
  const tabs = [];
  let m;
  while ((m = re.exec(inner)) !== null) {
    tabs.push({ label: m[1].trim(), lang: langClass(m[2]), body: m[3].replace(/\n$/, '') });
  }
  if (tabs.length === 0) return '';
  const gid = `${slug}-tab${groupIndex}`;
  const inputs = tabs
    .map((_, i) =>
      `<input type="radio" name="${gid}" id="${gid}-${i + 1}"${i === 0 ? ' checked' : ''}>`)
    .join('');
  const labels = tabs
    .map((t, i) => `<label for="${gid}-${i + 1}">${htmlEscape(t.label)}</label>`)
    .join('');
  const panels = tabs
    .map(t =>
      `<pre class="tabbed-code-panel"><code class="language-${t.lang}">${htmlEscape(t.body)}</code></pre>`)
    .join('');
  return `<div class="tabbed-code">${inputs}` +
    `<div class="tabbed-code-labels" role="tablist">${labels}</div>` +
    `<div class="tabbed-code-panels">${panels}</div></div>`;
}

// markdown-it maps some fence infostrings to a different highlighter class; keep
// the site's existing language-* names (csharp not cs, etc.) verbatim.
function langClass(lang) {
  return (lang || 'text').toLowerCase();
}

let work = src;
let tabIndex = 0;
work = work.replace(/<!--\s*tabs\s*-->([\s\S]*?)<!--\s*\/tabs\s*-->/gi, (_, inner) =>
  place(tabGroupHtml(inner, tabIndex++)));

// Callout: a blockquote whose first line is a classed heading. Consume the
// whole run of leading `>` lines.
work = work.replace(
  /(?:^>[ ]*#{3,4}[ ]+(.+?)[ ]*\{:[ ]*\.([a-z]+)[ ]*\}[ ]*\n(?:^>.*\n?)*)/gim,
  (block, rawTitle, cls) => {
    if (!CALLOUT_CLASSES.has(cls)) return block;
    const bodyMd = block
      .split('\n')
      .slice(1) // drop the heading line
      .map(l => l.replace(/^>[ ]?/, ''))
      .join('\n')
      .trim();
    const bodyHtml = mdInline.render(bodyMd);
    const title = htmlEscape(rawTitle.trim());
    return place(
      `<div class="docs-callout docs-callout-${cls}">` +
      `<p class="docs-callout-title">${title}</p>${bodyHtml}</div>`);
  });

// --- markdown -> html -----------------------------------------------------

const body = work.replace(/^#\s+.*(\r?\n)+/, '');
const h1 = (src.match(/^#\s+(.*)/) || [, title])[1];
let html = md.render(body);

// Guide cross-references are relative .md links (e.g. rest-api.md). ex_doc
// resolves those on hexdocs; on the site they must become /docs routes. A guide
// with no site page falls back to its hexdocs page so no link 404s.
const SITE_ROUTES = {
  'authentication': '/docs/authentication',
  'rest-api': '/docs/protocols/rest',
  'websocket-protocol': '/docs/protocols/websocket',
  'matchmaking': '/docs/matchmaking',
  'world-server': '/docs/world-server',
  'voting': '/docs/voting',
  'economy': '/docs/economy',
  'iap': '/docs/economy',
  'clustering': '/docs/clustering',
  'configuration': '/docs/configuration',
  'performance-tuning': '/docs/performance',
  'security-auth': '/docs/security/auth',
  'security-threat-model': '/docs/security/threat-model',
  'security-known-limitations': '/docs/security/known-limitations',
};
html = html.replace(/href="([a-z0-9-]+)\.md(#[^"]*)?"/g, (_, base, anchor = '') => {
  const route = SITE_ROUTES[base];
  const href = route ? route + anchor : `https://hexdocs.pm/asobi/${base}.html${anchor}`;
  return `href="${href}"`;
});

// splice generated blocks back in (markdown-it wraps a lone token in <p>…</p>)
blocks.forEach((blockHtml, i) => {
  html = html.replace(`<p>@@BLOCK${i}@@</p>`, blockHtml);
});
if (html.includes('@@BLOCK')) {
  console.error('ERROR: a lifted block was not spliced back:', mdPath);
  process.exit(1);
}

// --- emit the erlang view -------------------------------------------------

const bin = s => '~"' + s.replace(/\\/g, '\\\\').replace(/"/g, '\\"') + '"';

process.stdout.write(`%% GENERATED from asobi guides/${mdPath.split('/').pop()} - do not edit by hand.
%% Regenerate with scripts/gen-docs.sh
-module(${moduleName}).
-include("asobi_site_view.hrl").

-export([mount/1, render/1]).

-spec mount(map()) -> {map(), map()}.
mount(Bindings) ->
    {maps:merge(#{id => ${bin(pageId)}, title => ${bin(title)}}, Bindings), #{}}.

-spec render(map()) -> asobi_site_html:html().
render(Bindings) ->
    {'div', [{id, maps:get(id, Bindings)}], [
        {p, [{class, ~"docs-breadcrumb"}], [
            {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
            ${bin(' / ' + breadcrumb)}
        ]},
        {h1, [], [${bin(h1)}]},
        {raw, ${bin(html)}}
    ]}.
`);
