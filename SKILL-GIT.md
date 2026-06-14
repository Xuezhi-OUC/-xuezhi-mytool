# Git 技能卡 — 通用版本管理

> 适用任何项目，复制到新仓库根目录即可。
> 配套脚本: [git-manager.sh](git-manager.sh)（交互式菜单，推荐）

---

## 一、交互脚本速览（推荐）

```bash
cd /c/Users/32894/Desktop/RuiSa/WorkSpace
./git-manager.sh
```

| 选项 | 功能 | 说明 |
|------|------|------|
| **1** | 上传新版本 | add → commit → pull → push + 可选打标签 |
| **2** | 回档 | 用远程版本完全覆盖本地（丢弃本地修改） |
| **3** | 下载仓库 | 全新克隆远程仓库 |
| **4** | 查看状态 | 分支、修改、远程信息 |
| **5** | 提交历史 | 版本历史 + 标签列表 |
| **6** | 标签管理 | 创建/推送/删除标签 |
| **7** | 撤销修改 | 丢弃本地未提交的更改 |
| **8** | 配置检查 | Git 身份 / SSH 连通性 |
| **9** | 导入文件 | 从电脑任意位置复制文件到仓库并提交 |
| **0** | 退出 | — |

---

## 二、新仓库速通

```bash
# 1. 初始化
git init
git add .
git commit -m "首次提交"

# 2. 关联远程（GitHub 上先建空仓库，不要勾选 README）
git remote add origin git@github.com:<用户名>/<仓库名>.git
git branch -M main
git push -u origin main

# 3. 打首个标签
git tag -a v1.0 -m "初始版本"
git push origin v1.0
```

---

## 三、日常上传新版本

```bash
# 方式一：交互脚本
./git-manager.sh  →  选 1

# 方式二：手动
git add .
git commit -m "V2: 更新说明"
git pull --rebase --autostash   # 先同步远程
git push
# 可选打标签
git tag -a v2.0 -m "V2: 更新说明"
git push origin v2.0
```

---

## 四、导入外部文件

把电脑上任意位置的文件加入仓库版本管理。

```bash
# 方式一：交互脚本（推荐）
./git-manager.sh  →  选 9
# 输入源路径 → 输入仓库内目标路径 → 自动 add + commit + push

# 方式二：手动
cp /c/Users/32894/Desktop/某文件.txt .
git add 某文件.txt
git commit -m "添加文件: 某文件.txt"
git pull --rebase --autostash
git push
```

路径示例：

| 系统 | 格式 |
|------|------|
| Git Bash | `/c/Users/32894/Desktop/文件.txt` |
| Windows | `C:/Users/32894/Desktop/文件.txt` |

---

## 五、版本标签（存档里程碑）

```bash
# 创建标签
git tag -a v1.1 -m "V1.1: 修复XX问题"    # 附注标签（推荐）
git tag v1.1                              # 轻量标签（只有指针）

# 推送标签
git push origin v1.1       # 推送单个
git push --tags            # 推送全部

# 查看标签
git tag -l                              # 列表
git log --oneline --decorate            # 带标签的日志
git show v1.1                           # 查看标签详情

# 删除标签
git tag -d v1.1                         # 本地
git push origin --delete v1.1           # 远程

# 切到某版本（只读）
git checkout v2.0
# 基于该版本开新分支继续开发
git checkout -b fix-branch v2.0
```

标签命名灵活：`v1.0`、`v1.1`、`v2.2`、`v3.0` 均可。

---

## 六、回档（远程覆盖本地）

> 丢弃所有本地未提交修改，回到远程最新状态。

```bash
# 方式一：交互脚本
./git-manager.sh  →  选 2

# 方式二：手动
git fetch origin
git reset --hard origin/main
```

---

## 七、全新克隆

```bash
git clone git@github.com:<用户名>/<仓库名>.git
# 或指定目录名
git clone git@github.com:<用户名>/<仓库名>.git MyProject
```

---

## 八、查看状态与历史

```bash
git status                # 工作区状态
git status -s             # 精简模式
git log --oneline -10     # 最近 10 条
git log --oneline --graph --all  # 全部分支图谱
git diff                  # 未暂存的修改
git diff --staged         # 已暂存的修改
git show <commit-hash>    # 查看某次提交详情
```

---

## 九、撤销与修复

```bash
# 撤销未提交的修改
git restore <文件>        # 单个文件
git restore .             # 全部文件

# 撤销已暂存的修改
git restore --staged <文件>

# 删掉未跟踪的文件
git clean -fd

# 修改最近一条 commit 信息
git commit --amend -m "新消息"

# 回到某个历史版本
git reset --hard <hash>   # 本地 hard reset（慎用，会丢失之后的所有提交）
```

---

## 十、分支操作

```bash
# 创建并切换
git checkout -b feature-xxx

# 合并到主分支
git checkout main
git merge feature-xxx

# 删除分支
git branch -d feature-xxx                   # 本地
git push origin --delete feature-xxx        # 远程

# 查看所有分支
git branch -a
```

---

## 十一、SSH 配置（首次使用 GitHub）

```bash
# 设置身份（一次即可）
git config --global user.name "你的GitHub用户名"
git config --global user.email "你的邮箱@example.com"

# 生成密钥
ssh-keygen -t rsa -C "你的邮箱@qq.com"

# 复制公钥 → 添加到 GitHub: Settings → SSH and GPG keys → New SSH key
cat ~/.ssh/id_rsa.pub

# 测试连接
ssh -T git@github.com
```

---

## 十二、.gitignore 通用模板

```gitignore
# 编译输出
Debug/
Release/
build/
*.o
*.d
*.elf
*.map
*.hex
*.bin

# IDE
.idea/
.vscode/
*.swp
.settings/
.classpath
.project

# 日志
*.log

# 系统
.DS_Store
Thumbs.db
```

> `.gitignore` 在 `git add` 前创建才有效。已跟踪的文件需用 `git rm --cached` 先取消跟踪。

---

## 十三、常用缩写

| 操作 | 实际命令 | 说明 |
|------|---------|------|
| `s` | `git status` | 查看状态 |
| `a` | `git add .` | 暂存所有 |
| `c "msg"` | `git commit -m "msg"` | 提交 |
| `p` | `git push` | 推送 |
| `l` | `git log --oneline` | 历史 |
| `d` | `git diff` | 差异 |
| `t` | `git tag -l` | 标签列表 |

---

## 十四、常见问题

| 问题 | 解决 |
|------|------|
| `pull` 报 "unstaged changes" | 先 `git add . && git commit` 再 pull，或 `git stash` 暂存 |
| 提交错了想撤回 | `git reset --soft HEAD~1`（保留文件，撤销 commit） |
| 想放弃所有本地修改 | `git restore . && git clean -fd` |
| 推送被拒绝（远程有新提交） | `git pull --rebase` 再 `git push` |
| 标签打错了 | `git tag -d v1.0 && git push origin --delete v1.0` |

---

> 将此文件复制到新仓库根目录，配合 [git-manager.sh](git-manager.sh) 使用效果更佳。
