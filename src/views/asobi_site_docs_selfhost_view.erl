-module(asobi_site_docs_selfhost_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {maps:merge(#{id => ~"docs-selfhost", title => ~"Self-host — Asobi docs"}, Bindings), #{}}.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Self-host"
            ]},
            {h1, [], [~"Self-host Asobi"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Asobi is fully open-source and designed to be run on your own infrastructure. ",
                ~"This guide walks through three deployment targets: Docker Compose (dev), a single server (production), and Kubernetes (scale)."
            ]},

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Prefer managed? "]},
                    ~"Asobi Cloud is coming \x{2014} fully managed game servers, EU-sovereign hosting, per-environment scaling. ",
                    {a, [{href, ~"/cloud"}, az_navigate], [~"Join the waitlist at asobi.dev/cloud."]}
                ]}
            ]},

            {h2, [], [~"Deployment targets"]},
            {'div', [{class, ~"docs-grid"}], [
                {a, [{href, ~"#docker-compose"}, {class, ~"docs-card"}], [
                    {h3, [], [~"Docker Compose"]},
                    {p, [], [
                        ~"Single machine, everything local. Great for dev, prototyping, and small productions."
                    ]}
                ]},
                {a, [{href, ~"#single-server"}, {class, ~"docs-card"}], [
                    {h3, [], [~"Single VPS"]},
                    {p, [], [
                        ~"One Hetzner/DigitalOcean box, Erlang release, systemd. Supports hundreds of CCU."
                    ]}
                ]},
                {a, [{href, ~"#kubernetes"}, {class, ~"docs-card"}], [
                    {h3, [], [~"Kubernetes"]},
                    {p, [], [
                        ~"Scaleway Kapsule or similar. Container-per-game-env, full isolation, scale horizontally."
                    ]}
                ]}
            ]},

            {h2, [{id, ~"docker-compose"}], [~"Docker Compose"]},
            {p, [], [
                ~"The quickest way to run a real Asobi stack. Save this as ",
                {code, [], [~"docker-compose.yml"]},
                ~":"
            ]},
            code(
                ~"yaml",
                ~"""
services:
  postgres:
    image: postgres:17
    environment:
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: asobi
    volumes: [pgdata:/var/lib/postgresql/data]
    ports: ["5432:5432"]

  asobi:
    image: ghcr.io/widgrensit/asobi_lua:latest
    depends_on: [postgres]
    environment:
      ASOBI_DB_HOST: postgres
      ASOBI_DB_NAME: asobi
      ASOBI_DB_USER: postgres
      ASOBI_DB_PASSWORD: postgres
      ERLANG_COOKIE: ${ERLANG_COOKIE}
    ports: ["8080:8080"]
    volumes:
      - ./game:/app/game:ro

volumes:
  pgdata:
"""
            ),
            {p, [], [
                ~"Generate a cookie, then boot the stack:"
            ]},
            code(
                ~"bash",
                ~"""
export ERLANG_COOKIE=$(openssl rand -hex 32)
docker compose up -d
"""
            ),
            {p, [], [
                ~"Asobi is now running on ",
                {code, [], [~"http://localhost:8080"]},
                ~". Deploy your game with ",
                {code, [], [~"asobi deploy ./game"]},
                ~" and you're live."
            ]},

            {h2, [{id, ~"single-server"}], [~"Single VPS"]},
            {p, [], [
                ~"For production on a single machine \x{2014} a Hetzner AX41 (\x{20AC}40/mo) comfortably handles hundreds of concurrent players. ",
                ~"Build a release from the Asobi source:"
            ]},
            code(
                ~"bash",
                ~"""
git clone https://github.com/widgrensit/asobi
cd asobi
rebar3 as prod release

# The release is at _build/prod/rel/asobi/
# Copy it to the server, run with:
bin/asobi daemon
"""
            ),
            {p, [], [
                ~"Configure the release via ",
                {code, [], [~"config/prod_sys.config.src"]},
                ~" \x{2014} environment variables, database credentials, and TLS settings are all there. See ",
                {a, [{href, ~"https://github.com/widgrensit/asobi/tree/main/config"}], [
                    ~"the config directory"
                ]},
                ~" for full examples."
            ]},

            {h3, [], [~"Systemd unit"]},
            code(
                ~"ini",
                ~"""
# /etc/systemd/system/asobi.service
[Unit]
Description=Asobi game backend
After=network.target postgresql.service

[Service]
Type=notify
User=asobi
Environment=ERLANG_COOKIE=generate-a-real-one
Environment=HOME=/var/lib/asobi
ExecStart=/opt/asobi/bin/asobi foreground
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
"""
            ),

            {h3, [], [~"Reverse proxy (Caddy)"]},
            code(
                ~"caddy",
                ~"""
game.example.com {
    reverse_proxy localhost:8080
}
"""
            ),
            {p, [], [
                ~"Caddy auto-issues TLS certs and handles WebSocket upgrades without config. ",
                ~"Nginx works equally well \x{2014} make sure ",
                {code, [], [~"proxy_set_header Upgrade $http_upgrade"]},
                ~" is set."
            ]},

            {h2, [{id, ~"kubernetes"}], [~"Kubernetes"]},
            {p, [], [
                ~"For multi-tenant or multi-game deployments, run one pod per game-env. ",
                ~"Our reference infra repo (",
                {a, [{href, ~"https://github.com/widgrensit/asobi-infra"}], [
                    ~"widgrensit/asobi-infra"
                ]},
                ~") ships a Helm stack for Scaleway Kapsule: cert-manager, Prometheus, Loki, Velero, and CloudNativePG."
            ]},
            {p, [], [~"A minimal Deployment looks like this:"]},
            code(
                ~"yaml",
                ~"""
apiVersion: apps/v1
kind: Deployment
metadata:
  name: asobi-my-game-live
  namespace: tenant-widgrensit
spec:
  replicas: 1
  template:
    spec:
      containers:
        - name: engine
          image: ghcr.io/widgrensit/asobi_lua:latest
          env:
            - name: ASOBI_DB_HOST
              valueFrom:
                secretKeyRef: { name: pg-credentials, key: host }
            - name: ERLANG_COOKIE
              valueFrom:
                secretKeyRef: { name: erlang-cookie, key: cookie }
          ports:
            - containerPort: 8080
          resources:
            requests: { cpu: 100m, memory: 256Mi }
            limits:   { cpu: 1000m, memory: 1Gi }
"""
            ),
            {p, [], [
                ~"See the ",
                {a, [{href, ~"https://github.com/widgrensit/asobi-infra"}], [~"asobi-infra repo"]},
                ~" for the full cluster setup, NetworkPolicies, and tenant isolation patterns."
            ]},

            {h2, [], [~"Backups"]},
            {ul, [], [
                {li, [], [
                    {strong, [], [~"Postgres: "]},
                    ~"everything Asobi persists lives in Postgres. Back up continuously (WAL shipping to S3-compatible storage) or at least nightly."
                ]},
                {li, [], [
                    {strong, [], [~"Lua bundles: "]},
                    ~"your game source lives in git. That's the backup."
                ]},
                {li, [], [
                    {strong, [], [~"Zone snapshots: "]},
                    ~"persistent worlds snapshot their state to Postgres every tick interval. They're restored automatically on startup."
                ]}
            ]},

            {h2, [], [~"Security checklist"]},
            {ul, [], [
                {li, [], [~"Rotate the Erlang cookie. Never use a default value."]},
                {li, [], [
                    ~"Set ",
                    {code, [], [~"verify_peer"]},
                    ~" for any outbound HTTPS (already the default in asobi)."
                ]},
                {li, [], [
                    ~"Enable TLS in the reverse proxy; don't expose the raw ",
                    {code, [], [~"8080"]},
                    ~" port to the public internet."
                ]},
                {li, [], [~"Enable Postgres SSL for connections from other hosts."]},
                {li, [], [
                    ~"Run the engine as a non-root user (the Docker image does this; bare metal should too)."
                ]},
                {li, [], [~"Treat deploy keys like passwords. Rotate on employee offboarding."]}
            ]},

            {h2, [], [~"Upgrades"]},
            {p, [], [
                ~"Asobi releases are hot-code-loadable on the BEAM. For minor version bumps, deploy the new release and existing matches finish on the old code; new matches use the new code. No downtime.",
                ~" For major version bumps (breaking schema changes), run migrations via ",
                {code, [], [~"rebar3 kura migrate"]},
                ~" in a maintenance window."
            ]},

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [
                    {a, [{href, ~"/docs/concepts"}, az_navigate], [~"Core concepts"]},
                    ~" \x{2014} understand what the engine runs."
                ]},
                {li, [], [
                    {a, [{href, ~"https://github.com/widgrensit/asobi-infra"}], [~"asobi-infra"]},
                    ~" \x{2014} reference Helm stack for managed k8s."
                ]},
                {li, [], [
                    {a, [{href, ~"/cloud"}, az_navigate], [~"Asobi Cloud"]},
                    ~" \x{2014} managed hosting, coming soon."
                ]}
            ]}
        ]}
    ).
code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
