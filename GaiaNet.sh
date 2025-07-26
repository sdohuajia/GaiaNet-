#!/bin/bash

# 检查是否以root用户运行脚本
if [[ $EUID -ne 0 ]]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 函数：安装 GaiaNet 节点
function install_node() {
    echo "开始更新系统、安装依赖、清除旧 GaiaNet 节点并安装新节点..."

    # 更新包列表并升级系统
    apt update && apt upgrade -y

    # 安装 python3-pip
    apt install -y python3-pip

    # 安装 pip（确保最新版本）
    apt install -y pip

    # 安装开发依赖
    apt install -y build-essential libssl-dev libffi-dev python3-dev

    # 停止 GaiaNet 节点（如果已安装）
    echo "停止 GaiaNet 节点..."
    if command -v gaianet >/dev/null 2>&1; then
        gaianet stop
    else
        echo "GaiaNet 未安装，跳过停止步骤。"
    fi

    # 下载并运行 GaiaNet 卸载脚本
    echo "下载并运行 GaiaNet 卸载脚本..."
    curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/uninstall.sh' | bash

    # 重新加载 .bashrc 以应用环境变量
    BASHRC_PATH="/root/.bashrc"
    if [ -f "$BASHRC_PATH" ]; then
        echo "重新加载 $BASHRC_PATH 以应用 GaiaNet 的环境变量配置..."
        source "$BASHRC_PATH"
    else
        echo "未找到 $BASHRC_PATH，跳过重新加载。"
        echo "请手动运行 'source /root/.bashrc' 或重新打开终端以应用 GaiaNet 的环境变量。"
    fi

    # 下载并运行 GaiaNet 安装脚本
    echo "下载并运行 GaiaNet 安装脚本..."
    curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash

    # 检查 gaianet 命令是否可用
    if command -v gaianet >/dev/null 2>&1; then
        # 初始化 GaiaNet 节点
        echo "初始化 GaiaNet 节点，使用 qwen2-0.5b-instruct 配置文件（可能需要一些时间）..."
        if curl -s --head --fail "https://raw.githubusercontent.com/GaiaNet-AI/node-configs/main/qwen2-0.5b-instruct/config.json" >/dev/null; then
            if gaianet init --config https://raw.githubusercontent.com/GaiaNet-AI/node-configs/main/qwen2-0.5b-instruct/config.json; then
                echo "GaiaNet 节点初始化成功！"
            else
                echo "错误：GaiaNet 节点初始化失败。请检查错误信息或手动运行 'gaianet init'。"
                exit 1
            fi
        else
            echo "错误：无法访问配置文件 URL。请检查网络或配置文件地址。"
            exit 1
        fi
    else
        echo "错误：未找到 gaianet 命令，初始化失败。请检查 GaiaNet 安装是否成功。"
        exit 1
    fi

    # 启动 GaiaNet 节点
    echo "启动 GaiaNet 节点..."
    if gaianet start; then
        echo "GaiaNet 节点已启动。"
    else
        echo "错误：GaiaNet 节点启动失败。请检查错误信息或手动运行 'gaianet start'。"
        exit 1
    fi

    # 重新加载 .bashrc 以应用环境变量
    BASHRC_PATH="/root/.bashrc"
    if [ -f "$BASHRC_PATH" ]; then
        echo "重新加载 $BASHRC_PATH 以应用 GaiaNet 的环境变量配置..."
        source "$BASHRC_PATH"
    else
        echo "未找到 $BASHRC_PATH，跳过重新加载。"
        echo "请手动运行 'source /root/.bashrc' 或重新打开终端以应用 GaiaNet 的环境变量。"
    fi

    # 验证 gaianet 命令是否可用
    if command -v gaianet >/dev/null 2>&1; then
        echo "GaiaNet 命令已正确配置，可运行 'gaianet'。"
    else
        echo "警告：未找到 gaianet 命令，环境变量可能未正确设置。请手动运行 'source /root/.bashrc' 或检查安装步骤。"
    fi

    echo "节点安装和启动完成。"
}

