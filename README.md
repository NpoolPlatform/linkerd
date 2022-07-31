# [linkerd stable](https://linkerd.io/)

linkerd for service mesh, load balance metrics and tracing etc

## [相关组件](https://linkerd.io/2.11/reference/architecture/)

+ CLI(管理监测,不使用此方式安装)
+ cert-manager(证书的管理不使用,linkerd 推荐的方式,使用外部自建证书,方便证书的过期管理)
+ 控制面
+ 数据面
+ UI
+ 监控
+ Jaeger
+ Upgrade
+ 轮换根证书

## 安装

+ [安装模式采用的是 **helm**](https://linkerd.io/2.11/tasks/install-helm/#prerequisite-identity-certificates),[不使用官方推荐的 **CLI** 方式](https://linkerd.io/2.11/tasks/install/)

+ [证书的管理不采用官方推荐模式, 统一使用 **cert-manager** 管理](https://github.com/linkerd/linkerd2/issues/3548)或者[详情](https://github.com/linkerd/linkerd2/pull/3600)

1. 安装的是 **stable version**
2. 需要的证书必须要先创建好 **linkerd-trust-anchor**
3. 注意需要证书所在的命名空间是 **linkerd**
4. 创建 **linkerd** 使用的 **issuer**(这里可以是 **issuer** 或者 **clusterissuer**)

安装 **step** 生成根证书

```sh
  wget https://dl.step.sm/gh-release/cli/docs-cli-install/v0.20.0/step-cli_0.20.0_amd64.deb
  dpkg -i step-cli_0.20.0_amd64.deb
```

linkerd-component-ns.yaml

```yaml
apiVersion: v1
Kink: Namespace
metadata:
  name: linkerd
---
apiVersion: v1
Kink: Namespace
metadata:
  name: linkerd-viz
---
apiVersion: v1
Kink: Namespace
metadata:
  name: linkerd-jaeger
```

## root

root cert

```sh
  step certificate create \
    root.linkerd.cluster.local ca.crt ca.key  \
    --profile root-ca \
    --not-after=87600h \
    --no-password \
    --insecure && \
  kubectl create secret tls linkerd-trust-anchor \
    --cert=ca.crt \
    --key=ca.key \
    --namespace=linkerd
```

linkerd-control-issuer.yaml

```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: linkerd-trust-anchor
  namespace: linkerd
spec:
  ca:
    secretName: linkerd-trust-anchor
```

linkerd-control-certificate.yaml

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: linkerd-identity-issuer
  namespace: linkerd
spec:
  secretName: linkerd-identity-issuer
  duration: 48h
  renewBefore: 25h
  issuerRef:
    name: linkerd-trust-anchor
    kind: Issuer
  commonName: identity.linkerd.cluster.local
  dnsNames:
    - identity.linkerd.cluster.local
  isCA: true
  privateKey:
    algorithm: ECDSA
  usages:
    - cert sign
    - crl sign
    - server auth
    - client auth
```

**注意这里需要设置自定义的域名**,共需要设置三个参数

control

+ cluster-domain
+ identity-trust-domain

viz

+ clusterDomain

```sh
  helm repo add linkerd https://helm.linkerd.io/stable
  helm install linkerd2 \
    --cluster-domain=linkerd.npool.top \
    --identity-trust-domain=linkerd.npool.top \
    --set-file identityTrustAnchorsPEM=ca.crt \
    --set identity.issuer.scheme=kubernetes.io/tls \
    --set installNamespace=false \
    --set policyValidator.externalSecret=true \
    --set-file policyValidator.caBundle=ca.crt \
    --set proxyInjector.externalSecret=true \
    --set-file proxyInjector.caBundle=ca.crt \
    --set profileValidator.externalSecret=true \
    --set-file profileValidator.caBundle=ca.crt \
    linkerd/linkerd2 \
    -n linkerd
```

## webhook

webhook cert

```sh
  step certificate create \
    webhook.linkerd.cluster.local ca.crt ca.key \
    --profile root-ca \
    --no-password \
    --insecure \
    --san webhook.linkerd.cluster.local && \
  kubectl create secret tls webhook-issuer-tls \
    --cert=ca.crt \
    --key=ca.key \
    --namespace=linkerd && \
  kubectl create secret tls webhook-issuer-tls \
    --cert=ca.crt \
    --key=ca.key \
    --namespace=linkerd-viz && \
  kubectl create secret tls webhook-issuer-tls \
    --cert=ca.crt \
    --key=ca.key \
    --namespace=linkerd-jaeger
```

linkerd-webhook-issuer.yaml

```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: webhook-issuer
  namespace: linkerd
spec:
  ca:
    secretName: webhook-issuer-tls
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: webhook-issuer
  namespace: linkerd-viz
spec:
  ca:
    secretName: webhook-issuer-tls
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: webhook-issuer
  namespace: linkerd-jaeger
spec:
  ca:
    secretName: webhook-issuer-tls
```

linkerd-webhook-certificate.yaml

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: linkerd-policy-validator
  namespace: linkerd
spec:
  secretName: linkerd-policy-validator-k8s-tls
  duration: 24h
  renewBefore: 1h
  issuerRef:
    name: webhook-issuer
    kind: Issuer
  commonName: linkerd-policy-validator.linkerd.svc
  dnsNames:
    - linkerd-policy-validator.linkerd.svc
  isCA: false
  privateKey:
    algorithm: ECDSA
    encoding: PKCS8
  usages:
    - server auth
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: linkerd-proxy-injector
  namespace: linkerd
spec:
  secretName: linkerd-proxy-injector-k8s-tls
  duration: 24h
  renewBefore: 1h
  issuerRef:
    name: webhook-issuer
    kind: Issuer
  commonName: linkerd-proxy-injector.linkerd.svc
  dnsNames:
    - linkerd-proxy-injector.linkerd.svc
  isCA: false
  privateKey:
    algorithm: ECDSA
  usages:
    - server auth
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: linkerd-sp-validator
  namespace: linkerd
spec:
  secretName: linkerd-sp-validator-k8s-tls
  duration: 24h
  renewBefore: 1h
  issuerRef:
    name: webhook-issuer
    kind: Issuer
  commonName: linkerd-sp-validator.linkerd.svc
  dnsNames:
    - linkerd-sp-validator.linkerd.svc
  isCA: false
  privateKey:
    algorithm: ECDSA
  usages:
    - server auth
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: tap
  namespace: linkerd-viz
spec:
  secretName: tap-k8s-tls
  duration: 24h
  renewBefore: 1h
  issuerRef:
    name: webhook-issuer
    kind: Issuer
  commonName: tap.linkerd-viz.svc
  dnsNames:
    - tap.linkerd-viz.svc
  isCA: false
  privateKey:
    algorithm: ECDSA
  usages:
    - server auth
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: linkerd-tap-injector
  namespace: linkerd-viz
spec:
  secretName: tap-injector-k8s-tls
  duration: 24h
  renewBefore: 1h
  issuerRef:
    name: webhook-issuer
    kind: Issuer
  commonName: tap-injector.linkerd-viz.svc
  dnsNames:
    - tap-injector.linkerd-viz.svc
  isCA: false
  privateKey:
    algorithm: ECDSA
  usages:
    - server auth
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: jaeger-injector
  namespace: linkerd-jaeger
spec:ls
  secretName: jaeger-injector-k8s-t
  duration: 24h
  renewBefore: 1h
  issuerRef:
    name: webhook-issuer
    kind: Issuer
  commonName: jaeger-injector.linkerd-jaeger.svc
  dnsNames:
    - jaeger-injector.linkerd-jaeger.svc
  isCA: false
  privateKey:
    algorithm: ECDSA
  usages:
    - server auth
```

**注意这里需要设置 jaeger 的地址**

```sh
  helm install linkerd-viz \
    --set clusterDomain=linkerd.npool.top
    --set installNamespace=false \
    --set tap.externalSecret=true \
    --set-file tap.caBundle=ca.crt \
    --set tapInjector.externalSecret=true \
    --set-file tapInjector.caBundle=ca.crt \
    --set jaegerUrl=jaeger.linkerd-jaeger:16686
    linkerd/linkerd-viz \
    -n linkerd-viz

  helm install linkerd-jaeger \
    --set installNamespace=false \
    --set webhook.externalSecret=true \
    --set-file webhook.caBundle=ca.crt \
    linkerd/linkerd-jaeger \
    -n linkerd-jaeger
```

如果这里需要使用自己的镜像仓库,可以通过参数 **--registry** 设置

## ingress

linkerd-traefik.yaml

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: l5d-header-middleware
  namespace: traefik
spec:
  headers:
    customRequestHeaders:
      l5d-dst-override: "web-svc.emojivoto.svc.cluster.local:80"
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  annotations:
    kubernetes.io/ingress.class: traefik
  creationTimestamp: null
  name: emojivoto-web-ingress-route
  namespace: emojivoto
spec:
  entryPoints: []
  routes:
    - kind: Rule
      match: PathPrefix(`/`)
      priority: 0
      middlewares:
      - name: l5d-header-middleware
        services:
        - kind: Service
          name: web-svc
          port: 80
```

## [私有镜像](https://linkerd.io/2.11/tasks/using-a-private-docker-repository/)

## [自定义域名](https://linkerd.io/2.11/tasks/using-custom-domain/)

## 解决了什么问题

+ 微服务负载均衡
+ 灰度发布
+ 流量分割
+ 故障注入
+ ...

## 前置依赖

+ cert-manager(离线签名模式)
+ 根证书(linkerd-trust-anchor)

## QAs
