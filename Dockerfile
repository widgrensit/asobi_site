#
# Passthrough Dockerfile for Clever Cloud.
#
# The real image is built in GitHub Actions (see
# .github/workflows/docker-publish.yml) and published to GHCR. Clever's
# builder OOM-kills during rebar3 / erlfmt compilation on low-RAM nodes,
# so we have it pull the prebuilt image instead of rebuilding from source.
#
# Everything (Erlang release, CMD, EXPOSE, PORT) comes baked in via the
# source Dockerfile preserved at Dockerfile.build in this repo.
#
FROM ghcr.io/widgrensit/asobi_site:latest
