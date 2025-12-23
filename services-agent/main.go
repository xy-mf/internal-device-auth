package main

import (
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"os"
	"runtime"
	"strings"
)

// --- 1. 数据模型定义 ---

type Config struct {
	Port int `json:"port"`
}

type InterfaceInfo struct {
	Name string `json:"name"`
	IP   string `json:"ip"`
	Mac  string `json:"mac"`
}

type Response struct {
	Interfaces []InterfaceInfo `json:"interfaces"`
	OS         string          `json:"os"`
	Version    string          `json:"version"`
	Status     string          `json:"status"`
}

const AppVersion = "1.0.0"
const DefaultPort = 18888

// --- 2. 核心业务逻辑 (硬件采集) ---

// getDeviceInterfaces 采集网卡信息
func getDeviceInterfaces() []InterfaceInfo {
	var result []InterfaceInfo
	interfaces, _ := net.Interfaces()

	for _, inter := range interfaces {
		// 基础过滤
		if !isValidInterface(inter) {
			continue
		}

		// 获取最佳匹配 IP
		ip := getBestIP(inter)
		if ip == "" {
			continue
		}

		result = append(result, InterfaceInfo{
			Name: inter.Name,
			IP:   ip,
			Mac:  strings.ToUpper(inter.HardwareAddr.String()),
		})
	}
	return result
}

// isValidInterface 判断网卡是否有效
func isValidInterface(inter net.Interface) bool {
	hasMac := inter.HardwareAddr.String() != ""
	isUp := (inter.Flags & net.FlagUp) != 0
	isLoopback := (inter.Flags & net.FlagLoopback) != 0
	return hasMac && isUp && !isLoopback
}

// getBestIP 获取单个网卡最核心的 IP (IPv4 优先)
func getBestIP(inter net.Interface) string {
	addrs, err := inter.Addrs()
	if err != nil {
		return ""
	}

	var bestIP string
	for _, addr := range addrs {
		ipnet, ok := addr.(*net.IPNet)
		if !ok || ipnet.IP.IsLoopback() {
			continue
		}

		// 1. 优先选 IPv4
		if v4 := ipnet.IP.To4(); v4 != nil {
			return v4.String()
		}

		// 2. 备选全局 IPv6 (非链路本地地址 fe80)
		if bestIP == "" && !ipnet.IP.IsLinkLocalUnicast() {
			bestIP = ipnet.IP.String()
		}
	}
	return bestIP
}

// --- 3. 配置与基础设施 ---

// loadConfig 加载本地配置
func loadConfig() Config {
	conf := Config{Port: DefaultPort}
	data, err := os.ReadFile("config.json")
	if err == nil {
		_ = json.Unmarshal(data, &conf)
	}
	return conf
}

// deviceHandler API 处理器
func deviceHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	res := Response{
		Interfaces: getDeviceInterfaces(),
		OS:         runtime.GOOS,
		Version:    AppVersion,
		Status:     "success",
	}
	_ = json.NewEncoder(w).Encode(res)
}

// exitHandler 处理退出请求
func exitHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	// 构造返回消息，告诉前端“我正在退出”
	res := map[string]string{
		"status":  "success",
		"message": "服务正在关闭...",
	}
	_ = json.NewEncoder(w).Encode(res)

	// 启动一个 goroutine 延迟退出，确保当前的 HTTP 响应能成功发回给浏览器
	go func() {
		fmt.Println("接收到退出请求，正在关闭服务...")
		os.Exit(0)
	}()
}

// --- 4. 主函数 ---

func main() {
	config := loadConfig()

	http.HandleFunc("/api/device", deviceHandler)
	http.HandleFunc("/api/exit", exitHandler)

	addr := fmt.Sprintf("127.0.0.1:%d", config.Port)
	fmt.Printf("🚀 设备鉴权助手启动成功\n")
	fmt.Printf("📍 监听地址: %s\n", addr)
	fmt.Printf("💻 操作系统: %s | 版本: %s\n", runtime.GOOS, AppVersion)

	if err := http.ListenAndServe(addr, nil); err != nil {
		fmt.Printf("❌ 服务启动失败: %v\n", err)
		os.Exit(1)
	}
}