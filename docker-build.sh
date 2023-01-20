#!/bin/sh

type docker >/dev/null 2>&1 || { echo >&2 "Docker is not installed.  Aborting."; exit 1; }

if [ "$1" == "push" ]
then
    echo "Logging into docker hub..."
    if ! docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
    then
        echo "Docker login failed"
        exit 128
    fi
fi

if [ -z "$DRONE_BUILD_NUMBER" ]
then
    echo "DRONE_BUILD_NUMBER is not set.  Aborting."
    exit 1
fi

echo "Pulling latest..."
if ! docker pull supporttools/kube-builder:latest
then
    echo "Docker pull failed"
    exit 127
fi

echo "Testing docker build..."
if ! docker build --add-host=mirror.coxedgecomputing.com:185.85.196.205 -t supporttools/kube-builder:${DRONE_BUILD_NUMBER} --cache-from supporttools/kube-builder:latest -f Dockerfile .
then
    echo "Docker build failed"
    exit 126
fi

if [ ! "$1" == "push" ]
then
    echo "Test build, not pushing"
    exit 0
fi

echo "Pushing..."
if ! docker push supporttools/kube-builder:${DRONE_BUILD_NUMBER}
then
    echo "Docker push failed for build number"
    exit 125
fi
echo "Tagging to latest and pushing..."
if ! docker tag supporttools/kube-builder:${DRONE_BUILD_NUMBER} supporttools/kube-builder:latest
then
    echo "Docker tag failed"
    exit 124
fi

echo "Pushing latest..."
if ! docker push supporttools/kube-builder:latest
then
    echo "Docker push failed for latest"
    exit 123
fi
