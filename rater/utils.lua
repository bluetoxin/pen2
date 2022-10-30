-- Module with handy, reusable functions
local cjson = require("cjson")
local inspect = require("inspect")

local _M = {}

_M.load = function(dir)
  -- Load all Lua files in dir. Returns table with loaded files.
  local files = {}
  for file, _ in io.popen(("ls %s%s"):format(debug.getinfo(1).source:match("@?(.*/)"), dir)):lines() do
    if file:sub(-4) == ".lua" then
      files[file:sub(1, -5)] = require(("%s.%s"):format(dir, file:sub(1, -5)))
    end
  end
  return files
end

_M.log = function(...)
  -- Log pretty formatted custom messages
  local args = {
    n = select("#", ...),
    ...,
  }
  for arg = 1, args.n do
    if type(args[arg]) ~= "string" then
      ngx.log(ngx.ERR, inspect(args[arg]))
    else
      ngx.log(ngx.ERR, args[arg])
    end
  end
end

_M.decode = function(file)
  -- Decode json string into Lua table
  return cjson.decode(io.open(file, "r"):read("*a"))
end

_M.keys = function(dict)
  -- Get keys in table
  local keys = {}
  for key, _ in pairs(dict) do
    table.insert(keys, key)
  end
  return keys
end

_M.exists = function(item, dict)
  -- Check if "item" exists in dict
  for _, value in pairs(dict) do
    if value == item then
      return true
    end
  end
  return false
end

_M.get_nested = function(str, dict)
  -- Get nested table in dict using str 
  local result
  for nested in str:gmatch("(%w+)") do
    if not result then
      result = dict[nested]
    else
      result = result[nested]
    end
  end
  return result
end

_M.eval = function(str)
  -- Evaluates Lua code represented as a string and returns its completion value
  return assert(loadstring(("return %s"):format(str)))()
end

_M.get_path = function(file)
  -- Return path to specified file
  local pattern = ("{ find / -name %s 3>&2 2>&1 1>&3 | egrep -v '(Permission denied|Invalid argument)' >&3; } 3>&2 2>&1"):format(file)
  local path = io.popen(pattern):read("*a"):gsub("%s+", "")
  return path
end

return _M
