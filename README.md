**pen2** is an opensource flexible configurable rate limits.


* [Usage](#usage)
* [FAQ](#faq)


## Usage

```
git clone https://github.com/bluetoxin/pen2 ; chmod +x ./pen2/start.sh ; ./pen2/start.sh docker
```

What's next? Try to attack WEB Application!  

```
for i in {1..40} ; do curl 127.0.0.1:8008 -H 'x-real-ip: 1.1.1.1' ; done
```

You should see the message "Your request has been blocked by WAF".

## FAQ

_What filters do I have for editing rules?_  

```
http = {
    request = {
      path = {ngx.var.uri} or {},
      query = {ngx.var.args} or {},
      body = {ngx.req.get_body_data()} or {},
      uri = ngx.req.get_uri_args() or {},
      headers = ngx.req.get_headers() or {},
    },
    ip = ngx.var.remote_addr,
    proto = ngx.var.scheme,
    port = ngx.var.server_port,
    host = ngx.var.host,
  }
}
```

Rules under the hood use [wirefilter](https://github.com/cloudflare/wirefilter). The following filters are available. Feel free to use them.


<br>
