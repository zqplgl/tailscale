# Cloudflare Tunnel 配置指南

## 概述

本指南详细介绍如何使用 Cloudflare Tunnel 从家中安全 SSH 登录到公司电脑，解决直接连接问题。

## 前提条件

- 已安装 Docker
- 拥有 Cloudflare 账户
- 已在 Cloudflare 中设置好域名：static-cdn-blog.cc.cd

## 域名注册和解析

- 打开 [DNShe](https://my.dnshe.com) 注册并注册域名：static-cdn-blog.cc.cd 
- 登录 [Cloudflare](https://dash.cloudflare.com/) 配置域名解析，将域名托管到 Cloudflare DNS

## 公司端配置（被访问方）

### 1. 安装 Docker CE

#### Ubuntu/Debian

```bash
# 安装依赖
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

# 添加 Docker 官方 GPG 密钥
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 添加 Docker 源
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装 Docker CE
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 启动 Docker
sudo systemctl start docker
sudo systemctl enable docker
```
### 2. 安装 Cloudflared 客户端

```bash
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
chmod +x cloudflared-linux-amd64
sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
```

### 3. 登录 Cloudflare 并创建 Tunnel

```bash
# 登录 Cloudflare
cloudflared tunnel login

# 创建 SSH 访问专用 tunnel
cloudflared tunnel create ssh-access

# 配置 DNS 记录
cloudflared tunnel route dns ssh-access dev.static-cdn-blog.cc.cd
```

### 4. 获取 Tunnel Token

```bash
# 查看 tunnel 信息
cloudflared tunnel list

# 获取 tunnel token
cloudflared tunnel token ssh-access
```

### 5. 方法一：使用 Token 验证（推荐）

```bash
docker run -d --name cloudflared-tunnel \
  --restart unless-stopped \
  cloudflare/cloudflared:latest \
  tunnel --no-autoupdate run --token YOUR_TUNNEL_TOKEN
```

> 注意：
> - `--no-autoupdate` 标志可以禁用自动更新，确保版本稳定性
> - 直接使用 `--token` 参数传递 token 是另一种有效的方式
> - 使用 Token 验证时，不需要挂载 credentials-file 卷，更加安全和方便

### 6. 方法二：使用配置文件

#### 6.1 创建配置目录和文件

```bash
mkdir -p /home/zhangqipeng/projects/cloudflared/config

# 复制凭据文件
cp ~/.cloudflared/*.json /home/zhangqipeng/projects/cloudflared/config/

# 创建 config.yml
cat > /home/zhangqipeng/projects/cloudflared/config/config.yml << EOF
tunnel: YOUR_TUNNEL_ID  # 替换为实际的 tunnel ID
credentials-file: /etc/cloudflared/YOUR_TUNNEL_ID.json  # 替换为实际的文件名
ingress:
  - hostname: dev.static-cdn-blog.cc.cd
    service: ssh://localhost:22
  - service: http_status:404
EOF
```

#### 6.2 使用 Docker Compose

```yaml
# /home/zhangqipeng/projects/cloudflared/docker-compose.yml
version: '3.8'
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    restart: unless-stopped
    command: tunnel run
    volumes:
      - ./config:/etc/cloudflared
```

```bash
# 启动服务
cd /home/zhangqipeng/projects/cloudflared
docker-compose up -d
```

### 7. 配置 SSH 服务

```bash
# 确保 SSH 服务运行
sudo systemctl status ssh
sudo systemctl enable ssh
sudo systemctl start ssh

# 允许 SSH 端口
sudo ufw allow 22/tcp
```

## 家里端配置（访问方）

### 1. 安装 SSH 客户端

- **Windows**：使用 PowerShell 或安装 PuTTY
- **macOS/Linux**：系统自带 SSH 客户端

### 2. 配置 SSH 代理（解决连接问题）

```bash
# 创建或修改 ~/.ssh/config 文件
cat >> ~/.ssh/config << EOF

Host dev.static-cdn-blog.cc.cd
  ProxyCommand cloudflared access ssh --hostname %h
  User root
EOF
```

### 3. 连接到公司电脑

```bash
# 基本连接
ssh dev.static-cdn-blog.cc.cd

# 或者指定用户
ssh root@dev.static-cdn-blog.cc.cd
```

### 4. 使用 SSH 密钥（推荐）

```bash
# 在家生成密钥对
ssh-keygen -t ed25519

# 将公钥复制到公司电脑
ssh-copy-id root@dev.static-cdn-blog.cc.cd
```

## 故障排除

### 1. 检查 Tunnel 状态

```bash
# 查看容器日志
docker logs cloudflared-tunnel

# 或者使用 Docker Compose
cd /home/zhangqipeng/projects/cloudflared
docker-compose logs -f
```

### 2. 验证 DNS 记录

- 登录 Cloudflare 控制台
- 检查 dev.static-cdn-blog.cc.cd 的 DNS 记录
- 确保它是指向 Cloudflare Tunnel 的 CNAME 记录

### 3. 测试本地连接

```bash
# 在公司端测试
ssh localhost
```

### 4. 检查 Cloudflare 控制台

- 登录 Cloudflare 控制台
- 确认 Tunnel 状态为 "Active"

## 安全建议

- 使用 SSH 密钥认证而非密码
- 定期更新 cloudflared 版本
- 监控登录日志
- 考虑在 Cloudflare 控制台设置访问限制
- 限制 SSH 登录的用户和 IP

## 技术说明

- **直接 SSH 连接**：通过 Cloudflare Tunnel 路由 SSH 流量
- **ProxyCommand 方式**：明确指定使用 cloudflared 作为代理，确保连接稳定性
- **Token 验证**：更加安全和方便，不需要挂载凭据文件

此配置确保从家中安全访问公司电脑，无需暴露公司网络的公网 IP。