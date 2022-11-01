-- Module with different logging methods
local utils = require("utils")

local _M = {}

_M.connect = function(db_name, ip, port)
  -- Wrapper for connection to DB. Returns writable socket
  local loaded_db = require(("resty.%s"):format(db_name))
  local db = loaded_db:new()
  local ok, err = db:connect(ip, port)
  if not ok then
    utils.log(("Can't connect to %s. Error: %s."):format(db_name, err))
  end
  return db
end

_M.log_err = function(ok, err)
  -- Log an err if set failure
  if not ok then
    utils.log(("Internal Error: %s."):format(err))
  end
end

_M.memcached = function(ip, port, trigger)
  -- Log to Memcached
  local db = _M.connect("memcached", ip, port)
  local res, _ = db:get(ngx.ctx.http.ip)
  local ok, err
  if res then
    ok, err = db:append(ngx.ctx.http.ip, " ; " .. trigger)
  else
    ok, err = db:set(ngx.ctx.http.ip, trigger)
  end
  _M.log_err(ok, err)
end

_M.redis = function(ip, port, trigger)
  -- Log to Redis
  local db = _M.connect("redis", ip, port)
  local ok, err = db:lpush(ngx.ctx.http.ip, trigger)
  _M.log_err(ok, err)
end

return _M
