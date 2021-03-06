#!/bin/bash

# Builds an image, builds the app under test/test_app via
# s2i and verifies the app works.
#
# This is written as a bash script rather than a rake task
# because we get easy free streaming output and debugging
# capabilities.

if [[ $# -ne 1 ]]; then
    echo "USAGE: test.sh PATH_TO_DIST_DIR"
    echo ""
    echo "E.g test.sh dist/rails/pure"
    exit 1
fi

set -e

docker_dir=$1
cd $(dirname $0)/..
root=$(pwd)

image_name=puzzle/ose3-rails-$(basename $docker_dir)
echo
echo "# Building $image_name from files in $docker_dir"
echo

cd $root/$docker_dir
docker build . -t $image_name | sed 's/^/   /'

echo
echo "# Building test app"

build=$image_name-test-app

cd $root/test/test_app
s2i build -c . $image_name $build 2>&1 \
    --incremental=true \
    | sed 's/^/   /'

function test_app() {
    additional_docker_args=$1
    url=$2

    echo "# Starting test app, waiting a second"

    container=$(
        docker run -d \
               -p 18080:8080 \
               -p 18443:8443 \
               $additional_docker_args $build)

    sleep 1

    echo "# Checking test app"

    set +e
    echo
    output=$(curl --insecure -o- $url)
    set -e

    if [[ $output == "works" ]]; then
        echo
        echo "RESULT: OK"
    else
        echo
        echo "RESULT: BROKEN"
        echo
        echo "-- Docker logs:"
        docker logs $container 2>&1 | sed 's/^/   /'
        echo
        echo "RESULT: BROKEN"
    fi

    echo
    echo "# Shutting down test app"

    docker kill $container
}

function create_ssl_certificates () {
    openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout server.key -out server.crt
}

cd $root

echo "# HTTP"
test_app "" "http://localhost:18080"

echo "# HTTPS"

bin/create_certificates.sh
test_app "--env USE_SSL=1 -v $root/test/certificates:/opt/certificates" "https://localhost:18443"
