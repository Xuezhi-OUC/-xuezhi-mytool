# xuezhi-mytool 🛠️

> 个人 Git 版本管理工具集 — 技能速查卡 + 交互式管理脚本
> Git skill card & interactive manager for everyday version control.

---

## 📦 包含文件 | Files

| 文件 | 用途 |
|------|------|
| `SKILL-GIT.md` | Git 技能速查卡：初始化 / 提交 / 标签 / 回档 / 分支 / 常见问题 |
| `git-manager.sh` | 交互式 Bash 脚本：菜单驱动，一键完成版本管理 |

## 🚀 快速开始 | Quick Start

```bash
# 克隆
git clone git@github.com:Xuezhi-OUC/-xuezhi-mytool.git

# 运行脚本
cd xuezhi-mytool
./git-manager.sh
```

**将这两个文件复制到你的项目根目录即可使用。**

---

## 🎯 脚本功能一览 | Features

| 选项 | 功能 | 说明 |
|------|------|------|
| `1` | 上传新版本 | `add → commit → pull → push` + 可选打标签 |
| `2` | 回档 | 远程版本覆盖本地 |
| `3` | 下载仓库 | 全新克隆 |
| `4` | 查看状态 | 分支 / 修改 / 远程信息 |
| `5` | 提交历史 | 版本历史 + 标签 |
| `6` | 标签管理 | 创建 / 推送 / 删除标签 |
| `7` | 撤销修改 | 丢弃本地未提交更改 |
| `8` | 配置检查 | Git 身份 / SSH 连通性 |
| `9` | 导入文件 | 从电脑任意位置复制文件到仓库 |

## 📖 适用场景 | Use Cases

- 🔄 **日常版本管理**：一键提交推送，自动同步远程
- 🏷️ **版本归档**：灵活标签命名（v1.0 / v1.1 / v2.2）
- 📂 **文件导入**：将散落各处的文件纳入版本管理
- ⏪ **回滚恢复**：远程覆盖本地，快速回到稳定版本
- 🆕 **新项目初始化**：Git 速通流程，从零到推送

---

## 📄 License

MIT
