FROM openresty/openresty

RUN apt update && apt install net-tools procps curl luarocks -y
RUN luarocks install inspect

COPY /src /usr/local/openresty/lualib/resty 
COPY /docker/rules.json /usr/local/openresty/lualib/resty
COPY /libs /usr/local/openresty/lualib/resty/libs
COPY /docker/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

