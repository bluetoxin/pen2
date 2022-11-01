local utils = require("utils")
local log = require("log")

local function obtain_rates(db, hashmap)
  -- Returns table with rates
  local raw_rates, _ = db:hgetall(hashmap)
  local rates = {}
  for iter = 1, #raw_rates, 2 do
    rates[raw_rates[iter]] = raw_rates[iter + 1]
  end
  return rates
end

local _M = {}

_M.init = function(_, args)
  -- Check if rate_limit exceeds
  local db_name, ip, port = utils.parse_db_str(args.db_uri)
  if db_name ~= "redis" then
    utils.log("Only redis can be used for rate limiting.")
  end
  local db = log.connect(db_name, ip, port)
  local rates = obtain_rates(db, "rate_limit")
  local current_timestamp = os.time(os.date("!*t"))
  if not rates[ngx.ctx.http.ip] then
    rates[ngx.ctx.http.ip] = ("0:%s"):format(current_timestamp)
  end
  local rate, timestamp = rates[ngx.ctx.http.ip]:match("(%d+):(%d+)")
  -- Increase record
  local ok, err = db:hset("rate_limit", ngx.ctx.http.ip, ("%s:%s"):format(tostring(tonumber(rate) + 1), timestamp))
  log.log_err(ok, err)
  if current_timestamp - tonumber(timestamp) > args.rate then
    -- If time exceeds
    ok, err = db:hset("rate_limit", ngx.ctx.http.ip, ("%s:%s"):format("1", current_timestamp))
    log.log_err(ok, err)
  elseif args.amount == tonumber(rate) then
    return {
      ("rate_limit=%s"):format(current_timestamp + args.delay),
    }
  end
  return {}
end

return _M
