-- Main module
local utils = require("utils")
local rules = require("rules")
local log = require("log")

local actions = utils.load("rules")

local function log_triggers(triggers)
  -- Check for formatting and run log[db]
  for _, trigger in pairs(triggers) do
    local db, ip, port = utils.parse_db_str(trigger["db"])
    log[db](ip, port, unpack(trigger["trigger"]))
  end
end

local function run_actions()
  -- Run actions in right openresty phase
  local triggers = {}
  for action_name, action_param in pairs(ngx.ctx.actions) do
    if type(action_param) ~= "table" then
      action_param = {action_param}
    end
    local trigger = {
      ["trigger"] = actions[action_name]["init"](ngx.ctx.http.request, action_param),
      ["db"] = action_param.db_uri,
    }
    if next(trigger["trigger"]) then
      -- Log trigger and send response 
      table.insert(triggers, trigger)
    end
  end
  return triggers
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
  -- Runs WAF
  create_context(ngx.ctx.rules_path or os.getenv("RULES_PATH"))
  local triggers = run_actions()
  if next(triggers) then
    -- If a malicious pattern is found
    ngx.status = 403
    ngx.say(ngx.ctx.block_page or os.getenv("BLOCK_PAGE"))
    log_triggers(triggers)
    ngx.exit(ngx.HTTP_FORBIDDEN)
  end
end

return _M
