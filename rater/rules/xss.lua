local utils = require("utils")

local _M = {}

_M.access = function(args)
  utils.log("xss access")
end

return _M
