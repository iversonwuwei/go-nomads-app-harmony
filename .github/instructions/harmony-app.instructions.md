---
applyTo: "**/*.{ets,ts}"
---

# HarmonyOS 鸿蒙 App 开发规范

## 技术栈
- HarmonyOS SDK 6.0.1(21)
- ArkTS（TypeScript-like 语言）
- 设备类型: phone

## 目录结构
```
go_nomads_app/src/main/ets/
├── common/       # 公共工具与常量
├── models/       # 数据模型（TypeScript interface）
├── pages/        # 页面组件（@Entry @Component）
├── services/     # 网络请求与业务服务
└── state/        # 全局状态管理
```

## 页面开发
- 每个页面使用 `@Entry @Component` 装饰器
- 页面文件放在 `pages/` 目录
- Tab 页面放在 `pages/tabs/`
- 新页面需在 `module.json5` 中注册路由

## 功能对齐
- 鸿蒙版需与 Flutter 版功能保持一致
- API 接口与 Flutter App 共用同一套后端 Gateway
- 新增功能参考 Flutter 版 `go-nomads-app` 对应的 feature 实现

## 权限
- 当前已申请: `ohos.permission.INTERNET`, `ohos.permission.GET_NETWORK_INFO`
- 新增权限需在 `module.json5` 中声明

## 资源
- 字符串、图片等资源放在 `src/main/resources/`
- 基础资源在 `base/` 目录
- 多语言资源按 locale 目录组织
