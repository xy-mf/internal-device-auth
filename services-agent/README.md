# Internal Device Auth Agent
该工具用于内网跨网段环境下的设备 MAC 地址识别，支持跨平台运行。

## 🛠 开发环境运行
```bash
cd client-agent
go run main.go
```

## 🔌 API 接口说明
Agent 启动后默认监听 127.0.0.1:18888，提供以下接口：
| 接口地址|  请求方式|功能描述|返回示例|
|--------|---------|-------|--------|
|/api/device|GET|获取当前设备所有活跃网卡的 IP、MAC 及系统信息|{"interfaces": [...], "os": "windows", "version": "1.0.0", "status": "success"}|
|/api/exit|GET|安全退出进程。调用后 Agent 会延迟 0.5s 自动关闭|{"status": "success", "message": "服务正在关闭..."}|

其中，`interfaces` 字段是一个数组，每个元素包含以下字段：
| 字段名称|  类型|功能描述|
|--------|---------|-------|
|name|string|网卡名称|
|ip|string|网卡 IP|
|mac|string|网卡 MAC|   

## 📦 打包分发

项目支持按平台构建及自动 ZIP 压缩。脚本位于 client-agent/build/build.sh。

```bash
# 构建所有平台 (Windows, macOS, Linux)
sh build/build.sh

# 构建指定平台并自动打包成 ZIP (推荐分发方式)
sh build/build.sh -p windows -z
sh build/build.sh -p macos -z
```

**参数说明：**
- -p: 指定平台 (可选: windows, macos, linux, all，默认 all)
- -z: 开启后，会在 dist/ 目录下自动生成对应的 .zip 压缩包。

## 📖 维护说明
1. 端口修改: 直接修改 config.json 中的 port。（需要考虑怎么和web-demo同步修改之后的端口号）
2. 静默运行特性 (无黑窗口)
为了不打扰用户，程序在 Windows 和 macOS 下均实现了“隐身”运行：
- Windows: 编译时使用了 -H windowsgui，双击后无任何窗口。需在“任务管理器 -> 详细信息”中查看 DeviceAuth.exe。
- macOS: 封装为 .app 包并开启了 LSUIElement。双击后 Dock 栏无图标、无窗口。需在“活动监视器”中搜索 DeviceAuth 查看。
- Linux: 提供 `start.sh` 脚本。运行后程序进入后台，终端可直接关闭。
  
3. 如何退出程序
    **3.1 通过接口退出（推荐方式）**
    由于程序在各平台均以无窗口/后台模式运行，推荐通过接口进行优雅退出：
    - 浏览器退出: 直接在地址栏输入 http://127.0.0.1:18888/api/exit。
    - 命令行退出:
    - Windows: curl http://127.0.0.1:18888/api/exit
    - Mac/Linux: curl http://127.0.0.1:18888/api/exit
    - 前端退出: 在网页中使用 axios 或 fetch 请求该接口即可实现静默关闭。

    **3.2 强制结束进程（系统方式）**
    若接口失效，可通过以下方式强行关闭：
    - Windows: 打开“任务管理器” -> “详细信息”，找到 DeviceAuth.exe 并结束任务。
    - macOS: 打开“活动监视器”，搜索 DeviceAuth 并强制退出。
    - Linux: 执行 pkill DeviceAuth 或通过 ps -ef | grep DeviceAuth 找到 PID 后使用 kill 命令。

4. 跨域与安全
- 默认允许所有源 (Access-Control-Allow-Origin: *) 访问 127.0.0.1。
- 如需限定仅允许特定的内网域名访问，请修改 main.go 中的 deviceHandler 函数。

---
## 🚀 分发指南
1. 获取产物：运行 `sh build/build.sh -z`。
2. 提取包：进入 build/dist/ 文件夹。
3. 交付用户：
- Windows: 提供 DeviceAuth_windows.zip。
- macOS: 提供 DeviceAuth_macos.zip（内含 Intel 和 M1 双版本）。
- 解压即用: 用户解压后，保持 .exe 与 config.json 在同一目录即可运行。
