-- Handy functions for working with libinjection
local ffi = require("ffi")
local utils = require("utils")

ffi.cdef [[
const char* libinjection_sqli_fingerprint(struct libinjection_sqli_state* sql_state, int flags);

struct libinjection_sqli_token {
	char type;
	char str_open;
	char str_close;
	size_t pos;
	size_t len;
	int count;
	char val[32];
};

typedef char (*ptr_lookup_fn)(struct libinjection_sqli_state*, int lookuptype, const char* word, size_t len);

struct libinjection_sqli_state {
	const char *s;
	size_t slen;
	ptr_lookup_fn lookup;
	void* userdata;
	int flags;
	size_t pos;
	struct libinjection_sqli_token tokenvec[8];
	struct libinjection_sqli_token *current;
	char fingerprint[8];
	int reason;
	int stats_comment_ddw;
	int stats_comment_ddx;
	int stats_comment_c;
	int stats_comment_hash;
	int stats_folds;
	int stats_tokens;
};

void libinjection_sqli_init(struct libinjection_sqli_state * sf, const char *s, size_t len, int flags);
int libinjection_is_sqli(struct libinjection_sqli_state* sql_state);

int libinjection_sqli(const char* s, size_t slen, char fingerprint[]);

int libinjection_is_xss(const char* s, size_t len, int flags);
int libinjection_xss(const char* s, size_t slen);
]]

local lib = ffi.load(utils.get_path("libinjection.so"))

local _M = {}

_M.xss = function(string)
  -- Given a string, returns a boolean denoting if XSS was detected
  return lib.libinjection_xss(string, #string) == 1
end

_M.sqli = function(string)
  -- Given a string, returns a boolean indicating a match 
  local fingerprint = ffi.new("char [8]")
  return lib.libinjection_sqli(string, #string, fingerprint) == 1
end

_M.get_triggers = function(request_data, type)
  -- Checks for triggers in request_data
  local triggers = {}
  for _, request_table in pairs(request_data) do
    for param, value in pairs(request_table) do
      local detected = _M[type](value)
      if detected then
        table.insert(triggers, ("%s=%s"):format(param, value))
      end
    end
  end
  return triggers
end

return _M
