# Tailscale SSH 容器配置

## 容器配置
- 两个Ubuntu 22.04容器，使用华为源
- 容器用户：root
- SSH密钥认证，禁用密码登录
- 使用当前目录的id_rsa和id_rsa.pub密钥对
- Tailscale网络连接

## 启动步骤
1. 确保当前目录存在id_rsa和id_rsa.pub文件
2. 构建并启动容器：
   ```bash
   docker-compose up -d --build
   ```
3. 查看容器状态：
   ```bash
   docker-compose ps
   ```

## 测试命令
1. 查看容器1的Tailscale IP：
   ```bash
   docker exec -it tailscale-container-1 tailscale ip
   ```
2. 查看容器2的Tailscale IP：
   ```bash
   docker exec -it tailscale-container-2 tailscale ip
   ```
3. 从容器1连接到容器2：
   ```bash
   docker exec -it tailscale-container-1 ssh -o StrictHostKeyChecking=no root@100.112.64.91 echo "SSH连接测试成功！"
   ```
4. 从容器2连接到容器1：
   ```bash
   docker exec -it tailscale-container-2 ssh -o StrictHostKeyChecking=no root@100.86.226.74 echo "SSH连接测试成功！"
   ```

## Tailscale虚拟IP
- 容器1：100.86.226.74
- 容器2：100.112.64.91
