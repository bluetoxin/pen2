-- Main module
local utils = require("utils")
local rules = require("rules")
local log = require("log")

local phases = {
  ["rate_limit"] = {"access", "log"},
  ["xss"] = {"access"},
  ["sqli"] = {"access"},
}

local supported_dbs = {
  "redis", "memcached",
}

local actions = utils.load("rules")

local function log_trigger(trigger)
  -- Check for formatting and run log[db]
  if trigger["db"] and utils.exists(trigger["db"]:match("%a+"), supported_dbs) then
    local db, ip, port = trigger["db"]:match("(%a+)://([%d%.%a]+):(%d+)")
    if db and ip and port then
      log[db](ip, port, unpack(trigger["trigger"]))
    else
      utils.log("Invalid format. Path to db should looks like: 'db://ip:port'.")
    end
  end
end

local function run_actions(phase)
  -- Run actions in right openresty phase
  for action_name, action_param in pairs(ngx.ctx.actions) do
    if utils.exists(phase, phases[action_name]) then
      local trigger = {
        ["trigger"] = actions[action_name][phase](ngx.ctx.http.request, action_param),
        ["db"] = action_param.log or ngx.ctx.default.db or os.getenv("DB_URI"),
      }
      if next(trigger["trigger"]) then
        -- Log trigger and send response 
        log_trigger(trigger)
      end
    end
  end
end

local function create_context(config)
  -- Creates ngx.ctx for current request
  local http = {
    request = {
      -- Params to check for malicious patterns
      path = {ngx.var.uri} or {},
      query = {ngx.var.args} or {},
      body = {ngx.req.get_body_data()} or {},
      uri = ngx.req.get_uri_args() or {},
      headers = ngx.req.get_headers() or {},
    },
    -- Additional info for filtering in rules.json
    ip = ngx.var.remote_addr,
    proto = ngx.var.scheme,
    port = ngx.var.server_port,
    host = ngx.var.host,
  }
  ngx.ctx.http = http

  local actions_to_run = rules.obtain(utils.decode(config), utils.keys(actions), {})
  ngx.ctx.actions = actions_to_run
end

local _M = {}

_M.run = function()
  -- Runs rater
  local phase = ngx.get_phase()
  if phase == "access" then
    create_context(ngx.ctx.rules_path or os.getenv("RULES_PATH"))
  end
  run_actions(phase)
end

return _M
