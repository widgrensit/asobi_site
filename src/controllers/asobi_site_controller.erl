-module(asobi_site_controller).

-export([heartbeat/1]).

-spec heartbeat(cowboy_req:req()) -> {status, integer()}.
heartbeat(_Req) ->
    {status, 200}.
