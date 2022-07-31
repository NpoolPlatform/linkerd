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
helm install linkerd2 \
  --set installNamespace=false \
  --cluster-domain=linkerd.npool.top \
  --identity-trust-domain=linkerd.npool.top \
  --set identity.issuer.scheme=kubernetes.io/tls \
  --set-file identityTrustAnchorsPEM=ca.crt \
  --set-file identity.issuer.tls.crtPEM=issuer.crt \
  --set-file identity.issuer.tls.keyPEM=issuer.key \
  --set policyValidator.externalSecret=true \
  --set-file policyValidator.caBundle=ca.crt \
  --set proxyInjector.externalSecret=true \
  --set-file proxyInjector.caBundle=ca.crt \
  --set profileValidator.externalSecret=true \
  --set-file profileValidator.caBundle=ca.crt \
  linkerd/linkerd2 \
  -n linkerd

helm install linkerd-viz \
  --set installNamespace=false \
  --set tap.externalSecret=true \
  --set-file tap.caBundle=ca.crt \
  --set tapInjector.externalSecret=true \
  --set-file tapInjector.caBundle=ca.crt \
  linkerd/linkerd-viz \
  -n linkerd-viz

helm install linkerd-jaeger \
  --set installNamespace=false \
  --set webhook.externalSecret=true \
  --set-file webhook.caBundle=ca.crt \
  linkerd/linkerd-jaeger \
  -n linkerd-jaeger
