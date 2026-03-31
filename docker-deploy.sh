#!/bin/bash

# Load environment variables from .env file
set -a
source .env
set +a

# Function to run npm commands
run_docker_command() {
  # Run the appropriate command based on the argument
  case "$1" in
    docker-build)
      docker build --platform=linux/amd64 -t $DOCKER_HUB_IMAGE .
      ;;
    docker-run)
      docker run --rm -p 3000:3000 $DOCKER_HUB_IMAGE
      ;;
    docker-build-run)
      run_docker_command docker-build && run_docker_command docker-run
      ;;
    docker-push)
      run_docker_command docker-build && docker push $DOCKER_HUB_IMAGE
      ;;
    *)
      echo "Invalid argument. Please use: docker-build, docker-run, docker-build-run, or docker-push"
      exit 1
      ;;
  esac
}

# Check if an argument is provided
if [ $# -eq 0 ]; then
    echo "Please provide an argument: docker-build, docker-run, docker-build-run, or docker-push"
    exit 1
fi

run_docker_command $1