# 函数：查看节点信息
function view_node_info() {
    echo "获取节点信息..."
    BASHRC_PATH="/root/.bashrc"
    if [ -f "$BASHRC_PATH" ]; then
        source "$BASHRC_PATH"
    else
        echo "未找到 $BASHRC_PATH，环境变量可能未正确加载。"
    fi
    if command -v gaianet >/dev/null 2>&1; then
        gaianet info
    else
        echo "错误：未找到 gaianet 命令，请确保节点已正确安装。"
    fi
    read -n 1 -s -r -p "按任意键返回主菜单..."
}

# 函数：启动自动聊天机器人
function start_chatbot() {
    echo "开始启动自动聊天机器人..."

    # 安装 screen（如果未安装）
    if ! command -v screen >/dev/null 2>&1; then
        echo "未找到 screen，安装 screen..."
        apt install -y screen
    fi

    # 下载 bot.py 文件
    BOT_URL="https://raw.githubusercontent.com/sdohuajia/GaiaNet-/refs/heads/main/bot.py"
    BOT_PATH="/root/bot.py"
    echo "下载 bot.py 文件..."
    if curl -L -o "$BOT_PATH" "$BOT_URL"; then
        echo "bot.py 下载成功，保存到 $BOT_PATH。"
    else
        echo "错误：无法下载 bot.py 文件。请检查网络或 URL 地址。"
        exit 1
    fi

    # 检查 bot.py 文件是否存在且可执行
    if [ -f "$BOT_PATH" ]; then
        chmod +x "$BOT_PATH"
    else
        echo "错误：bot.py 文件不存在，下载可能失败。"
        exit 1
    fi

    # 检查 python3 是否安装
    if ! command -v python3 >/dev/null 2>&1; then
        echo "错误：未找到 python3，请确保 Python3 已安装。"
        exit 1
    fi

    # 加载 .bashrc 以确保环境变量正确
    BASHRC_PATH="/root/.bashrc"
    if [ -f "$BASHRC_PATH" ]; then
        echo "加载 $BASHRC_PATH 以确保环境变量正确..."
        source "$BASHRC_PATH"
    else
        echo "警告：未找到 $BASHRC_PATH，环境变量可能未正确加载。"
    fi

    # 检查是否已存在名为 gaia 的 screen 会话
    if screen -list | grep -q "gaia"; then
        echo "检测到已存在的 gaia screen 会话，正在终止..."
        screen -S gaia -X quit
    fi

    # 在新的 screen 会话中运行 bot.py
    echo "在 screen 会话 'gaia' 中启动 python3 bot.py..."
    screen -dmS gaia python3 "$BOT_PATH"
    if [ $? -eq 0 ]; then
        echo "自动聊天机器人已在 screen 会话 'gaia' 中启动。"
        echo "使用 'screen -r gaia' 查看运行中的 bot.py，或者 'screen -list' 查看所有 screen 会话。"
    else
        echo "错误：无法启动 screen 会话 'gaia'。请检查 screen 和 python3 环境。"
        exit 1
    fi

    read -n 1 -s -r -p "按任意键返回主菜单..."
}

# 函数：显示主菜单
function main_menu() {
    while true; do
        clear  # 清屏
        echo "脚本由推特 @ferdie_jhovie 制作，免费开源，请勿相信收费"
        echo "GaiaNet 一键安装脚本"
        echo "======================="
        echo "1. 安装 GaiaNet 节点"
        echo "2. 查看节点信息"
        echo "3. 启动自动聊天机器人"
        echo "4. 退出脚本"
        echo "======================="
        read -p "请选择操作（输入对应数字）：" OPTION

        case $OPTION in
            1)
                install_node
                read -n 1 -s -r -p "按任意键返回主菜单..."
                ;;
            2)
                view_node_info
                ;;
            3)
                start_chatbot
                ;;
            4)
                echo "退出脚本。"
                exit
                ;;
            *)
                echo "无效的选项，请重新选择。"
                read -n 1 -s -r -p "按任意键返回主菜单..."
                ;;
        esac
    done
}

# 运行主菜单
main_menu
