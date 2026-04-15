# Deploying asobi_site to Clever Cloud

The site is a Nova + Arizona Erlang release packaged as a Docker image. Clever Cloud's Docker runtime is the target.

## One-time setup

1. Create a **Docker** application on Clever Cloud:
   - **Create → an application → Docker**
   - Region: `par` (Paris) or `rbx` (Roubaix) — both FR-sovereign
   - Instance size: `XS` (per-second billing, ~€7-10/mo)
   - Name: `asobi-site`

2. Link the GitHub repo `widgrensit/asobi_site` when prompted. Pick the `main` branch for auto-deploy.

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

Any push to `main` auto-builds and deploys:

```bash
git push origin main
```

Clever watches the GitHub repo and rebuilds. First build takes 3-5 min (Erlang compile), subsequent builds ~1-2 min with layer cache.

To deploy from CLI instead, install `clever-tools` and run:

```bash
clever deploy
```

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
