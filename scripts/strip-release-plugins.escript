#!/usr/bin/env escript
%% Strip dev-only project_plugins from a rebar.config in place so the
%% release image does not compile tooling it never runs (sbom, formatter).
%% Derives from the real rebar.config at build time, so it cannot drift.
main([Path]) ->
    {ok, Terms} = file:consult(Path),
    Drop = [rebar3_sbom, erlfmt],
    Keep = fun(Plugins) -> [P || P <- Plugins, not lists:member(element(1, P), Drop)] end,
    Rewritten = [
        case Term of
            {project_plugins, Plugins} -> {project_plugins, Keep(Plugins)};
            Other -> Other
        end
     || Term <- Terms
    ],
    ok = file:write_file(Path, [io_lib:format("~tp.~n", [T]) || T <- Rewritten]).
