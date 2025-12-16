#!/bin/bash

# 定时任务快速安装脚本

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}照片自动分类 - 定时任务安装脚本${NC}"
echo "================================"

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORGANIZE_SCRIPT="$SCRIPT_DIR/organize_photos.sh"

# 检查脚本是否存在
if [ ! -f "$ORGANIZE_SCRIPT" ]; then
    echo -e "${RED}错误: 找不到 organize_photos.sh${NC}"
    exit 1
fi

# 让用户选择方法
echo ""
echo "请选择定时任务方式："
echo "1) launchd (macOS 推荐)"
echo "2) cron (传统方式)"
echo "3) 取消"
echo ""
read -p "请输入选项 [1-3]: " choice

case $choice in
    1)
        # launchd 方式
        echo ""
        read -p "请输入照片目录的完整路径: " PHOTOS_DIR

        if [ ! -d "$PHOTOS_DIR" ]; then
            echo -e "${YELLOW}警告: 目录不存在，但会继续安装${NC}"
        fi

        # 创建 plist 文件
        PLIST_FILE="$HOME/Library/LaunchAgents/com.user.organize-photos.plist"

        cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.organize-photos</string>
    <key>ProgramArguments</key>
    <array>
        <string>$ORGANIZE_SCRIPT</string>
        <string>$PHOTOS_DIR</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>2</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>WorkingDirectory</key>
    <string>$SCRIPT_DIR</string>
    <key>StandardOutPath</key>
    <string>/tmp/organize_photos.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/organize_photos.error.log</string>
    <key>KeepAlive</key>
    <false/>
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
EOF

        echo -e "${GREEN}已创建: $PLIST_FILE${NC}"

        # 加载 launchd 任务
        launchctl unload "$PLIST_FILE" 2>/dev/null
        launchctl load "$PLIST_FILE"

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}定时任务已成功安装！${NC}"
            echo ""
            echo "任务将在每天凌晨 2:00 自动运行"
            echo ""
            echo "管理命令："
            echo "  查看日志: tail -f /tmp/organize_photos.log"
            echo "  立即运行: launchctl start com.user.organize-photos"
            echo "  停止任务: launchctl stop com.user.organize-photos"
            echo "  卸载任务: launchctl unload $PLIST_FILE"
        else
            echo -e "${RED}安装失败，请检查错误信息${NC}"
            exit 1
        fi
        ;;

    2)
        # cron 方式
        echo ""
        read -p "请输入照片目录的完整路径: " PHOTOS_DIR

        if [ ! -d "$PHOTOS_DIR" ]; then
            echo -e "${YELLOW}警告: 目录不存在，但会继续安装${NC}"
        fi

        # 创建 cron 任务
        CRON_CMD="0 2 * * * $ORGANIZE_SCRIPT \"$PHOTOS_DIR\" >> /tmp/organize_photos.log 2>&1"

        # 检查是否已存在
        if crontab -l 2>/dev/null | grep -q "$ORGANIZE_SCRIPT"; then
            echo -e "${YELLOW}检测到已存在的定时任务${NC}"
            read -p "是否替换? [y/N]: " replace
            if [ "$replace" != "y" ] && [ "$replace" != "Y" ]; then
                echo "已取消"
                exit 0
            fi
            # 删除旧任务
            crontab -l 2>/dev/null | grep -v "$ORGANIZE_SCRIPT" | crontab -
        fi

        # 添加新任务
        (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}定时任务已成功安装！${NC}"
            echo ""
            echo "任务将在每天凌晨 2:00 自动运行"
            echo ""
            echo "管理命令："
            echo "  查看任务: crontab -l"
            echo "  查看日志: tail -f /tmp/organize_photos.log"
            echo "  编辑任务: crontab -e"
            echo "  删除任务: crontab -e (然后删除对应行)"
        else
            echo -e "${RED}安装失败，请检查错误信息${NC}"
            exit 1
        fi
        ;;

    3)
        echo "已取消"
        exit 0
        ;;

    *)
        echo -e "${RED}无效选项${NC}"
        exit 1
        ;;
esac

echo ""
echo "================================"
echo -e "${GREEN}安装完成！${NC}"
echo ""
echo "提示："
echo "  - 可以先用 '$ORGANIZE_SCRIPT --dry-run $PHOTOS_DIR' 测试"
echo "  - 建议安装 exiftool 以获得更准确的日期: brew install exiftool"
