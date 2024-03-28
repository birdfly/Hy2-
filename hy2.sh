#!/bin/sh

# 确保脚本以root权限执行
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root!" 1>&2
    exit 1
fi

# 设置时区为Asia/Shanghai
timedatectl set-timezone Asia/Shanghai

# 生成随机密码和端口号
hyPasswd=$(cat /proc/sys/kernel/random/uuid)
getPort=$(shuf -i 2000-65000 -n 1)

# 函数：获取服务器IP
getIP(){
    local serverIP=
    serverIP=$(curl -s -4 https://ipinfo.io/ip)
    if [ -z "${serverIP}" ]; then
        serverIP=$(curl -s -6 https://ipinfo.io/ip)
    fi
    echo "${serverIP}"
}

# 安装Hysteria和runit
install_hy(){
    # 安装基本工具
    apt-get update -y && apt-get install -y curl runit openssl

    # 下载和安装Hysteria
    bash <(curl -fsSL https://get.hy2.sh/)

    # 创建证书
    mkdir -p /etc/hysteria/
    openssl req -x509 -nodes -newkey rsa:4096 -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt -subj "/CN=bing.com" -days 36500

    # 创建Hysteria配置文件
    cat > /etc/hysteria/config.json <<EOF
{
    "listen": ":$getPort",
    "protocol": "quic",
    "obfs": "bing.com",
    "cert": "/etc/hysteria/server.crt",
    "key": "/etc/hysteria/server.key",
    "auth": {
        "mode": "password",
        "config": {
            "passwords": [
                "$hyPasswd"
            ]
        }
    }
}
EOF

    # 设置runit服务
    mkdir -p /etc/sv/hysteria
    cat > /etc/sv/hysteria/run <<EOF
#!/bin/sh
exec 2>&1
exec /usr/local/bin/hysteria -config /etc/hysteria/config.json
EOF
    chmod +x /etc/sv/hysteria/run

    # 激活和启动服务
    ln -s /etc/sv/hysteria /etc/service/
}

# 安装并启动Hysteria
install_hy

# 显示客户端配置信息
echo
echo "Hysteria安装和配置完成。"
echo "配置信息："
echo "服务器地址: $(getIP)"
echo "端口: $getPort"
echo "密码: $hyPasswd"
echo "伪装域名: bing.com"
