-- Main module
local utils = require("utils")
local rules = require("rules")

local phases = {
  ["rate_limit"] = {"access", "log"},
  ["xss"] = {"access"},
  ["sqli"] = {"access"},
}

local actions = utils.load("rules")

local function run_actions(phase)
  -- Run actions in right openresty phase
  for action_name, action_param in pairs(ngx.ctx.actions) do
    if utils.exists(phase, phases[action_name]) then
      actions[action_name][phase](action_param)
    end
  end
end

local function create_context(config)
  -- Creates ngx.ctx for current request
  local http = {
    user = {ip = ngx.var.remote_addr},
  }
  ngx.ctx.http = http

  local actions_to_run = rules.obtain(utils.decode(config), utils.keys(actions))
  ngx.ctx.actions = actions_to_run
end

local _M = {}

_M.run = function(config)
  -- Runs rater
  local phase = ngx.get_phase()
  if phase == "access" then
    create_context(config)
  end
  run_actions(phase)
end

return _M
