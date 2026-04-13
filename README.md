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

## 使用docker命令启动（不使用docker-compose）
1. 构建镜像：
   ```bash
   docker build -t tailscale-ssh-container .
   ```
2. 启动容器1：
   ```bash
   docker run -d \
     --name tailscale-container-1 \
     --hostname DGX1-01-tailscale-container-1 \
     --privileged \
     --device=/dev/net/tun:/dev/net/tun \
     -p 2222:22 \
     -e TS_AUTHKEY=tskey-auth-kamAr4M2YE11CNTRL-4xKcZuYBcK4Yu85PkjUXK4cT88U1vhWh \
     --restart always \
     tailscale-ssh-container
   ```
3. 启动容器2：
   ```bash
   docker run -d \
     --name tailscale-container-2 \
     --hostname DGX1-01-tailscale-container-2 \
     --privileged \
     --device=/dev/net/tun:/dev/net/tun \
     -p 2223:22 \
     -e TS_AUTHKEY=tskey-auth-kamAr4M2YE11CNTRL-4xKcZuYBcK4Yu85PkjUXK4cT88U1vhWh \
     --restart always \
     tailscale-ssh-container
   ```
4. 查看容器状态：
   ```bash
   docker ps
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
3. 从容器1连接到容器2（使用443端口）：
   ```bash
   docker exec -it tailscale-container-1 ssh -o StrictHostKeyChecking=no -p 443 root@100.75.163.66 echo "SSH连接测试成功（443端口）！"
   ```
4. 从容器2连接到容器1（使用443端口）：
   ```bash
   docker exec -it tailscale-container-2 ssh -o StrictHostKeyChecking=no -p 443 root@100.74.157.107 echo "SSH连接测试成功（443端口）！"
   ```
5. 从容器1连接到容器2（使用22端口）：
   ```bash
   docker exec -it tailscale-container-1 ssh -o StrictHostKeyChecking=no root@100.75.163.66 echo "SSH连接测试成功（22端口）！"
   ```
6. 从容器2连接到容器1（使用22端口）：
   ```bash
   docker exec -it tailscale-container-2 ssh -o StrictHostKeyChecking=no root@100.74.157.107 echo "SSH连接测试成功（22端口）！"
   ```

## Tailscale虚拟IP
- 容器1：100.74.157.107
- 容器2：100.75.163.66

## 端口配置说明
- **真实地址连接**：通过主机端口映射（2222:22 和 2223:22）只能使用22端口
- **虚拟地址连接**：通过Tailscale虚拟IP可以使用22或443端口