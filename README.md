**pen2** is an opensource flexible configurable waf.

* [Features](#features)
* [Usage](#usage)
* [FAQ](#faq)

## Features

_Detections:_
- SQLi (libinjection)  
- XSS (libinjection)

_Databases:_
- Memcached
- Redis

## Usage

```
git clone https://github.com/pinktoxin/pen2 ; chmod +x ./pen2/start.sh ; ./pen2/start.sh docker
```

What's next? Try to attack WEB Application!  

```
curl "127.0.0.1:8008/?b=<video%20poster=javascript:alert(1)//></video>" -H 'x-real-ip: 1.1.1.1' -H "a: test'--"
```

You should see the message "Your request has been blocked by WAF". Malicious pattern will be sent to Redis. You can attach to the Redis container if you want to see it.

```
docker exec -ti redis bash
redis-cli
LRANGE 1.1.1.1 0 -1
```

## FAQ

_What filters do I have for editing rules?_  

```
http = {
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
}
```

Rules under the hood use [wirefilter](https://github.com/cloudflare/wirefilter). The following filters are available. Feel free to use them.

_Can I set a different database for the rule?_  

```
{
  "http.ip == \"1.1.1.1\"": {
    "sqli": {
      "db_uri": "memcached://192.168.88.3:11211"
    },
    "xss": {
      "db_uri": "redis://192.168.88.2:6379"
    }
  }
}
```

You can set a new (supported by pen2) database for each rule. Currently only memcached and redis are implemented.
<br>