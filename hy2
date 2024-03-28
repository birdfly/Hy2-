#!/bin/sh

# 安装必要的软件包
if [ -f "/usr/bin/apt-get" ]; then
    apt-get update -y && apt-get upgrade -y
    apt-get install -y gawk curl
else
    yum update -y && yum upgrade -y
    yum install -y epel-release
    yum install -y gawk curl
fi

# 下载并安装 Hysteria
bash <(curl -fsSL https://get.hy2.sh/)

# 创建 Hysteria 配置目录
mkdir -p /etc/hysteria/

# 生成 Hysteria 配置文件
hyPasswd=$(cat /proc/sys/kernel/random/uuid)
getPort=$(shuf -i 2000-65000 -n 1)

cat >/etc/hysteria/config.yaml <<EOF
listen: :$getPort
tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key
auth:
  type: password
  password: $hyPasswd
masquerade:
  type: proxy
  proxy:
    url: https://bing.com
    rewriteHost: true
quic:
  initStreamReceiveWindow: 26843545
  maxStreamReceiveWindow: 26843545
  initConnReceiveWindow: 67108864
  maxConnReceiveWindow: 67108864
EOF

# 生成 TLS 证书
openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt -subj "/CN=bing.com" -days 36500 && chown hysteria /etc/hysteria/server.key && chown hysteria /etc/hysteria/server.crt

# 启动 Hysteria 进程
nohup /usr/local/bin/hysteria-server -config /etc/hysteria/config.yaml >/dev/null 2>&1 &

# 显示配置信息
hylink=$(echo -n "${hyPasswd}@$(curl -s -4 http://www.cloudflare.com/cdn-cgi/trace | grep "ip" | awk -F "=" '{print $2}'):${getPort}/?insecure=1&sni=bing.com#1024-Hysteria2")

echo
echo "安装已经完成"
echo
echo "===========Hysteria2配置参数============"
echo
echo "地址：$(curl -s -4 http://www.cloudflare.com/cdn-cgi/trace | grep "ip" | awk -F "=" '{print $2}')"
echo "端口：${getPort}"
echo "密码：${hyPasswd}"
echo "SNI：bing.com"
echo "传输协议：tls"
echo "打开跳过证书验证，true"
echo
echo "========================================="
echo "hysteria2://${hylink}"
echo
