#!/bin/bash

function usage () {
  echo "Usage: ${cmd_name} macro_file [warp10_version]"
  exit $1
}

function cleanup_docker () {
  if [ -n "${container_id}" ]; then
    echo "Cleanup..."
    docker stop "${container_id}" >/dev/null
  fi
}

if [ $# -lt 1 ]; then
  echo "Missing arguments"
  usage 1
fi

cmd_name=$(basename $0)
macro=$1
warp10_version=${2:-"latest"}

if [ ! -f "${macro}" ]; then
  echo "The macro file does not exists"
  exit 1
fi

echo "Starting Warp10"
container_id=$(docker run -d --rm -p 8080 -v "$(pwd):/op/warp10/warpscripts" warp10io/warp10:${warp10_version})
container_post=$(docker inspect -f '{{ (index (index .NetworkSettings.Ports "8080/tcp") 0).HostPort }}' ${container_id})
echo "Waiting starting"
sleep 30
echo "Testing macro"
ret_code=$(curl -s -w "\n%{http_code}" --data-binary "@${macro}" -H "Content-Type: text/plain; charset=UTF-8" http://localhost:${container_post}/api/v0/exec)
if [ $(echo "${ret_code}" | tail -1) = "500" ]; then
  echo "Error in unit test"
  echo "---------------------- RESULT -------------------"
  echo ${ret_code}
  echo "-------------------------------------------------"
  cleanup_docker
  exit 1
fi
echo "Unit test valid"
cleanup_docker
exit 0
