#!/usr/bin/env sh

get_log () {
  docker exec -ti rater cat /usr/local/openresty/nginx/logs/my.log
}

clean_log () {
  docker exec -ti rater sh -c ">/usr/local/openresty/nginx/logs/my.log"
}

make_request () {
  curl 127.0.0.1:8008
}

run_docker () {
  if docker ps | grep -q "rater"
  then
    docker-compose -f ./example/docker-compose.yml down
  fi
  docker build -f ./example/Dockerfile -t rater .
  docker-compose -f ./example/docker-compose.yml up -d
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


