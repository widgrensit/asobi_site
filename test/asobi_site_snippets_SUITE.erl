%% @doc Guards the single-source-of-truth snippet module.
%%
%% - Every {Flow, SDK} pair must resolve to a non-empty binary.
%% - Every flow must mention the protocol keywords that prove the
%%   snippet still talks to the current server (e.g. "matchmaker" in
%%   the hero flow, "world" in the world flow).
%%
%% When a new flow is added in `asobi_site_snippets', extend
%% `required_keywords/1' so drift is caught here instead of on the
%% homepage.
-module(asobi_site_snippets_SUITE).
-compile([export_all, nowarn_export_all]).

-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").

all() ->
    [coverage, non_empty, required_keywords, label_coverage].

%%====================================================================

coverage(_Config) ->
    Flows = asobi_site_snippets:flows(),
    SDKs = asobi_site_snippets:sdks(),
    Missing = [
        {F, S}
     || F <- Flows,
        S <- SDKs,
        not is_binary(catch asobi_site_snippets:get(F, S))
    ],
    ?assertEqual([], Missing, "snippet coverage gap").

non_empty(_Config) ->
    Flows = asobi_site_snippets:flows(),
    SDKs = asobi_site_snippets:sdks(),
    Empty = [
        {F, S}
     || F <- Flows,
        S <- SDKs,
        byte_size(asobi_site_snippets:get(F, S)) < 20
    ],
    ?assertEqual([], Empty, "suspiciously short snippet").

required_keywords(_Config) ->
    Flows = asobi_site_snippets:flows(),
    SDKs = asobi_site_snippets:sdks(),
    Failures = [
        {F, S, K}
     || F <- Flows,
        S <- SDKs,
        K <- keywords_for(F),
        not contains(asobi_site_snippets:get(F, S), K)
    ],
    ?assertEqual([], Failures, "snippet missing required protocol keyword"),
    ok.

label_coverage(_Config) ->
    Missing = [S || S <- asobi_site_snippets:sdks(), not is_binary(catch asobi_site_snippets:sdk_label(S))],
    ?assertEqual([], Missing, "SDK label missing").

%%====================================================================

%% Keyword checks are deliberately forgiving — server-side snippets
%% (lua) don't touch client-side protocol strings, so we look for any
%% token that proves the snippet is for the right flow.

keywords_for(hero_connect) ->
    [~"match"];
keywords_for(connect_world) ->
    [~"world"];
keywords_for(_) ->
    [].

contains(Bin, Needle) when is_binary(Bin), is_binary(Needle) ->
    binary:match(string:lowercase(Bin), string:lowercase(Needle)) =/= nomatch.
