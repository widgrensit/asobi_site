-module(asobi_site_docs_clustering_view).
-include_lib("arizona/include/arizona_stateful.hrl").

-export([mount/1, render/1]).

-spec mount(az:bindings()) -> az:mount_ret().
mount(Bindings) ->
    {
        maps:merge(#{id => ~"docs-clustering", title => ~"Clustering — Asobi docs"}, Bindings),
        #{}
    }.

-spec render(az:bindings()) -> az:template().
render(Bindings) ->
    Content = ?html(
        {'div', [], [
            {p, [{class, ~"docs-breadcrumb"}], [
                {a, [{href, ~"/docs"}, az_navigate], [~"Docs"]},
                ~" / Clustering"
            ]},
            {h1, [], [~"Clustering"]},
            {p, [{class, ~"docs-lede"}], [
                ~"Run multiple Asobi nodes as one cluster: horizontal scale for connections and matches, plus automatic failover. ",
                ~"Presence, chat, and cross-match messaging are cluster-safe out of the box via ",
                {code, [], [~"pg"]},
                ~"."
            ]},

            {'div', [{class, ~"docs-callout"}], [
                {p, [], [
                    {strong, [], [~"Asobi is single-node by design for gameplay. "]},
                    ~"A match lives on one node; the world server's zones live on one node. Clustering is for connection termination, cross-node messaging, and failover \x{2014} not for live cross-node zone migration. Shard at the app level (e.g. route players by region)."
                ]}
            ]},

            {h2, [], [~"What's cluster-safe"]},
            {ul, [], [
                {li, [], [
                    {code, [], [~"pg"]},
                    ~"-scoped process groups \x{2014} presence, chat channels, world/match whereis lookups work cross-node."
                ]},
                {li, [], [
                    ~"Player sessions: a session on node A can send to a match on node B (proxied via ",
                    {code, [], [~"pg"]},
                    ~" lookup)."
                ]},
                {li, [], [
                    ~"Storage (Postgres) is shared; everything persistent is consistent across nodes."
                ]},
                {li, [], [
                    ~"Matchmaker is replicated (one gen_server per node, tickets are in PG; any node can match)."
                ]}
            ]},

            {h2, [], [~"What isn't"]},
            {ul, [], [
                {li, [], [
                    ~"A match/world process ",
                    {em, [], [~"does not"]},
                    ~" migrate between nodes. If the owning node dies, active matches on it are lost (though state persists for post-mortem)."
                ]},
                {li, [], [
                    ~"ETS caches (zone entity snapshots, rate limits) are per-node. Hot paths assume local access."
                ]},
                {li, [], [
                    ~"Luerl VMs are per-process and per-node \x{2014} no shared script state across nodes."
                ]}
            ]},

            {h2, [], [~"Forming a cluster"]},
            {p, [], [
                ~"Asobi uses the BEAM's distribution protocol. Give each node a long name, share a cookie, and let the ",
                {code, [], [~"asobi_cluster"]},
                ~" discovery loop (configured below) connect them. Out of the box the image only reads ",
                {code, [], [~"ASOBI_PORT"]},
                ~", ",
                {code, [], [~"ASOBI_DB_*"]},
                ~", and ",
                {code, [], [~"ASOBI_CORS_ORIGINS"]},
                ~" \x{2014} set node name and cookie with the standard ",
                {code, [], [~"-name"]},
                ~"/",
                {code, [], [~"-setcookie"]},
                ~" VM flags."
            ]},
            {p, [], [~"Or from a running shell:"]},
            code(
                ~"erlang",
                ~"""
net_adm:ping('asobi@10.0.0.1').
nodes().          %% ['asobi@10.0.0.1']
"""
            ),

            {h2, [], [~"Service discovery"]},
            {p, [], [
                ~"Asobi ships a tiny discovery loop (",
                {code, [], [~"asobi_cluster"]},
                ~") with two strategies \x{2014} DNS (for Kubernetes headless services) and EPMD (for a static list of hosts). It resolves peer addresses, derives node names by reusing the current node's base name, and pings them periodically."
            ]},
            code(
                ~"erlang",
                ~"""
%% DNS (Kubernetes headless service):
{asobi, [
    {cluster, #{
        strategy      => dns,
        dns_name      => ~"asobi-headless",
        poll_interval => 10000
    }}
]}

%% EPMD (static host list):
{asobi, [
    {cluster, #{
        strategy      => epmd,
        hosts         => ['asobi-1.example.internal', 'asobi-2.example.internal'],
        poll_interval => 10000
    }}
]}
"""
            ),

            {h2, [], [~"Routing players to nodes"]},
            {p, [], [
                ~"Put a load balancer in front of the cluster with a ",
                {strong, [], [~"sticky WebSocket"]},
                ~" cookie, or hash on ",
                {code, [], [~"player_id"]},
                ~" at the LB. This keeps a player's session on one node; cross-node calls happen only for matches/worlds the player joins on a different node."
            ]},

            {h2, [], [~"Deployment"]},
            {p, [], [
                ~"Rolling restarts are safe: drain a node (stop accepting new matches, wait for existing ones to finish), upgrade, rejoin. Sessions on the drained node reconnect to another node when the LB routes them."
            ]},

            {h2, [], [~"Observability"]},
            {p, [], [
                ~"Cluster-wide metrics surface via ",
                {code, [], [~"telemetry"]},
                ~" events under ",
                {code, [], [~"[asobi, match, *]"]},
                ~", ",
                {code, [], [~"[asobi, zone, *]"]},
                ~", and ",
                {code, [], [~"[asobi, matchmaker, *]"]},
                ~". Wire them into Prometheus via ",
                {code, [], [~"telemetry_metrics_prometheus"]},
                ~" or ship them to any OpenTelemetry collector."
            ]},

            {h2, [], [~"Where next?"]},
            {ul, [], [
                {li, [], [{a, [{href, ~"/docs/self-host"}, az_navigate], [~"Self-host"]}]},
                {li, [], [{a, [{href, ~"/docs/performance"}, az_navigate], [~"Performance tuning"]}]},
                {li, [], [{a, [{href, ~"/docs/configuration"}, az_navigate], [~"Configuration reference"]}]}
            ]}
        ]}
    ),
    asobi_site_docs_shell:render(maps:get(id, Bindings), ~"/docs/clustering", Content).

code(Lang, Body) ->
    ?html({pre, [], [{code, [{class, iolist_to_binary([~"language-", Lang])}], [Body]}]}).
