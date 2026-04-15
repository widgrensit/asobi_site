# Deploying asobi_site to Clever Cloud

The site is a Nova + Arizona Erlang release packaged as a Docker image.

We build the image in GitHub Actions (7 GB RAM, no OOM risk) from `Dockerfile.build` and push to GHCR. Clever Cloud then builds a 1-line passthrough `Dockerfile` (`FROM ghcr.io/widgrensit/asobi_site:latest`) — which is effectively just a registry pull, no compilation. This avoids the OOM kills we hit on Clever's builder during the `erlfmt` compile step.

## Image publishing

The `.github/workflows/docker-publish.yml` workflow builds and pushes to `ghcr.io/widgrensit/asobi_site` on every push to `main` and every `v*.*.*` tag. Tags produced:

- `latest` — head of `main`
- `main` — same, by branch name
- `sha-<full-sha>` — reproducible pin
- `1.2.3`, `1.2` — for version tags

No extra secrets needed; the workflow uses the default `GITHUB_TOKEN` with `packages: write`.

## One-time Clever setup

1. Create a **Docker** application on Clever Cloud:
   - **Create → an application → Docker**
   - Region: `par` (Paris) or `rbx` (Roubaix) — both FR-sovereign
   - Instance size: `XS` (per-second billing, ~€7-10/mo)
   - Name: `asobi-site`

2. Leave the app as a normal Docker app linked to the GitHub repo. The `Dockerfile` at the repo root is a 1-line passthrough that pulls the prebuilt image — Clever treats it as a Docker build, but the "build" is just a registry pull and takes ~20 seconds.

3. **(Recommended) Turn off Clever's GitHub auto-deploy** and trigger via webhook from GHCR instead, so Clever only pulls after the image is actually published:
   - Clever Console → your app → **Information** → **Automatic deployment** → toggle off.
   - Then set up the webhook described below under "Auto-redeploy on image push".

3. Environment variables (Console → Environment variables):
   - `CC_RUN_COMMAND` — leave unset; the Dockerfile's `CMD` is used.
   - `PORT` — already set to `8080` in the Dockerfile; Clever honours `EXPOSE 8080`.

4. Domain names (Console → Domain names):
   - Add `asobi.dev` and `www.asobi.dev`.
   - Follow the DNS instructions Clever shows (ALIAS/ANAME for apex, CNAME for www).
   - Enable **Let's Encrypt SSL** once DNS propagates.

5. Configure **Plausible Analytics** (analytics):
   - Sign up at https://plausible.io (Estonia-hosted, data in EU).
   - Add `asobi.dev` as a site.
   - The `<script>` tag in `asobi_site_layout` is already pointing at Plausible.

6. Configure **Tally form** (beta signup):
   - Sign up at https://tally.so (Netherlands-hosted).
   - Create a form with fields: email, engine (dropdown), expected CCU (dropdown), free-text ("what are you building?").
   - Copy the form ID and replace `FORM_ID` in `asobi_site_cloud_view.erl` (`data-tally-src` attribute).

## Deploying

1. Push to `main`. GitHub Actions builds + pushes the image (~3-5 min first build, ~1-2 min with cache).
2. In Clever Console → Activity, click **Redeploy** — or schedule auto-pulls via a deploy hook (see below).

To deploy from CLI instead:

```bash
clever restart --force   # re-pulls :latest
```

### Auto-redeploy on image push (optional)

To make Clever redeploy as soon as the image lands on GHCR, add a deploy webhook:

1. Clever Console → your app → **Information** → copy the **Deploy URL**.
2. GitHub repo → **Settings → Webhooks → Add** → paste the Deploy URL, content type `application/json`, events: `Packages`.

Now every successful `docker-publish` run triggers a redeploy.

## Verifying the sovereign story after deploy

Before publishing links, run these checks:

```bash
# TLS cert issuer and IP location
curl -v https://asobi.dev 2>&1 | grep -E 'issuer|Server:'
dig asobi.dev +short

# No US CDN/font leaks on the rendered page
curl -s https://asobi.dev | grep -Ei 'googleapis|gstatic|cloudflare|fly.dev'
# ^ should return nothing

# Plausible script loads from plausible.io (EU-hosted)
curl -s https://asobi.dev | grep plausible.io
```

Every third-party request from the page should resolve to an EU-sovereign provider (Clever Cloud, Plausible, Tally). Any hit to `googleapis.com`, `gstatic.com`, `fonts.google.com`, Cloudflare edge, or Fly.dev is a bug to fix before the page goes live with its EU-sovereign claim.

## Rollback

Clever keeps previous deploys. In the Console → Activity, pick any past successful build and click **Deploy**. Rollback is under 30 seconds.

## Cost expectation

- Clever Cloud XS Docker instance: ~€7-10/mo (per-second billing)
- Plausible Analytics: ~€9/mo (lowest tier)
- Tally: free tier covers 100 signups/month — upgrade later if needed
- Domain renewal (asobi.dev): included in existing budget

**Total recurring: ~€15-20/mo** for the marketing site.
