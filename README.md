# 键鼠共享大师

一个基于 [Deskflow](https://github.com/deskflow/deskflow) 二次开发的局域网键盘鼠标共享工具。

目标是保留 Deskflow 稳定的底层键鼠共享能力，同时把 Windows 使用体验改得更适合中文用户：中文界面、局域网自动发现、自动配对、自动重连、一键安装和托盘常驻。

## 下载

当前 Windows x64 稳定版：**v1.26.0.479**

- [下载键鼠共享大师 v1.26.0.479](https://github.com/xiewuchen666/KeyboardMouseShareMaster/releases/tag/v1.26.0.479)

普通用户直接下载并运行上面的 EXE 即可。安装器会自动检测并补齐所需的 Microsoft Visual C++ x64 Runtime。

## 快速使用（这是教程，必读！）
特别注意：设备需要处于同一个局域网！
1. 两台 Windows 电脑都安装“键鼠共享大师”。
2. 准备共享键盘鼠标的电脑选择“将此计算机设为服务器”。
3. 另一台电脑选择“将此计算机设为客户端”。
4. 两台电脑处于同一局域网时，客户端会自动发现并连接服务器。
5. 在服务器中配置两台屏幕的相对位置，例如第二台电脑在右侧，就把它拖到服务器右边。
6. 鼠标移动到屏幕边缘并继续推动，即可跨到另一台电脑，键盘会随当前屏幕一起切换。
<img width="430" height="540" alt="1" src="https://github.com/user-attachments/assets/33cac923-a2cd-4b41-9fdf-a8005cfd9f78" />
<img width="633" height="678" alt="2" src="https://github.com/user-attachments/assets/4c610a06-c833-481d-89d6-f3a5be8599e3" />
<img width="430" height="540" alt="3" src="https://github.com/user-attachments/assets/f0df8192-71e3-4e92-a866-80d3b4c483aa" />
<img width="726" height="641" alt="4" src="https://github.com/user-attachments/assets/bb117219-7e01-4adf-93b4-53ed5608d3d6" />

首次建立 TLS 信任时仍会保留安全确认，不会自动绕过证书指纹验证。

## 主要功能

- 一套键盘鼠标控制多台电脑
- 简体中文界面
- 局域网自动发现服务器
- 首次连接自动登记客户端
- 记住已配对服务器，IP 变化后自动更新
- 默认开启断线自动重连
- 保留 TLS 首次指纹确认，不自动绕过信任校验
- Windows 登录后自动隐藏到系统托盘
- 双击桌面快捷方式可唤起主界面
- 点击关闭按钮后回到托盘，不中断后台连接
- Windows 一键 EXE 安装器
- 安装器自动检测/补齐 Microsoft Visual C++ x64 Runtime
- 独立品牌、安装器、服务显示名和防火墙规则
- 已关闭官方 Deskflow 更新检查，避免误升级回上游版本

## 当前状态

Windows x64 **v1.26.0.479** 已完成实机双机验证。

已验证场景：

- Windows 主机作为服务器
- Windows 客户端自动发现并连接
- 鼠标跨屏
- 键盘跟随当前屏幕
- 自动重连
- 托盘常驻
- 开机启动
- 一键安装与覆盖升级

macOS 已完成部分品牌和 Bundle 前置适配，但尚未完成 Apple Silicon 实机编译、权限验证和 DMG 发布。

## Windows 构建

### 依赖

- Visual Studio 2022 Build Tools / MSVC
- CMake
- Qt 6.8.x
- vcpkg
- OpenSSL 3.x
- WiX Toolset 4（生成 MSI/EXE 安装器时需要）

本项目当前开发环境使用：

- Qt 6.8.3
- OpenSSL 3.4.x
- WiX 4.x

### 配置

```powershell
cmake -S . -B build-package `
  -DCMAKE_TOOLCHAIN_FILE=D:\Programs\vcpkg\scripts\buildsystems\vcpkg.cmake `
  -DCMAKE_PREFIX_PATH=D:\Programs\Qt\6.8.3\msvc2022_64 `
  -DBUILD_TESTS=OFF `
  -DBUILD_INSTALLER=ON
```

### 编译并生成 MSI

```powershell
cmake --build build-package --config Release --target package
```

### 生成单文件 EXE 安装器

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\deploy\windows\build-bundle.ps1
```

最终分发文件生成到：

```text
dist/
```

其中推荐给普通用户的是：

```text
KeyboardMouseShareMaster-Setup-<version>-x64.exe
```

## Windows 内部安装路径

虽然产品显示名是“键鼠共享大师”，Windows 内部安装目录仍固定使用 ASCII 路径：

```text
C:\Program Files\Deskflow-cn
```

这是有意设计。当前 Deskflow Windows daemon 在通过服务启动核心进程时，对中文可执行路径存在兼容问题。用户可见名称仍然全部使用“键鼠共享大师”。

## 与上游 Deskflow 的主要区别

| 项目 | Deskflow 上游 | 键鼠共享大师 |
| --- | --- | --- |
| 中文界面 | 部分翻译 | 补全简体中文 |
| 局域网设备发现 | 原有配置方式 | 增加 UDP 自动发现 |
| 首次配对 | 需要人工配置 | 自动登记客户端 |
| DHCP / IP 变化 | 可能需要重新配置 | 按设备名更新服务器地址 |
| 自动重连 | 有能力 | 默认启用 |
| 官方更新检查 | 启用 | 已关闭 |
| Windows 安装 | 上游安装方式 | 自带 VC++ Runtime 的一键 EXE |
| 托盘 | 上游逻辑 | Windows 默认开机隐藏常驻 |
| 品牌 | Deskflow | 键鼠共享大师 |

底层键鼠协议、TLS、安全模型和大量核心代码仍来自 Deskflow。本项目不是重新实现一个新的 KVM 协议。

## 上游同步

本仓库保留官方 Deskflow 作为 `upstream`：

```text
https://github.com/deskflow/deskflow.git
```

同步上游时建议先拉取并在独立分支处理冲突，不要直接覆盖本项目的品牌、自动发现、安装器和托盘改动。

## 目录说明

```text
src/                 Deskflow 核心与 GUI 源码
translations/        翻译资源
deploy/windows/      Windows MSI / Burn 一键安装器
deploy/mac/          macOS 打包配置
tools/               本项目辅助脚本
docs/                上游文档
LICENSES/            第三方许可证
```

构建目录和发布产物不会提交到 Git：

```text
build-*/
dist/
```

## 开源来源与许可证

本项目是 Deskflow 的修改版，不是 Deskflow 官方发行版。

上游项目：

- Deskflow: https://github.com/deskflow/deskflow

本仓库保留了上游的 `LICENSE`、`LICENSES/`、`REUSE.toml` 以及原始版权信息。

代码按仓库中对应 SPDX 标识和许可证文件发布，核心部分遵循 GNU GPL v2 及上游声明的 OpenSSL 例外。使用、修改或再分发前请阅读：

- `LICENSE`
- `LICENSES/`
- `REUSE.toml`

“键鼠共享大师”是本修改版使用的产品显示名称，不代表 Deskflow 官方项目。
