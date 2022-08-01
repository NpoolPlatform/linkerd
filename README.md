# [linkerd stable](https://linkerd.io/)

linkerd for service mesh, load balance metrics and tracing etc

## 安装流程

1. 安装 **step**，并生成根证书(仓库已自带有效期 10 年)
2. 创建命名空间
3. 安装 **linkerd** 控制面
4. 安装组件

## [相关组件](https://linkerd.io/2.11/reference/architecture/)

+ CLI(管理监测,不使用此方式安装)
+ cert-manager(证书的管理不使用,linkerd 推荐的方式,使用外部自建证书,方便证书的过期管理)
+ 控制面
+ 数据面
+ UI(注意域名定义在**k8s/viz-ingress.yaml**内)
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
