local utils = require("utils")

local _M = {}

_M.access = function(args)
  utils.log("rate_limit access")
end

_M.log = function(args)
  utils.log("rate_limit log")
end

return _M
