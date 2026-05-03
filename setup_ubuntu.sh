#!/data/data/com.termux/files/usr/bin/bash

# Termux Ubuntu 配置脚本
# 用法: bash setup_ubuntu.sh

set -e

echo "====================================="
echo "  Termux Ubuntu 配置脚本"
echo "====================================="

# 1. 安装 proot-distro
echo "[1/7] 正在安装 proot-distro..."
pkg install proot-distro -y

# 2. 安装 Ubuntu
echo "[2/7] 正在安装 Ubuntu..."
proot-distro install ubuntu

# 3. 在 Ubuntu 中创建用户并配置
echo "[3/7] 正在 Ubuntu 中创建用户 new..."
proot-distro login ubuntu << 'UBUNTU_EOF'
    useradd -d /data/data/com.termux/files/home -m new
    echo "new:new" | chpasswd
    usermod -s /bin/bash new
    apt update
UBUNTU_EOF

# 4. 修改 passwd 文件，将 new 用户 UID/GID 改为 0（root 权限）
echo "[4/7] 正在修改 new 用户权限..."
PASSWD_FILE="/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu/etc/passwd"

if [ -f "$PASSWD_FILE" ]; then
    # 备份原文件
    cp "$PASSWD_FILE" "${PASSWD_FILE}.bak"
    # 修改 new 所在行，将 x:后的数字改为 0:0
    sed -i 's/^new:x:[0-9]*:[0-9]*/new:x:0:0/' "$PASSWD_FILE"
    echo "[5/7] passwd 文件已修改并备份为 ${PASSWD_FILE}.bak"
else
    echo "错误: 未找到 passwd 文件: $PASSWD_FILE"
    exit 1
fi

# 5. 在 Termux home 目录创建 .bashrc
echo "[6/7] 正在创建 Termux .bashrc..."
TERMUX_HOME="/data/data/com.termux/files/home"
BASHRC_FILE="${TERMUX_HOME}/.bashrc"

# 如果 .bashrc 已存在，先备份
if [ -f "$BASHRC_FILE" ]; then
    cp "$BASHRC_FILE" "${BASHRC_FILE}.bak"
fi

cat >> "$BASHRC_FILE" << 'EOF'

# 自动登录 Ubuntu
proot-distro login --user new ubuntu
EOF

echo "[7/7] 配置完成！"
echo ""
echo "====================================="
echo "  安装完成！"
echo "====================================="
echo ""
echo "使用方法:"
echo "  1. 关闭并重新打开 Termux，将自动以 new 用户登录 Ubuntu"
echo "  2. 或手动运行: proot-distro login --user new ubuntu"
echo ""
echo "注意: new 用户已被设为 root 权限 (UID=0, GID=0)"
echo "      passwd 备份: ${PASSWD_FILE}.bak"
echo "      .bashrc 备份: ${BASHRC_FILE}.bak"
