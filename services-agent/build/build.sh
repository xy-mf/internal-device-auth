#!/bin/bash

# 确保在脚本所在目录执行时路径正确
cd "$(dirname "$0")"

# 定义变量
DIST_ROOT="./dist"
APP_NAME="DeviceAuth"
SRC_PATH="../main.go"
CONFIG_PATH="../config.json"

# 默认参数
PLATFORM="all"
NEED_ZIP=false

# 处理输入参数
while getopts "p:z" opt; do
  case $opt in
    p) PLATFORM=$OPTARG ;;
    z) NEED_ZIP=true ;;
    *) echo "用法: ./build.sh [-p windows|macos|linux|all] [-z]" && exit 1 ;;
  esac
done

# 初始清理输出根目录（可选，如果不希望删除其他平台的产物，可以注释掉这一行）
rm -rf $DIST_ROOT

# 编译函数封装
build_windows() {
    echo "📦 Building Windows..."
    local TARGET_DIR="$DIST_ROOT/windows"
    mkdir -p "$TARGET_DIR"

    CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -ldflags="-s -w -H windowsgui" -o "$TARGET_DIR/${APP_NAME}.exe" "$SRC_PATH"
    cp "$CONFIG_PATH" "$TARGET_DIR/"

    if [ "$NEED_ZIP" = true ]; then
        (cd "$TARGET_DIR" && zip -q -r "../${APP_NAME}_windows.zip" .)
        echo "   └─ Created: ${APP_NAME}_windows.zip"
    fi
}

build_linux() {
    echo "📦 Building Linux..."
    local TARGET_DIR="$DIST_ROOT/linux"
    mkdir -p "$TARGET_DIR"

    # 编译二进制
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o "$TARGET_DIR/${APP_NAME}" "$SRC_PATH"
    cp "$CONFIG_PATH" "$TARGET_DIR/"

    # 创建一个一键静默启动脚本
    cat <<EOF > "$TARGET_DIR/start.sh"
#!/bin/bash
cd "\$(dirname "\$0")"
chmod +x ${APP_NAME}
nohup ./${APP_NAME} > /dev/null 2>&1 &
echo "服务已在后台启动。"
EOF
    chmod +x "$TARGET_DIR/start.sh"
}

build_macos() {
    echo "📦 Building macOS (Silent App Bundle)..."
    local TARGET_DIR="$DIST_ROOT/macos"
    local APP_BUNDLE="$TARGET_DIR/${APP_NAME}.app"
    local MACOS_DIR="$APP_BUNDLE/Contents/MacOS"

    # 1. 创建标准的 .app 目录结构
    mkdir -p "$MACOS_DIR"

    # 2. 编译 Intel 和 M1 版本
    CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -ldflags="-s -w" -o "$MACOS_DIR/${APP_NAME}_intel" "$SRC_PATH"
    CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build -ldflags="-s -w" -o "$MACOS_DIR/${APP_NAME}_m1" "$SRC_PATH"

    # 3. 创建一个简单的启动脚本，由它来决定运行哪个架构，且不带窗口
    cat <<EOF > "$MACOS_DIR/${APP_NAME}_launcher"
#!/bin/bash
cd "\$(dirname "\$0")"
# 拷贝配置文件到 App 内部（如果外部没有）
cp -n ../../../config.json . 2>/dev/null
# 根据架构运行程序
arch_name=\$(uname -m)
if [ "\$arch_name" = "x86_64" ]; then
    ./${APP_NAME}_intel &
else
    ./${APP_NAME}_m1 &
fi
EOF
    chmod +x "$MACOS_DIR/${APP_NAME}_launcher"

    # 4. 创建 Info.plist（这是关键：告诉系统它是后台程序）
    cat <<EOF > "$APP_BUNDLE/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}_launcher</string>
    <key>CFBundleIdentifier</key>
    <string>com.device.auth</string>
    <key>LSUIElement</key>
    <string>1</string>
</dict>
</plist>
EOF

    # 5. 把配置文件放在 .app 同级，方便用户修改
    cp "$CONFIG_PATH" "$TARGET_DIR/"

    if [ "$NEED_ZIP" = true ]; then
        (cd "$TARGET_DIR" && zip -q -r "../${APP_NAME}_macos.zip" .)
        echo "   └─ Created: ${APP_NAME}_macos.zip"
    fi
}

# 执行逻辑
echo "🚀 开始构建流程 (平台: $PLATFORM, 压缩: $NEED_ZIP)"

case $PLATFORM in
    "windows") build_windows ;;
    "linux")   build_linux ;;
    "macos")   build_macos ;;
    "all")
        rm -rf "$DIST_ROOT" # 只有在全量构建时才彻底清空根目录
        build_windows
        build_linux
        build_macos
        ;;
    *)         echo "错误: 未知平台 '$PLATFORM'。可选值: windows, macos, linux, all" && exit 1 ;;
esac

echo "---------------------------------------"
echo "✅ 构建完成！"