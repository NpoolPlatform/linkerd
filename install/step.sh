#!/usr/bin/env bash

#[step](https://smallstep.com/docs/step-cli/installation)

# source common function
source ./common.sh

STEP_NAME=step-cli_${STEP_VERSION}_amd64.deb
STEP_URL=https://dl.step.sm/gh-release/cli/docs-cli-install/v${STEP_VERSION}/${STEP_NAME}
DOWNLOAD_DIR=/tmp
STEP_PATH=${DOWNLOAD_DIR}/${STEP_NAME}

# check step exist and version ok
if [ _pre_check -eq 0 ]; then
  exit 1
fi

# download
$WGET -O $STEP_PATH $STEP_URL

# install
$DPKG -i $STEP_PATH
