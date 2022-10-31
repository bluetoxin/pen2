local injections = require("injections")

local _M = {}

_M.access = function(request_data)
  return injections.get_triggers(request_data, "xss")
end

return _M
