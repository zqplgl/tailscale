#!/bin/bash

# 配置SSH
mkdir -p /root/.ssh && chmod 700 /root/.ssh

# 复制当前目录的密钥到容器
if [ -f /id_rsa ]; then
    cp /id_rsa /root/.ssh/id_rsa && chmod 600 /root/.ssh/id_rsa
fi
if [ -f /id_rsa.pub ]; then
    cp /id_rsa.pub /root/.ssh/id_rsa.pub && chmod 644 /root/.ssh/id_rsa.pub
    cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys
fi

# 配置SSH服务
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
echo "Port 22" >> /etc/ssh/sshd_config
echo "Port 443" >> /etc/ssh/sshd_config

# 启动SSH服务
/usr/sbin/sshd

# 启动Tailscale
/usr/sbin/tailscaled --state=/var/lib/tailscale/tailscaled.state &
tailscale up --authkey="$TS_AUTHKEY" --accept-dns=false

# 保持容器运行
tail -f /dev/null