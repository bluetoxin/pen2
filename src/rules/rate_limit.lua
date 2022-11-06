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

_M.init = function(args)
  -- Check if rate_limit exceeds
  local current_timestamp = os.time(os.date("!*t"))
  local db_name, ip, port = utils.parse_db_str(args.db_uri)
  local db = log.connect(db_name, ip, port)
  local ban_until = db:lrange(ngx.ctx.http.ip, 0, -1)
  if next(ban_until) and math.max(unpack(ban_until)) > current_timestamp then
    ngx.status = 403
    ngx.say(ngx.ctx.block_page or os.getenv("BLOCK_PAGE"))
    ngx.exit(ngx.HTTP_FORBIDDEN)
  end
  local rates = obtain_rates(db, "rate_limit")
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
      tostring(current_timestamp + args.delay),
    }
  end
  return {}
end

return _M
