# Deploying asobi_site

The site is a Nova Erlang release (server-rendered, no Arizona) packaged as a Docker image.

**Target setup: Hetzner k3s** (same cluster as asobi_saas) — see the next section. The Clever Cloud sections below describe the legacy setup and stay valid until cutover; after teardown they can be deleted.

## Hetzner k3s

Manifests live in `deploy/k8s/asobi-site.yaml`: Deployment (GHCR `:latest`, non-root uid 999, `/heartbeat` probes), Service, and a Traefik Ingress for `asobi.dev` + `www.asobi.dev` with cert-manager TLS (`letsencrypt-prod`). The image is the GHCR one built by `docker-publish.yml` on every push to `main` — unlike Clever there is no source build.

### Cutover (one-time)

1. Merge this branch so GHCR has the non-root image (`docker-publish.yml` rebuilds on merge).
2. `kubectl --kubeconfig ~/.kube/asobi.yaml apply -f deploy/k8s/` (Deployment/Service/Ingress + the NetworkPolicies in `asobi-site-policy.yaml` - the site pod accepts traffic only from traefik and can reach only DNS)
3. Verify the pod directly, before touching DNS:
   `kubectl -n asobi port-forward deploy/asobi-site 18080:8080` then `curl -H 'Host: asobi.dev' http://localhost:18080/heartbeat`
4. At deSEC, point `asobi.dev` (A/AAAA) and `www` at the cluster ingress IP (same records as `demo.asobi.dev`). Lower TTLs beforehand if you want a fast rollback window. The cert-manager HTTP-01 challenge completes only after DNS points here; expect a few minutes of cert warning on the new host, or pre-stage with a temporary hostname first.
5. Watch `kubectl -n asobi get certificate asobi-site-tls` until Ready, then spot-check `https://asobi.dev` and `https://www.asobi.dev`.

Rollback: repoint DNS at Clever (records unchanged there) — nothing on Clever is removed by the steps above.

### Teardown (after a comfortable soak)

1. Delete the Clever application (stops billing).
2. Remove the Clever DNS instructions' leftovers at deSEC if any (ALIAS/CNAME targets).
3. Delete the Clever sections from this file.

### Redeploying

Push to `main` → GHCR image updates → `kubectl -n asobi rollout restart deploy/asobi-site`. (Same gotcha as asobi_saas: merging does not deploy by itself.)

**Clever Cloud source-builds the multi-stage `Dockerfile` from the repo** on each deploy: it compiles the release in the `erlang:28` builder stage and copies it into a slim runtime image. The `Dockerfile` must `COPY include` (the views' shared `asobi_site_view.hrl` lives there) or the release build fails with "can't find include file".

GitHub Actions (`.github/workflows/docker-publish.yml`) also builds and pushes the same image to GHCR on every push to `main`. That GHCR image is an artifact mirror; it is **not** what Clever serves (Clever builds from source). The builder stage peaks ~600 MB RAM; if Clever OOMs, bump the build instance one RAM tier.

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

2. Leave the app as a normal Docker app linked to the GitHub repo. Clever builds the repo-root multi-stage `Dockerfile` from source on each deploy (~2-4 min).

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

1. Push to `main` (GitHub Actions runs CI and publishes the GHCR mirror).
2. In Clever Console → Activity, click **Redeploy** — Clever rebuilds from source. Or wire the deploy hook (see below) so it triggers automatically.

To deploy from CLI instead:

```bash
clever restart --force   # rebuilds from source
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
curl -s https://asobi.dev | grep -Ei 'googleapis|gstatic|cloudflare|fly\.dev|fontawesome|jsdelivr|unpkg|cloudfront'
# ^ should return nothing. Fonts are self-hosted under /assets/fonts/.

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
