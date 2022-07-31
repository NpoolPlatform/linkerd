#!/usr/bin/env bash

# fast fail
set -o errexit
set -o nounset
set -o pipefail

WGET=$(which wget)
DPKG=$(which dpkg)

STEP_VERSION=0.20.0

_pre_check() {
  if [[ $(type step &>/dev/null) -eq 0 && $(step -v | grep "CLI/${STEP_VERSION}" -c) -eq 1 ]]; then
    echo "step match latest version ${STEP_VERSION}"
    return 0
  fi
  return 1
}
