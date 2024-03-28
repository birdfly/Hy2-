#!/bin/sh
# forum: https://1024.day

if [ "$(id -u)" -ne 0 ]; then
    clear
    echo "Error: This script must be run as root!" 1>&2
    exit 1
fi

timedatectl set-timezone Asia/Shanghai
hyPasswd=$(cat /proc/sys/kernel/random/uuid)
getPort=$(shuf -i 2000-65000 -n 1)

getIP(){
    local serverIP=
    serverIP=$(curl -s -4 http://www.cloudflare.com/cdn-cgi/trace | grep "ip" | awk -F "=" '{print $2}')
    if [ -z "${serverIP}" ]; then
        serverIP=$(curl -s -6 http://www.cloudflare.com/cdn-cgi/trace | grep "ip" | awk -F "=" '{print $2}')
    fi
    echo "${serverIP}"
}

install_hy2(){
    if [ -f "/usr/bin/apt-get" ]; then
        apt-get update -y && apt-get upgrade -y
        apt-get install -y gawk curl
    else
        yum update -y && yum upgrade -y
        yum install -y epel-release
        yum install -y gawk curl
    fi
    bash <(curl -fsSL https://get.hy2.sh/)
    mkdir -p /etc/hysteria/
    openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt -subj "/CN=bing.com" -days 36500
    
    # 创建runit服务脚本
    HYSTERIA_SERVICE_DIR="/etc/sv/hysteria"
    mkdir -p "${HYSTERIA_SERVICE_DIR}"
    cat <<EOF >"${HYSTERIA_SERVICE_DIR}/run"
#!/bin/sh
exec /usr/local/bin/hysteria server -config /etc/hysteria/config.yaml
EOF
    chmod +x "${HYSTERIA_SERVICE_DIR}/run"
    
    # 激活runit服务
    ln -s "${HYSTERIA_SERVICE_DIR}" /etc/service/

    # 清理不再需要的脚本
    rm -f tcp-wss.sh hy2.sh
}

client_hy2(){
    hylink=$(echo -n "${hyPasswd}@$(getIP):${getPort}/?insecure=1&sni=bing.com#1024-Hysteria2")

    echo
    echo "安装已经完成"
    echo
    echo "===========Hysteria2配置参数============"
    echo
    echo "地址：$(getIP)"
    echo "端口：${getPort}"
    echo "密码：${hyPasswd}"
    echo "SNI：bing.com"
    echo "传输协议：tls"
    echo "打开跳过证书验证，true"
    echo
    echo "========================================="
    echo "hysteria2://${hylink}"
    echo
}

install_hy2
client_hy2
