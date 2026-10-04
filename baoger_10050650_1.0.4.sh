#!/usr/bin/bash

# ===== 配置区 =====
LOCAL_VERSION="1.0.4"
REMOTE_VERSION_URL="https://raw.githubusercontent.com/MN0322/notebook-with-mn/main/version.txt"    #验证版本号
REMOTE_SCRIPT_URL="https://raw.githubusercontent.com/MN0322/notebook-with-mn/main/baoger_10050650_1.0.4.sh"  #更新链接
REMOTE_CHANGELOG_URL="https://raw.githubusercontent.com/MN0322/notebook-with-mn/main/log.txt"  #获取更新日志
FILE_URL="https://raw.githubusercontent.com/MN0322/notebook-with-mn/main/keybox.xml"                 #keybox密钥下载链接
DOWNLOAD_DIR="/storage/emulated/0/Download" #存放目录
TEMP_FILE="$DOWNLOAD_DIR/keybox.xml"
TARGET_DIR="/data/adb/tricky_store"            #替换目录
KEY_URL="https://raw.githubusercontent.com/MN0322/notebook-with-mn/main/key.txt"                          #读取卡密内容
# ==================
show_changelog() {
    echo "===== 更新日志 ====="
    if ! curl -fsSL --max-time 10 "$REMOTE_CHANGELOG_URL" 2>/dev/null; then
        echo "获取更新日志失败"
    fi
    echo
    echo "===================="
}

check_update() {
    remote_version=$(curl -fsSL --max-time 10 "$REMOTE_VERSION_URL" 2>/dev/null | tr -d '[:space:]')
    [ -z "$remote_version" ] && return 1

    if [ "$remote_version" = "$LOCAL_VERSION" ]; then
        echo "当前已为最新版"
        return 0
    fi

    newest=$(printf '%s\n%s' "$LOCAL_VERSION" "$remote_version" | sort -V | tail -1)
    if [ "$newest" = "$LOCAL_VERSION" ]; then
        echo "开发者，你似乎当前版本比云端版本更高，请检查上传云端"
        echo "当前本地版本:$LOCAL_VERSION"
        exit 0
    fi

    echo "发现新版本: $remote_version (当前: $LOCAL_VERSION)"
    echo "正在更新..."

    tmp_file=$(mktemp)
    if curl -fsSL --max-time 30 "$REMOTE_SCRIPT_URL" -o "$tmp_file" 2>/dev/null; then
        chmod --reference="$0" "$tmp_file" 2>/dev/null || chmod +x "$tmp_file"
        mv "$tmp_file" "$0"
        echo "更新完成，请重新运行脚本。"
        exit 0
    else
        rm -f "$tmp_file"
        echo "更新下载失败，继续使用当前版本。"
    fi
}
download_and_move() {
    echo "开始下载文件..."
    
    # 1. 检查并创建目标文件夹
    if [ ! -d "$TARGET_DIR" ]; then
        mkdir -p "$TARGET_DIR" || { echo "创建目标文件夹失败，请检查权限！"; return 1; }
    fi

    # 2. 下载文件
    if ! curl -fsSL --max-time 30 "$FILE_URL" -o "$TEMP_FILE"; then
        echo "下载失败，请检查网络或链接。"
        return 1
    fi
    echo "密钥文件下载成功"

    # 3. 复制文件到目标文件夹
    cp -f "$TEMP_FILE" "$TARGET_DIR/" 2>/dev/null
    copy_status=$?

    # 4. 删除源文件
    rm -f "$TEMP_FILE"
    echo "已清理下载目录临时文件。"

    # 5. 根据复制结果输出提示
    if [ $copy_status -eq 0 ]; then
        echo "密钥更新成功"
    else
        echo "密钥更新失败！"
        return 1
    fi
}
key() {
    # 直接从云端读取内容到变量，不保存到本地    
    correct_key=$(curl -fsSL --max-time 3 "${KEY_URL}?t=$(date +%s)" 2>/dev/null | tr -d '[:space:]')
    
    if [ -z "$correct_key" ]; then
        echo "云端key解析失败，请使用VPN再执行"
        exit 1
    fi

    echo -n "请输入卡密: "
    read input_key

    # 防止 read 失败导致异常
    if [ $? -ne 0 ]; then
        echo "输入读取失败"
        exit 1
    fi

    # 去掉输入里的空格换行
    input_key=$(echo "$input_key" | tr -d '[:space:]')

    if [ "$input_key" = "$correct_key" ]; then
        echo "卡密正确"
        return 0
    else
        echo "卡密错误"
        exit 1
    fi
}
font(){
# 定义颜色
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
MAGENTA='\033[35m'
BOLD='\033[1m'
RESET='\033[0m'
#输出baoger字体
printf "${CYAN}${BOLD}"
printf "  ____                                \n"
printf "${GREEN}${BOLD}"
printf " | __ )  __ _  ___   __ _  ___ _ __   \n"
printf "${YELLOW}${BOLD}"
printf " |  _ \\ / _\` |/ _ \\ / _\` |/ _ \\ '__|  \n"
printf "${MAGENTA}${BOLD}"
printf " | |_) | (_| | (_) | (_| |  __/ |     \n"
printf "${CYAN}${BOLD}"
printf " |____/ \\__,_|\\___/ \\__, |\\___|_|     \n"
printf "${GREEN}${BOLD}"
printf "                     |___/            \n"
printf "${RESET}\n"

# 底部栏
printf "${GREEN}Welcome ${CYAN}Baoger ${GREEN}System${RESET}\n"
printf "${MAGENTA}| Kernel HW Breakpoint Tracking & Leak Patch${RESET}\n"
printf "${CYAN}[${GREEN} OK ${CYAN}]${RESET} Initialized with success.\n"
}


# ===== 主逻辑 =====
main() {
# ===== 菜单界面与主循环 =====
sleep 1
while true; do
    clear
    font
    echo ""
    echo "=================================="
    echo "          功能菜单"
    echo "=================================="
    echo "  1. 一键替换有效keybox密钥"
    echo "  2. 查看更新日志"
    echo "  0. 退出脚本"
    echo "=================================="
    
    echo -n "请输入序号并回车: "
    read choice

    if [ $? -ne 0 ]; then
        echo "读取输入失败，已退出。"
        exit 1
    fi

    case "$choice" in
        1) download_and_move ;;
        2) show_changelog ;;   
        0) echo "已退出"; exit 0 ;;
        *) echo "输入无效，请输入 0-3 的数字。" ;;
    esac

    echo ""
    echo -n "按回车键返回菜单..."
    read -r dummy
done
    # 功能添加处
}

# 函数调用入口 
if [ "$1" = "--log" ] || [ "$1" = "-l" ]; then
    show_changelog
    exit 0
fi
font
sleep 1
key
show_changelog
check_update
main "$@"
