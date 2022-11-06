#!/usr/bin/env bash

get_log () {
  docker exec -ti pen2 cat /usr/local/openresty/nginx/logs/pen2.log
}

clean_log () {
  docker exec -ti pen2 sh -c ">/usr/local/openresty/nginx/logs/pen2.log"
}

make_request () {
  curl 127.0.0.1:8008
}

run_docker () {
  if docker ps | grep -q "pen2"
  then
    docker-compose -f ./docker/docker-compose.yml down
  fi
  docker build -f ./docker/Dockerfile -t pen2 .
  docker-compose -f ./docker/docker-compose.yml up -d
}

if [[ $1 == "log" ]]
then
  get_log
elif [[ $1 == "clean" ]]
then
  clean_log
elif [[ $1 == "request" ]]
then
  make_request
elif [[ $1 ==  "docker" ]]
then
  run_docker
else
  run_docker
  sleep 3
  make_request
  get_log
fi


