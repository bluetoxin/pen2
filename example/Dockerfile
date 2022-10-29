FROM openresty/openresty

RUN apt update && apt install net-tools procps curl luarocks -y
RUN luarocks install inspect

COPY /rater /usr/local/openresty/lualib/resty 
COPY /example/rules.json /usr/local/openresty/lualib/resty
COPY /libs /usr/local/openresty/lualib/resty/libs
COPY /example/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

