# 脚本说明

+ common.sh 定义的是公用的脚本

+ control.sh 是使用 helm 安装 linkerd 控制面脚本

  *这里需要注意的是引用的证书文件存放在 **k8s/root-cert** 内*

+ gen_roo_cert.sh 是生成 root anchor 脚本, 过期重新生成需要放入 **k8s/root-cert** 内

+ step.sh 安装 **step** 和是生成 **root key** 的脚本
