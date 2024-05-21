#!/usr/bin/env bash
# Run a single packer build
#
# Specify the build as an argument to the script. Ex:
# ./build.sh ubuntu2204
set -eu

if [ ! "${VAULT_TOKEN+x}" ]; then
  #shellcheck disable=SC1091
  source vault-env.sh
fi

if [ $# -ne 1 ]; then
  echo """
Syntax: $0 [BUILD]

Where [BUILD] is one of the supported OS builds:

ubuntu2204
"""
  exit 1
fi

build_name="${1,,}"
build_path=

case $build_name in
  ubuntu2204)
    build_path="builds/linux/ubuntu/22-04-lts/"
    ;;
  *)
    echo "Unknown build; exiting..."
    exit 1
    ;;
esac

packer init "${build_path}"
packer build -on-error=abort -force "${build_path}"


