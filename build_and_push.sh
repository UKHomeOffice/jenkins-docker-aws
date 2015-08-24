#!/bin/bash

if test $# -eq 1
  then
    echo "Building repository: $1"
    docker build -t $1 .
    docker push $1
  else
    echo "Please provide a single parameter which is the repository to push do, for example timgent/aws-jenkins:v0.4"
fi
