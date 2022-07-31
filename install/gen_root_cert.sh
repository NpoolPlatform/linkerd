#!/usr/bin/env bash

#[trust-anchor-certificate](https://linkerd.io/2.11/tasks/generate-certificates/#trust-anchor-certificate)
set -o errexit
set -o nounset
set -o pipefail

# source common function
source ./common.sh

# check step exist and version ok
if [ _pre_check -eq 1 ]; then
  echo "please first install step with version ${STEP_VERSION}"
  exit 1
fi

# gen root trust anchor
$STEP certificate create \
  root.linkerd.cluster.local ca.crt ca.key \
  --profile root-ca \
  --not-after=87600h \
  --no-password \
  --insecure

# gen root cert issuer
$STEP certificate create \
  identity.linkerd.cluster.local issuer.crt issuer.key \
  --profile intermediate-ca \
  --not-after 87600h \
  --no-password \
  --insecure \
  --ca ca.crt \
  --ca-key ca.key
