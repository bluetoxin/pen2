# rater

**rater** is an opensource flexible configurable waf.

* [Detection](#detection)
* [Usage](#usage)
* [Licence](#licence)

## Detection

- SQLi (libinjection)  
- XSS (libinjection) 

## Usage

```
git clone https://github.com/pinktoxin/rater ; chmod +x ./rater/start.sh ; ./rater/start.sh docker
```

What's next? Try to attack WEB Application!  

```
curl "127.0.0.1:8008/?b=<video%20poster=javascript:alert(1)//></video>" -H 'x-real-ip: 1.1.1.1' -H "a: test'--"
```

You should see the message "Your request has been blocked by WAF" and the malicious pattern will be hosted in Redis. You can attach to the Redis container if you want to see it.

```
docker exec -ti redis bash
redis-cli
LRANGE 1.1.1.1 0 -1
```
