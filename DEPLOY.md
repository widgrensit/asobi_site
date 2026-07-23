# Deploying asobi_site

The site is a Nova Erlang release (server-rendered, no Arizona) packaged as a Docker image, served from the Hetzner k3s cluster (same cluster as asobi_saas). Cut over from Clever Cloud on 2026-07-23; the Clever application is deleted.

## Hetzner k3s

Manifests live in `deploy/k8s/`:

- `asobi-site.yaml` — Deployment (GHCR `:latest`, non-root uid 999, restricted-PSA securityContext, `/heartbeat` probes, 500m CPU / 512Mi limits), Service, and a Traefik Ingress for `asobi.dev` + `www.asobi.dev` with cert-manager TLS (`letsencrypt-prod`, secret `asobi-site-tls`).
- `asobi-site-policy.yaml` — NetworkPolicies pinning the pod to ingress-from-traefik and egress-to-DNS only.

DNS at deSEC: apex A/AAAA and `www` CNAME point at the cluster ingress (same records as `demo.asobi.dev`).

## Deploying a change

Push to `main` → CI runs and `docker-publish.yml` pushes the image to GHCR → then roll it:

```bash
kubectl --kubeconfig ~/.kube/asobi.yaml -n asobi rollout restart deploy/asobi-site
```

Same gotcha as asobi_saas: **merging does not deploy by itself.**

Manifest changes: `kubectl --kubeconfig ~/.kube/asobi.yaml apply -f deploy/k8s/`.

## Image publishing

The `.github/workflows/docker-publish.yml` workflow builds and pushes to `ghcr.io/widgrensit/asobi_site` on every push to `main` and every `v*.*.*` tag. Tags produced:

- `latest` — head of `main`
- `main` — same, by branch name
- `sha-<full-sha>` — reproducible pin
- `1.2.3`, `1.2` — for version tags

No extra secrets needed; the workflow uses the default `GITHUB_TOKEN` with `packages: write`.

Build note: the `Dockerfile` must `COPY include` (the views' shared `asobi_site_view.hrl` lives there) or the release build fails with "can't find include file". The runtime stage runs as uid 999 (`asobi`), matching the manifest's `runAsUser`.

## Rollback

```bash
# Previous image by digest (find it under GHCR package versions), then:
kubectl --kubeconfig ~/.kube/asobi.yaml -n asobi set image deploy/asobi-site asobi-site=ghcr.io/widgrensit/asobi_site@sha256:<previous>
# Or simply revert the offending commit and redeploy via the normal flow.
```

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

Every third-party request from the page should resolve to an EU-sovereign provider (Hetzner, Plausible, Tally). Any hit to `googleapis.com`, `gstatic.com`, `fonts.google.com`, Cloudflare edge, or Fly.dev is a bug to fix before the page goes live with its EU-sovereign claim.

## Cost expectation

- Hosting: marginal on the existing Hetzner k3s node (~€0)
- Plausible Analytics: ~€9/mo (lowest tier)
- Tally: free tier covers 100 signups/month — upgrade later if needed
- Domain renewal (asobi.dev): included in existing budget

**Total recurring: ~€9/mo** for the marketing site (down from ~€15–20/mo on Clever).
