# 照片自动分类工具

根据照片的拍摄日期自动将照片分类到日期命名的文件夹中。

## 功能特性

- 自动读取照片/视频 EXIF 数据获取拍摄日期
- 支持多种图片格式（JPG, PNG, HEIC, RAW 等）
- 支持多种视频格式（MP4, MOV, AVI, MKV 等）
- 自动创建日期文件夹（格式：YYYY-MM-DD）
- 支持指定独立的源目录和目标目录
- 支持测试模式，预览操作而不实际移动文件
- 彩色日志输出，清晰展示处理过程
- 智能跳过已分类的照片

## 安装

### 1. 克隆或下载此脚本

```bash
git clone git@github.com:TerrisZhao/auto-file-organizer.git
cd auto-file-organizer
```

### 2. 安装 exiftool（可选但强烈推荐）

使用 Homebrew 安装：

```bash
brew install exiftool
```

如果不安装 exiftool，脚本会使用 macOS 的 `mdls` 命令或文件修改时间作为后备方案。

## 使用方法

### 基本用法

```bash
# 在源目录中整理（文件移动到源目录下的日期文件夹）
./organize_photos.sh ~/Downloads

# 指定源目录和目标目录（文件从源目录移动到目标目录下的日期文件夹）
./organize_photos.sh ~/Downloads /abc/photo

# 测试模式（预览将要执行的操作，不实际移动文件）
./organize_photos.sh --dry-run ~/Downloads /abc/photo
```

**参数说明：**
- **源目录**：照片/视频文件所在的位置（必需）
- **目标目录**：分类后文件的存放位置（可选，默认与源目录相同）

### 使用示例

**示例 1：在同一目录中整理**

假设你有以下照片：

```
~/Downloads/
├── IMG_001.jpg  (拍摄于 2024-01-15)
├── IMG_002.jpg  (拍摄于 2024-01-15)
├── IMG_003.jpg  (拍摄于 2024-01-20)
└── IMG_004.jpg  (拍摄于 2024-02-01)
```

运行脚本：

```bash
./organize_photos.sh ~/Downloads
```

结果（文件在源目录中按日期分类）：

```
~/Downloads/
├── 2024-01-15/
│   ├── IMG_001.jpg
│   └── IMG_002.jpg
├── 2024-01-20/
│   └── IMG_003.jpg
└── 2024-02-01/
    └── IMG_004.jpg
```

**示例 2：移动到指定的目标目录**

假设你有以下照片：

```
~/Downloads/
├── IMG_001.jpg  (拍摄于 2025-11-13)
├── IMG_002.jpg  (拍摄于 2025-11-14)
└── video.mp4    (拍摄于 2025-11-13)
```

运行脚本：

```bash
./organize_photos.sh ~/Downloads /abc/photo
```

结果（文件从源目录移动到目标目录下的日期文件夹）：

```
~/Downloads/
(空，所有文件已移走)

/abc/photo/
├── 2025-11-13/
│   ├── IMG_001.jpg
│   └── video.mp4
└── 2025-11-14/
    └── IMG_002.jpg
```

## 定时任务设置

推荐使用快速安装脚本：

```bash
./install_cron.sh
```

该脚本会引导你选择定时任务方式（launchd 或 cron）并设置源目录和目标目录。

### 手动设置 cron（Linux/macOS）

1. 编辑 crontab：

```bash
crontab -e
```

2. 添加定时任务（示例：每天凌晨 2 点执行）：

```cron
# 在源目录中整理
0 2 * * * /path/to/organize_photos.sh "/path/to/source" >> /tmp/organize_photos.log 2>&1

# 或者指定目标目录
0 2 * * * /path/to/organize_photos.sh "/path/to/source" "/path/to/destination" >> /tmp/organize_photos.log 2>&1
```

3. 查看定时任务：

```bash
crontab -l
```

### 手动设置 launchd（macOS）

1. 创建 plist 文件：

```bash
nano ~/Library/LaunchAgents/com.user.organize-photos.plist
```

2. 添加以下内容（根据需要选择一种配置）：

**配置 1：在源目录中整理**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.organize-photos</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/organize_photos.sh</string>
        <string>/path/to/source</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>2</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/organize_photos.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/organize_photos.error.log</string>
</dict>
</plist>
```

**配置 2：指定目标目录**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.organize-photos</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/organize_photos.sh</string>
        <string>/path/to/source</string>
        <string>/path/to/destination</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>2</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/organize_photos.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/organize_photos.error.log</string>
</dict>
</plist>
```

3. 加载定时任务：

```bash
launchctl load ~/Library/LaunchAgents/com.user.organize-photos.plist
```

4. 管理定时任务：

```bash
# 启动
launchctl start com.user.organize-photos

# 停止
launchctl stop com.user.organize-photos

# 卸载
launchctl unload ~/Library/LaunchAgents/com.user.organize-photos.plist
```

## 支持的格式

### 图片格式

- JPG / JPEG
- PNG
- GIF
- BMP
- TIFF / TIF
- HEIC / HEIF / HIF (iPhone)
- RAW / CR2 / NEF / ARW / DNG (相机原始格式)

### 视频格式

- MP4
- MOV
- AVI
- MKV
- M4V
- 3GP
- FLV
- WMV
- MPG / MPEG
- M2TS / MTS

## 日期获取优先级

脚本会按以下优先级尝试获取照片日期：

1. EXIF DateTimeOriginal（如果安装了 exiftool）
2. macOS Spotlight 元数据（kMDItemContentCreationDate）
3. 文件修改时间（后备方案）

## 注意事项

- 脚本只处理指定目录的第一层文件，不会递归子文件夹
- 已经在正确日期文件夹中的照片会被跳过
- 如果目标位置已存在同名文件，会跳过移动
- 建议先使用 `--dry-run` 模式测试

## 故障排查

### 无法获取拍摄日期

如果大量照片显示"无法获取日期"：

1. 安装 exiftool 获得更好的支持
2. 检查照片文件是否包含 EXIF 数据
3. 某些编辑过的照片可能丢失了 EXIF 信息

### 权限问题

确保脚本有执行权限：

```bash
chmod +x organize_photos.sh
```

### 定时任务不执行

检查日志文件：

```bash
# cron 日志
tail -f /tmp/organize_photos.log

# launchd 日志
tail -f /tmp/organize_photos.log
tail -f /tmp/organize_photos.error.log
```

## 许可证

MIT License
