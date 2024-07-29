#!/bin/bash

# 函数：安装 Docker
function install_docker() {
    echo "正在安装 Docker..."
    sudo apt-get update
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    echo "Docker 安装完成！"
}

# 函数：检查 Docker 是否已安装
function check_docker_installed() {
    if ! command -v docker &> /dev/null; then
        echo "未检测到 Docker 安装，正在安装 Docker..."
        install_docker
    else
        echo "Docker 已安装，跳过安装步骤。"
    fi
}

# 函数：安装 GaiaNet 节点（包括初始化）
function install_node() {
    echo "正在安装 GaiaNet 节点..."
    echo "请稍候..."

    # 检查并安装 Docker
    check_docker_installed

    # 下载并运行 GaiaNet 的 install.sh 脚本
    curl -sSfL 'https://raw.githubusercontent.com/GaiaNet-AI/gaianet-node/main/install.sh' | bash

    # 检查安装结果
    if [ $? -ne 0 ]; then
        echo "安装过程中出现错误，请检查网络连接或稍后重试。"
        return 1
    fi

    # 初始化 GaiaNet 节点（下载模型文件和矢量数据库文件）
    echo "正在初始化 GaiaNet 节点..."
    gaianet init $HOME/gaianet/config.json

    echo "GaiaNet 节点安装成功！"
}

# 函数：启动 GaiaNet 节点
function start_node() {
    echo "正在启动 GaiaNet 节点..."

    # 进入 GaiaNet 目录（请替换为实际的 gaianet 目录路径）
    cd /path/to/gaianet  # 替换为实际的 gaianet 目录路径

    # 执行 gaianet start 命令
    gaianet start

    # 检查 gaianet start 的退出码
    if [ $? -ne 0 ]; then
        echo "启动节点过程中出现错误，请检查相关配置或稍后重试。"
    else
        echo "GaiaNet 节点启动成功！"
    fi
}

# 函数：卸载 GaiaNet 节点
function uninstall_node() {
    echo "正在卸载 GaiaNet 节点..."
    echo "请稍候..."

    # 停止 GaiaNet 节点
    gaianet stop

    # 停止并删除 GaiaNet 节点容器
    docker stop gaianet-node
    docker rm gaianet-node

    # 删除 GaiaNet 节点数据和配置
    sudo rm -rf ~/.gaianet

    echo "GaiaNet 节点卸载完成。"
}

# 函数：显示 GaiaNet 节点信息
function gaianet_info() {
    echo "显示 GaiaNet 节点信息..."
    # 在这里编写显示 GaiaNet 节点信息的代码，例如调用 gaianet info 命令
    gaianet info
}

# 函数：显示主菜单
function main_menu() {
    while true; do
        clear  # 清屏
        echo "脚本由推特 @ferdie_jhovie，免费开源，请勿相信收费"
        echo "GaiaNet 一键安装脚本"
        echo "======================="
        echo "1. 安装 GaiaNet 节点"
        echo "2. 启动 GaiaNet 节点"
        echo "3. 卸载 GaiaNet 节点"
        echo "4. GaiaNet 节点信息"
        echo "5. 退出脚本"
        echo "======================="
        read -p "请选择操作（输入对应数字）：" OPTION

        case $OPTION in
            1)
                install_node
                read -n 1 -s -r -p "按任意键返回主菜单..."
                ;;
            2)
                start_node
                read -n 1 -s -r -p "按任意键返回主菜单..."
                ;;
            3)
                uninstall_node
                read -n 1 -s -r -p "按任意键返回主菜单..."
                ;;
            4)
                gaianet_info
                read -n 1 -s -r -p "按任意键返回主菜单..."
                ;;
            5)
                echo "退出脚本。"
                exit 0
                ;;
            *)
                echo "无效选项，请重新输入。"
                ;;
        esac
    done
}

# 执行主菜单函数
main_menu
