# Freqtrade 管理器

一个基于 Flutter 开发的 Freqtrade 交易管理客户端应用。

## 功能特点

### 1. 用户认证
- 安全的登录/退出系统
- 凭证安全存储
- 会话管理

### 2. 市场数据
- 实时 K 线图表展示
- 交易数据可视化
- 自动数据刷新（30秒间隔）
- 手动刷新功能

### 3. 交易管理
- 查看开放交易
- 交易操作界面
- 实时交易状态更新

### 4. 系统功能
- Material Design 3 界面设计
- 响应式布局
- 深色/浅色主题支持
- 通知服务
- 可配置侧边栏

## 技术栈

- Flutter
- Provider 状态管理
- SharedPreferences 本地存储
- Material Design 3
- RESTful API 集成

## 项目结构

```
lib/
├── main.dart              # 应用入口
├── screens/              # 页面界面
├── services/             # 服务层
├── widgets/              # 可复用组件
├── models/               # 数据模型
└── providers/            # 状态管理
```

## 开发环境要求

- Flutter SDK
- Dart SDK
- Android Studio / VS Code
- Git

## 安装和运行

1. 克隆项目
```bash
git clone [项目地址]
```

2. 安装依赖
```bash
flutter pub get
```

3. 运行项目
```bash
flutter run
```

## 配置说明

1. API 配置
   - 在设置中配置 Freqtrade API 地址
   - 设置 API 密钥

2. 通知设置
   - 配置交易通知
   - 设置提醒方式

## 贡献指南

欢迎提交 Issue 和 Pull Request 来帮助改进项目。 