# Security

Report vulnerabilities privately via [GitHub security advisories](https://github.com/widgrensit/asobi_site/security/advisories/new).

## Accepted advisories

CI audit (`rebar3 audit`) skips the IDs below. Each has no upstream fix and does not apply to this site.

| Advisory | Dependency | Why accepted |
|----------|------------|--------------|
| GHSA-g2wm-735q-3f56 (CVE-2026-43969) | cowlib `cow_cookie:cookie/1` | LOW; vulnerable `<= 2.16.1`, no fixed release yet. The site is a static marketing/docs app with no sessions or cookies, so the cookie encoder is never used. Drop this entry once cowlib ships a fix above 2.16.1. |
