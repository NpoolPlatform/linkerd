#!/usr/bin/env bash

# fast fail
set -o errexit
set -o nounset
set -o pipefail

# add the repo for stable releases
helm repo add linkerd https://helm.linkerd.io/stable

# install linkerd control plane
# dep resource
# 1. root ca
# 2. issuer crt/key
helm upgrade -i linkerd2 \
  --set installNamespace=false \
  --set identity.issuer.scheme=kubernetes.io/tls \
  --set-file identityTrustAnchorsPEM=../k8s/root-cert/ca.crt \
  --set-file identity.issuer.tls.crtPEM=../k8s/root-cert/issuer.crt \
  --set-file identity.issuer.tls.keyPEM=../k8s/root-cert/issuer.key \
  --set policyValidator.externalSecret=true \
  --set-file policyValidator.caBundle=../k8s/root-cert/ca.crt \
  --set proxyInjector.externalSecret=true \
  --set-file proxyInjector.caBundle=../k8s/root-cert/ca.crt \
  --set profileValidator.externalSecret=true \
  --set-file profileValidator.caBundle=../k8s/root-cert/ca.crt \
  linkerd/linkerd2 \
  -n linkerd

helm upgrade -i linkerd-viz \
  --set installNamespace=false \
  --set tap.externalSecret=true \
  --set-file tap.caBundle=../k8s/root-cert/ca.crt \
  --set tapInjector.externalSecret=true \
  --set-file tapInjector.caBundle=../k8s/root-cert/ca.crt \
  linkerd/linkerd-viz \
  -n linkerd-viz

helm upgrade -i linkerd-jaeger \
  --set installNamespace=false \
  --set webhook.externalSecret=true \
  --set-file webhook.caBundle=../k8s/root-cert/ca.crt \
  linkerd/linkerd-jaeger \
  -n linkerd-jaeger
