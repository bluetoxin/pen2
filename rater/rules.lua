-- Module for parsing rules
local utils = require("utils")
local cjson = require("cjson")
local ffi = require("ffi")
local inspect = require("inspect")

ffi.cdef [[
    typedef struct wirefilter_scheme wirefilter_scheme_t;
    typedef struct wirefilter_filter_ast wirefilter_filter_ast_t;
  
    typedef struct wirefilter_rust_allocated_str {
        const char *data;
        size_t length;
    } wirefilter_rust_allocated_str_t;
  
    typedef struct wirefilter_externally_allocated_str {
        const char *data;
        size_t length;
    } wirefilter_externally_allocated_str_t;
  
    typedef union wirefilter_parsing_result {
        uint8_t success;
        struct {
            uint8_t _res1;
            wirefilter_rust_allocated_str_t msg;
        } err;
        struct {
            uint8_t _res2;
            wirefilter_filter_ast_t *ast;
        } ok;
    } wirefilter_parsing_result_t;
  
    typedef enum {
        WIREFILTER_TYPE_IP,
        WIREFILTER_TYPE_BYTES,
        WIREFILTER_TYPE_INT,
        WIREFILTER_TYPE_BOOL,
    } wirefilter_type_t;
  
    wirefilter_scheme_t *wirefilter_create_scheme();
  
    void wirefilter_add_type_field_to_scheme(
        wirefilter_scheme_t *scheme,
        wirefilter_externally_allocated_str_t name,
        wirefilter_type_t type
    );
  
    wirefilter_parsing_result_t wirefilter_parse_filter(
        const wirefilter_scheme_t *scheme,
        wirefilter_externally_allocated_str_t input
    );
  
    wirefilter_rust_allocated_str_t wirefilter_serialize_filter_to_json(
      const wirefilter_filter_ast_t *ast
    );
]]

local libwirefilter = ffi.load("/usr/local/openresty/lualib/resty/libs/libwirefilter.so")
local str_t = ffi.typeof("wirefilter_externally_allocated_str_t")

local function to_str(str)
  -- Returns wirefilter string
  return str_t(str, #str)
end

local function get_rhs_type(rhs, op)
  -- Determine the type of the right operator in condition
  -- IP type equals 0
  -- BYTES type equals 1
  -- INT type equals 2
  -- BOOL type equals 3
  local decimal = {">=", "<=", ">", "<"}
  local boolean = {"or", "and"}

  if (boolean[op]) or (not rhs and not op) then
    return 3
  elseif decimal[op] then
    return 2
  elseif rhs:match("%d%.%d%.%d%.%d") and not rhs:match("[\"]") then
    return 0
  else
    return 1
  end
end

local function get_ast(condition)
  -- Parses condition into AST using wirefilter
  local scheme = libwirefilter.wirefilter_create_scheme()
  for lhs in condition:gmatch("(http%.[^%s%)]+)") do
    local op, rhs = condition:match(lhs .. "%s*%)?%s+([^%s]+)%s+([^%s]+)")
    local filter_type = get_rhs_type(rhs, op)
    libwirefilter.wirefilter_add_type_field_to_scheme(scheme, to_str(lhs), filter_type)
    local filter_p = libwirefilter.wirefilter_parse_filter(scheme, to_str(condition))
    if filter_p.err._res1 == 1 then
      local res = libwirefilter.wirefilter_serialize_filter_to_json(filter_p.ok.ast)
      return cjson.decode(ffi.string(res.data):sub(1, tonumber(res.length)))
    else
      utils.log(("Can't Compile. Bad condition: %s."):format(condition))
    end
  end
end

local function parse_ast(ast)
  -- Recursive AST Parsing
  -- Returns str like "{ true, "or", { false, "and", false } }"
  local items
  if ast.items then
    items = {}
    for iter, item in pairs(ast.items) do
      table.insert(items, parse_ast(item))
      if iter ~= #ast.items then
        table.insert(items, ast.op:lower())
      end
    end
  else
    if type(ast.rhs) == "string" then
      ast.rhs = {ast.rhs}
    end
    return utils.exists(utils.get_nested(ast.lhs, ngx.ctx), ast.rhs)
  end
  return items
end

local function check_condition(condition)
  -- Checks if the condition is true
  local replacement = {
    ["\""] = "",
    [","] = "",
    ["{"] = "(",
    ["\","] = "",
    ["}"] = ")",
  }
  local ast = parse_ast(get_ast(condition))
  local parsed_ast = inspect(ast):gsub("[{}\",]+", replacement)
  return utils.eval(parsed_ast)
end

local _M = {}

_M.obtain = function(config, actions, actions_to_run)
  -- Obtain actions to run
  for key, statement in pairs(config) do
    if utils.exists(key, actions) then
      actions_to_run[key] = statement
    elseif key:match("http%.") then
      if check_condition(key) then
        -- If condition is true dive in
        _M.obtain(statement, actions, actions_to_run)
      end
    end
  end
  return actions_to_run
end

return _M
