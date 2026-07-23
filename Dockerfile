FROM erlang:28 AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

COPY rebar.config rebar.lock ./
COPY scripts/strip-release-plugins.escript ./scripts/
RUN escript scripts/strip-release-plugins.escript rebar.config
RUN rebar3 compile --deps_only

COPY config ./config
COPY include ./include
COPY src ./src
COPY priv ./priv

RUN rebar3 as prod release

FROM debian:trixie-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libssl3 libncurses6 libstdc++6 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# uid 999 matches the runAsUser in deploy/k8s/asobi-site.yaml (kubelet
# rejects a named user under runAsNonRoot)
RUN groupadd -g 999 asobi && useradd -u 999 -g asobi -d /app asobi

COPY --from=builder --chown=asobi:asobi /app/_build/prod/rel/asobi_site ./

USER asobi

ENV PORT=8080
EXPOSE 8080

CMD ["bin/asobi_site", "foreground"]
