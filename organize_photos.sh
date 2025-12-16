#!/bin/bash

# 照片自动分类脚本
# 根据照片的拍摄日期，将照片移动到对应日期的文件夹中

# 配置部分
SOURCE_DIR="${1:-.}"  # 默认为当前目录，可通过第一个参数指定
DATE_FORMAT="%Y-%m-%d"  # 文件夹日期格式：2024-01-15
DRY_RUN=false  # 是否为测试模式（只显示不实际移动）

# 支持的图片格式（不区分大小写）
IMAGE_EXTENSIONS="jpg jpeg png gif bmp tiff tif heic heif raw cr2 nef arw dng"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否安装了 exiftool（更准确）
HAS_EXIFTOOL=false
if command -v exiftool &> /dev/null; then
    HAS_EXIFTOOL=true
    log_info "检测到 exiftool，将使用 EXIF 数据获取拍摄日期"
else
    log_warn "未检测到 exiftool，将使用 macOS mdls 命令（如果可用）或文件修改时间"
fi

# 获取照片拍摄日期
get_photo_date() {
    local file="$1"
    local date_taken=""

    # 方法1: 使用 exiftool（最准确）
    if [ "$HAS_EXIFTOOL" = true ]; then
        date_taken=$(exiftool -DateTimeOriginal -d "$DATE_FORMAT" -s3 "$file" 2>/dev/null)
        if [ -n "$date_taken" ]; then
            echo "$date_taken"
            return 0
        fi
    fi

    # 方法2: 使用 macOS 的 mdls 命令
    if command -v mdls &> /dev/null; then
        # 尝试获取内容创建日期
        local mdls_date=$(mdls -name kMDItemContentCreationDate -raw "$file" 2>/dev/null)
        if [ "$mdls_date" != "(null)" ] && [ -n "$mdls_date" ]; then
            # mdls 输出格式: 2024-01-15 10:30:45 +0000
            date_taken=$(echo "$mdls_date" | awk '{print $1}')
            if [ -n "$date_taken" ]; then
                echo "$date_taken"
                return 0
            fi
        fi
    fi

    # 方法3: 使用文件修改时间作为后备方案
    if [ "$(uname)" = "Darwin" ]; then
        # macOS
        date_taken=$(stat -f "%Sm" -t "$DATE_FORMAT" "$file" 2>/dev/null)
    else
        # Linux
        date_taken=$(date -r "$file" +"$DATE_FORMAT" 2>/dev/null)
    fi

    echo "$date_taken"
}

# 检查文件是否为图片
is_image_file() {
    local file="$1"
    local ext="${file##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

    for valid_ext in $IMAGE_EXTENSIONS; do
        if [ "$ext" = "$valid_ext" ]; then
            return 0
        fi
    done
    return 1
}

# 主处理函数
process_photos() {
    local source_dir="$1"
    local processed=0
    local skipped=0
    local errors=0

    log_info "开始处理目录: $source_dir"
    log_info "================================"

    # 使用 find 命令遍历所有文件（不递归到已创建的日期文件夹）
    while IFS= read -r -d '' file; do
        # 跳过目录
        if [ -d "$file" ]; then
            continue
        fi

        # 获取文件名
        filename=$(basename "$file")

        # 检查是否为图片文件
        if ! is_image_file "$filename"; then
            continue
        fi

        # 获取拍摄日期
        date_folder=$(get_photo_date "$file")

        if [ -z "$date_folder" ]; then
            log_warn "无法获取日期: $filename (跳过)"
            ((skipped++))
            continue
        fi

        # 检查文件是否已经在正确的文件夹中
        current_dir=$(dirname "$file")
        current_dir_name=$(basename "$current_dir")
        if [ "$current_dir_name" = "$date_folder" ]; then
            log_info "已在正确位置: $filename -> $date_folder/"
            ((skipped++))
            continue
        fi

        # 创建目标文件夹
        target_dir="$source_dir/$date_folder"
        if [ ! -d "$target_dir" ]; then
            if [ "$DRY_RUN" = false ]; then
                mkdir -p "$target_dir"
                if [ $? -ne 0 ]; then
                    log_error "创建文件夹失败: $target_dir"
                    ((errors++))
                    continue
                fi
            fi
            log_info "创建文件夹: $date_folder/"
        fi

        # 移动文件
        target_file="$target_dir/$filename"

        # 检查目标文件是否已存在
        if [ -f "$target_file" ]; then
            log_warn "文件已存在: $target_file (跳过)"
            ((skipped++))
            continue
        fi

        if [ "$DRY_RUN" = true ]; then
            log_info "[测试模式] 将移动: $filename -> $date_folder/"
        else
            mv "$file" "$target_file"
            if [ $? -eq 0 ]; then
                log_info "已移动: $filename -> $date_folder/"
                ((processed++))
            else
                log_error "移动失败: $filename"
                ((errors++))
            fi
        fi

    done < <(find "$source_dir" -maxdepth 1 -type f -print0)

    # 输出统计信息
    log_info "================================"
    log_info "处理完成!"
    log_info "成功处理: $processed 个文件"
    log_info "跳过: $skipped 个文件"
    if [ $errors -gt 0 ]; then
        log_error "失败: $errors 个文件"
    fi
}

# 显示帮助信息
show_help() {
    cat << EOF
照片自动分类脚本

用法:
    $0 [选项] [目录]

参数:
    目录          要处理的照片目录（默认为当前目录）

选项:
    -h, --help    显示此帮助信息
    -d, --dry-run 测试模式，只显示将要执行的操作，不实际移动文件

示例:
    $0                      # 处理当前目录
    $0 ~/Pictures/Photos    # 处理指定目录
    $0 --dry-run            # 测试模式

说明:
    - 脚本会根据照片的 EXIF 拍摄日期创建文件夹（格式：YYYY-MM-DD）
    - 支持的图片格式: jpg, jpeg, png, gif, bmp, tiff, heic, raw 等
    - 如果安装了 exiftool，将获得更准确的拍摄日期
    - 否则使用 macOS mdls 命令或文件修改时间

安装 exiftool (可选，推荐):
    brew install exiftool

EOF
}

# 解析命令行参数
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            SOURCE_DIR="$1"
            shift
            ;;
    esac
done

# 检查源目录是否存在
if [ ! -d "$SOURCE_DIR" ]; then
    log_error "目录不存在: $SOURCE_DIR"
    exit 1
fi

# 转换为绝对路径
SOURCE_DIR=$(cd "$SOURCE_DIR" && pwd)

# 开始处理
process_photos "$SOURCE_DIR"

exit 0
