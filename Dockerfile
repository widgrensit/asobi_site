FROM erlang:28 AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

COPY rebar.config rebar.lock ./
RUN rebar3 compile --deps_only

COPY config ./config
COPY src ./src
COPY priv ./priv

RUN rebar3 as prod release

FROM debian:trixie-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libssl3 libncurses6 libstdc++6 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/_build/prod/rel/asobi_site ./

ENV PORT=8080
EXPOSE 8080

CMD ["bin/asobi_site", "foreground"]
