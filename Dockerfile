FROM ubuntu:22.04

# 配置华为源
RUN sed -i 's/archive.ubuntu.com/mirrors.huaweicloud.com/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.huaweicloud.com/g' /etc/apt/sources.list

# 安装依赖
RUN apt-get update && apt-get install -y \
    openssh-server \
    wget \
    curl \
    gnupg2 \
    ca-certificates

# 安装Tailscale
RUN curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null && \
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list && \
    apt-get update && apt-get install -y tailscale

# 配置SSH
RUN mkdir -p /var/run/sshd

# 复制SSH密钥
COPY id_rsa /id_rsa
COPY id_rsa.pub /id_rsa.pub

# 复制entrypoint脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 暴露SSH端口
EXPOSE 22

# 启动脚本
ENTRYPOINT ["/entrypoint.sh"]