#!/bin/bash

# script used to allow start the PoC setup.
#
# Can use specific tags:
#
# Official:
#   ruby:3.0.2-buster
#   ruby latest
#
# Bash based.

image=${1:-'ghcr.io/appoptics/appoptics-apm-ruby/apm_ruby_ubuntu:latest'} 

# for the current branch - make sure name and S3 are setup to dev.
echo_section() {
    echo ""
    echo "$1"
    echo "****************"
    echo ""
}

cleanup() {
    docker-compose -f "./otel-collector/docker-compose.yaml" down

    # remove artifacts left locally by previous bundle install
    rm -rf appoptics-legacy/vendor
    rm -rf appoptics-w3c/vendor
    rm -rf otel/vendor

    rm appoptics-legacy/Gemfile.lock
    rm appoptics-w3c/Gemfile.lock
    rm otel/Gemfile.lock

    rm -rf appoptics-legacy/.bundle
    rm -rf aappoptics-w3c/.bundle
    rm -rf otel/.bundle

    docker stop "$container_id"
    docker rm "$container_id"
}

set -e
trap cleanup EXIT

echo_section "OTel Collector Setup"

docker-compose -f "./otel-collector/docker-compose.yaml" up -d

echo_section "Container Setup"

# pull a standard image
docker pull "$image"

# open a shell in detached mode
container_id=$(docker run -itd \
    -h "${image}" \
    -w /usr/src/work \
    -v "$(pwd)":/usr/src/work \
    -v "$(pwd)"/../appoptics-apm-ruby:/usr/src/work/gem \
    -p 4000:4000 \
    -p 4100:4100 \
    -p 4200:4200 \
    --env-file .env \
    "$image" bash)

echo_section "Bundle install"

docker exec "$container_id" bash -c "bundle config set --local path 'vendor/bundle'"
# compile binary extension
docker exec "$container_id" bash -c "cd gem && bundle exec rake clean fetch compile"

docker exec "$container_id" bash -c "cd appoptics-legacy && bundle install"
docker exec "$container_id" bash -c "cd appoptics-w3c && bundle install"
docker exec "$container_id" bash -c "cd otel && bundle install"

echo_section "Start Servers"

for port in {4200..4210}; do
    docker exec "$container_id" bash -c "cd appoptics-legacy && bundle exec ruby single.rb $port &"
done

for port in {4000..4010}; do
    docker exec "$container_id" bash -c "cd appoptics-w3c && bundle exec ruby single.rb $port &"
done

for port in {4100..4110}; do
    docker exec "$container_id" bash -c "cd otel && bundle exec ruby single.rb $port &"
done

echo_section "System info"

echo "Container Id is ""$container_id"""
docker exec "$container_id" printenv
docker exec "$container_id" ruby -v

# ready for work
docker attach "$container_id"
