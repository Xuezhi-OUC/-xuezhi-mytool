#!/bin/bash
# ============================================
# Git 管理器 v2.0
# 位置: C:\Users\32894\Desktop\RuiSa\WorkSpace
# 用途: 快速管理 LifeD 项目的 Git 操作
# ============================================

WORKSPACE="C:/Users/32894/Desktop/RuiSa/WorkSpace"
REPO_DIR="$WORKSPACE/LifeD"
REMOTE_NAME="origin"
REMOTE_URL="git@github.com:Xuezhi-OUC/LifeD2026.git"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# ============================================
# 辅助函数
# ============================================

print_banner() {
    clear
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}         Git 管理器 - LifeD 项目${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

check_repo() {
    if [ ! -d "$REPO_DIR/.git" ]; then
        print_error "LifeD 目录不是 Git 仓库"
        echo "是否要初始化？(y/n): "
        read -r choice
        if [ "$choice" = "y" ]; then
            cd "$REPO_DIR" && git init
            git remote add $REMOTE_NAME $REMOTE_URL
            print_status "仓库已初始化"
        else
            return 1
        fi
    fi
    return 0
}

press_any_key() {
    echo ""
    echo -e "${YELLOW}按回车键返回菜单...${NC}"
    read -r
}

# ============================================
# 功能 1: 上传新版本
# ============================================
push_new_version() {
    print_banner
    echo -e "${BLUE}--- 上传新版本 ---${NC}"
    echo ""

    cd "$REPO_DIR" || return

    # 显示当前状态
    echo -e "${YELLOW}当前文件状态:${NC}"
    git status -s
    echo ""

    # 输入版本说明
    echo -e "${YELLOW}请输入版本说明（例如: V4: 添加XX功能）:${NC}"
    read -r commit_msg

    if [ -z "$commit_msg" ]; then
        print_error "版本说明不能为空"
        press_any_key
        return
    fi

    # 确认提交
    echo ""
    echo -e "${YELLOW}将执行以下操作:${NC}"
    echo "  git add ."
    echo "  git commit -m \"$commit_msg\""
    echo "  git push $REMOTE_NAME main"
    echo ""
    echo -e "${YELLOW}确认提交并推送？(y/n):${NC}"
    read -r confirm

    if [ "$confirm" != "y" ]; then
        print_warn "操作已取消"
        press_any_key
        return
    fi

    # 先提交本地更改
    echo ""
    git add .
    git commit -m "$commit_msg"
    local commit_ok=$?
    if [ $commit_ok -ne 0 ]; then
        # 可能是空的提交（无修改），继续尝试推送
        print_warn "本地提交跳过（无变更）"
    else
        print_status "本地提交成功: $commit_msg"
    fi

    # 拉取远程更新（防止冲突）
    print_info "正在同步远程..."
    git pull $REMOTE_NAME main --rebase --autostash
    if [ $? -ne 0 ]; then
        print_error "同步远程失败，可能有冲突"
        echo "请手动解决冲突后重试"
        press_any_key
        return
    fi
    print_status "远程同步完成"

    # 推送
    git push $REMOTE_NAME main
    if [ $? -eq 0 ]; then
        print_status "推送成功！远程仓库已更新"
    else
        print_error "推送失败，请检查网络和权限"
        press_any_key
        return
    fi

    # 打标签
    echo ""
    local latest_tag
    latest_tag=$(git tag -l | sort -V | tail -1)
    if [ -n "$latest_tag" ]; then
        echo -e "${YELLOW}最近标签: $latest_tag${NC}"
    else
        echo -e "${YELLOW}暂无标签${NC}"
    fi
    echo -e "${YELLOW}是否创建标签归档此版本？(y/n):${NC}"
    read -r tag_confirm
    if [ "$tag_confirm" = "y" ]; then
        echo -n "输入标签名称 (例如 v1.1 / v2.2 / v3.0): "
        read -r tag_name
        if [ -n "$tag_name" ]; then
            git tag -a "$tag_name" -m "$commit_msg"
            git push $REMOTE_NAME "$tag_name"
            print_status "标签 $tag_name 已创建并推送"
        fi
    fi

    press_any_key
}

# ============================================
# 功能 2: 回档 - 用远程版本覆盖本地
# ============================================
rollback_to_remote() {
    print_banner
    echo -e "${BLUE}--- 回档 - 用远程版本覆盖本地 ---${NC}"
    echo ""
    print_warn "警告：此操作将丢弃所有本地未提交的修改！"
    echo -e "${YELLOW}  1. 本地的 readme.txt 等文件将恢复为远程版本"
    echo "  2. 所有未提交的更改将被永久丢弃"
    echo "  3. 未跟踪的文件不受影响${NC}"
    echo ""

    echo -e "${YELLOW}确认要回档？(y/n):${NC}"
    read -r confirm

    if [ "$confirm" != "y" ]; then
        print_warn "操作已取消"
        press_any_key
        return
    fi

    cd "$REPO_DIR" || return

    # 二次确认
    echo ""
    echo -e "${RED}最终确认：真的要用远程版本完全覆盖本地？(yes/no):${NC}"
    read -r final_confirm
    if [ "$final_confirm" != "yes" ]; then
        print_warn "操作已取消"
        press_any_key
        return
    fi

    print_info "正在从远程获取最新版本..."
    git fetch $REMOTE_NAME
    if [ $? -ne 0 ]; then
        print_error "无法连接到远程仓库"
        press_any_key
        return
    fi

    print_info "正在重置到远程版本..."
    git reset --hard "$REMOTE_NAME/main"
    if [ $? -eq 0 ]; then
        print_status "回档成功！本地已与远程仓库同步"
        echo ""
        echo -e "${GREEN}当前版本:${NC}"
        git log --oneline -3
    else
        print_error "回档失败"
    fi

    press_any_key
}

# ============================================
# 功能 3: 下载远程仓库（全新克隆）
# ============================================
clone_repo() {
    print_banner
    echo -e "${BLUE}--- 下载远程仓库 ---${NC}"
    echo ""

    # 检查是否已存在
    if [ -d "$REPO_DIR/.git" ]; then
        print_warn "LifeD 目录已存在 Git 仓库"
        echo -e "${YELLOW}  当前远程地址:${NC}"
        cd "$REPO_DIR" && git remote -v 2>/dev/null
        echo ""
        echo "是否要删除后重新克隆？(y/n):"
        read -r choice
        if [ "$choice" != "y" ]; then
            print_warn "操作已取消"
            press_any_key
            return
        fi

        echo -e "${RED}确认删除 $REPO_DIR 并重新克隆？(yes/no):${NC}"
        read -r confirm
        if [ "$confirm" != "yes" ]; then
            print_warn "操作已取消"
            press_any_key
            return
        fi

        print_info "正在删除旧仓库..."
        rm -rf "$REPO_DIR"
        if [ $? -ne 0 ]; then
            print_error "删除失败，请检查文件权限"
            press_any_key
            return
        fi
    fi

    # 克隆
    print_info "正在克隆仓库 $REMOTE_URL ..."
    git clone $REMOTE_URL "$REPO_DIR"
    if [ $? -eq 0 ]; then
        print_status "克隆成功！"
        print_status "仓库位置: $REPO_DIR"
    else
        print_error "克隆失败，请检查："
        echo "  - 网络连接"
        echo "  - SSH 密钥是否配置正确 (ssh -T git@github.com)"
        echo "  - 仓库地址是否正确"
    fi

    press_any_key
}

# ============================================
# 功能 4: 查看状态
# ========================================================================
show_status() {
    print_banner
    echo -e "${BLUE}--- 仓库状态 ---${NC}"
    echo ""

    cd "$REPO_DIR" || return

    echo -e "${YELLOW}分支信息:${NC}"
    git branch -a
    echo ""

    echo -e "${YELLOW}当前状态:${NC}"
    git status
    echo ""

    echo -e "${YELLOW}远程仓库:${NC}"
    git remote -v

    press_any_key
}

# ============================================
# 功能 5: 查看提交历史
# ============================================
show_history() {
    print_banner
    echo -e "${BLUE}--- 提交历史 ---${NC}"
    echo ""

    cd "$REPO_DIR" || return

    echo -e "${YELLOW}最近提交记录:${NC}"
    git log --oneline --graph --all -20
    echo ""

    echo -e "${YELLOW}版本标签:${NC}"
    git tag -l

    echo ""
    echo -e "${YELLOW}查看详细历史？(输入数字查看最近 N 条, 回车跳过):${NC}"
    read -r n
    if [ -n "$n" ] && [ "$n" -eq "$n" ] 2>/dev/null; then
        git log --oneline --graph --all -"$n"
        echo ""
        echo -e "${YELLOW}查看某次提交的详情？(输入 commit hash, 回车跳过):${NC}"
        read -r hash
        if [ -n "$hash" ]; then
            git show --stat "$hash"
        fi
    fi

    press_any_key
}

# ============================================
# 功能 6: 标签管理
# ============================================
manage_tags() {
    while true; do
        print_banner
        echo -e "${BLUE}--- 标签管理 ---${NC}"
        echo ""

        cd "$REPO_DIR" || return

        echo -e "${YELLOW}现有标签:${NC}"
        git tag -l
        echo ""

        echo "1) 创建新标签"
        echo "2) 推送标签到远程"
        echo "3) 删除本地标签"
        echo "4) 返回主菜单"
        echo ""
        echo -n "请选择 [1-4]: "
        read -r tag_choice

        case $tag_choice in
            1)
                echo -n "标签名称 (例如 v4.0): "
                read -r tag_name
                echo -n "标签说明: "
                read -r tag_msg
                if [ -n "$tag_name" ]; then
                    git tag -a "$tag_name" -m "$tag_msg"
                    print_status "本地标签 $tag_name 已创建"
                    echo ""
                    echo "是否推送到远程？(y/n):"
                    read -r push_tag
                    if [ "$push_tag" = "y" ]; then
                        git push $REMOTE_NAME "$tag_name"
                        print_status "标签 $tag_name 已推送到远程"
                    fi
                fi
                press_any_key
                ;;
            2)
                echo "1) 推送单个标签"
                echo "2) 推送所有标签"
                echo -n "请选择 [1-2]: "
                read -r push_choice
                case $push_choice in
                    1)
                        echo -n "标签名称: "
                        read -r tname
                        git push $REMOTE_NAME "$tname"
                        ;;
                    2)
                        git push --tags
                        ;;
                esac
                print_status "推送完成"
                press_any_key
                ;;
            3)
                echo -n "要删除的标签名称: "
                read -r dname
                if [ -n "$dname" ]; then
                    git tag -d "$dname"
                    echo "是否同时删除远程标签？(y/n):"
                    read -r del_remote
                    if [ "$del_remote" = "y" ]; then
                        git push $REMOTE_NAME --delete "$dname"
                    fi
                    print_status "删除完成"
                fi
                press_any_key
                ;;
            *)
                return
                ;;
        esac
    done
}

# ============================================
# 功能 7: 撤销本地修改
# ============================================
discard_changes() {
    print_banner
    echo -e "${BLUE}--- 撤销本地修改 ---${NC}"
    echo ""

    cd "$REPO_DIR" || return

    echo -e "${YELLOW}已修改的文件:${NC}"
    git status -s
    echo ""

    echo "请选择操作:"
    echo "1) 撤销所有未提交的修改（保留未跟踪文件）"
    echo "2) 撤销单个文件的修改"
    echo "3) 删除所有未跟踪文件（清理临时文件）"
    echo ""
    echo -n "请选择 [1-3] (回车取消): "
    read -r choice

    case $choice in
        1)
            echo -e "${RED}确认撤销所有修改？(yes/no):${NC}"
            read -r confirm
            if [ "$confirm" = "yes" ]; then
                git restore .
                print_status "所有已跟踪文件已恢复到最近提交状态"
            fi
            ;;
        2)
            echo -n "输入文件路径 (例如 readme.txt): "
            read -r filepath
            if [ -n "$filepath" ]; then
                git restore "$filepath"
                print_status "$filepath 已恢复"
            fi
            ;;
        3)
            echo -e "${RED}确认删除所有未跟踪文件？(yes/no):${NC}"
            read -r confirm
            if [ "$confirm" = "yes" ]; then
                git clean -fd
                print_status "未跟踪文件已清理"
            fi
            ;;
    esac

    press_any_key
}

# ============================================
# 功能 8: 快速 Git 配置检查
# ============================================
check_config() {
    print_banner
    echo -e "${BLUE}--- Git 配置检查 ---${NC}"
    echo ""

    echo -e "${YELLOW}用户信息:${NC}"
    git config --global user.name && echo "  Name: $(git config --global user.name)" || print_warn "用户名称未设置"
    git config --global user.email && echo "  Email: $(git config --global user.email)" || print_warn "用户邮箱未设置"
    echo ""

    echo -e "${YELLOW}SSH 连接测试:${NC}"
    ssh -T git@github.com 2>&1
    echo ""

    echo -e "${YELLOW}如果 SSH 有问题，检查密钥:${NC}"
    echo "  ls -la ~/.ssh/"
    echo "  或重新生成: ssh-keygen -t rsa -C \"your_email@qq.com\""

    press_any_key
}

# ============================================
# 功能 9: 从外部导入文件到仓库
# ============================================
import_file() {
    print_banner
    echo -e "${BLUE}--- 导入外部文件到仓库 ---${NC}"
    echo ""
    print_info "从电脑任意位置复制文件到仓库并提交"
    echo ""

    cd "$REPO_DIR" || return

    # 输入源文件路径
    echo -e "${YELLOW}请输入源文件路径（例如:${NC}"
    echo "  Windows: C:/Users/32894/Desktop/example.txt"
    echo "  Git Bash: /c/Users/32894/Desktop/example.txt"
    echo -e "${YELLOW}）:${NC}"
    read -r src_path

    # 展开路径中的 ~ 和变量
    src_path=$(eval echo "$src_path")

    # 检查源文件是否存在
    if [ ! -f "$src_path" ]; then
        print_error "文件不存在: $src_path"
        press_any_key
        return
    fi

    # 显示文件信息
    local filename
    filename=$(basename "$src_path")
    local filesize
    filesize=$(du -h "$src_path" | cut -f1)
    print_status "找到文件: $filename ($filesize)"

    # 输入目标路径（相对于仓库根目录）
    echo ""
    echo -e "${YELLOW}保存到仓库中的路径${NC}"
    echo -n "（直接回车保存到根目录，或输入子目录如 docs/readme.txt）: "
    read -r dest_path

    if [ -z "$dest_path" ]; then
        dest_path="$filename"
    fi

    local full_dest="$REPO_DIR/$dest_path"

    # 检查是否已存在
    if [ -f "$full_dest" ]; then
        echo ""
        print_warn "仓库中已存在: $dest_path"
        echo -n "是否覆盖？(y/n): "
        read -r overwrite
        if [ "$overwrite" != "y" ]; then
            print_warn "操作已取消"
            press_any_key
            return
        fi
    fi

    # 创建目标目录（如果包含子目录）
    local dest_dir
    dest_dir=$(dirname "$full_dest")
    if [ ! -d "$dest_dir" ]; then
        mkdir -p "$dest_dir"
    fi

    # 复制文件
    cp "$src_path" "$full_dest"
    if [ $? -ne 0 ]; then
        print_error "文件复制失败"
        press_any_key
        return
    fi
    print_status "文件已复制到: $dest_path"

    # 提交
    echo ""
    echo -e "${YELLOW}版本说明（例如: 添加 $filename）:${NC}"
    read -r commit_msg
    if [ -z "$commit_msg" ]; then
        commit_msg="添加文件: $filename"
    fi

    echo ""
    echo -e "${YELLOW}将执行:${NC}"
    echo "  git add \"$dest_path\""
    echo "  git commit -m \"$commit_msg\""
    echo "  git push $REMOTE_NAME main"
    echo ""
    echo -n "确认提交并推送？(y/n): "
    read -r confirm

    if [ "$confirm" != "y" ]; then
        print_warn "操作已取消（文件已复制到仓库，可手动提交）"
        press_any_key
        return
    fi

    # 只添加导入的文件
    git add "$dest_path"
    git commit -m "$commit_msg"
    local commit_ok=$?
    if [ $commit_ok -ne 0 ]; then
        print_warn "提交跳过（无变更）"
    fi

    # 拉取最新
    print_info "正在同步远程..."
    git pull $REMOTE_NAME main --rebase --autostash
    if [ $? -ne 0 ]; then
        print_error "同步失败，请手动处理"
        press_any_key
        return
    fi

    if [ $? -eq 0 ]; then
        git push $REMOTE_NAME main
        if [ $? -eq 0 ]; then
            print_status "文件已提交并推送到远程仓库！"
        else
            print_error "推送失败"
        fi
    else
        print_error "提交失败"
    fi

    press_any_key
}

# ============================================
# 主菜单
# ============================================
show_menu() {
    print_banner

    # 显示当前仓库摘要
    cd "$REPO_DIR" 2>/dev/null || return
    echo -e "${GREEN}仓库:${NC} LifeD"
    echo -e "${GREEN}分支:${NC} $(git branch --show-current 2>/dev/null || echo 'N/A')"
    echo -e "${GREEN}远程:${NC} $REMOTE_URL"
    echo -e "${GREEN}最新标签:${NC} $(git tag -l | sort -V | tail -1 2>/dev/null || echo '无')"
    echo -e "${GREEN}状态:${NC} $(git status -s 2>/dev/null | wc -l) 个文件待提交"
    echo ""

    echo -e "${YELLOW}================== 操作菜单 ==================${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC}) ${BLUE}上传新版本${NC}       git add → commit → push"
    echo -e "  ${GREEN}2${NC}) ${BLUE}回档${NC}             用远程版本完全覆盖本地"
    echo -e "  ${GREEN}3${NC}) ${BLUE}下载远程仓库${NC}     全新克隆远程仓库"
    echo ""
    echo -e "  ${GREEN}4${NC}) ${BLUE}查看状态${NC}         查看工作区状态和分支信息"
    echo -e "  ${GREEN}5${NC}) ${BLUE}提交历史${NC}         查看版本历史和标签"
    echo -e "  ${GREEN}6${NC}) ${BLUE}标签管理${NC}         创建/推送/删除版本标签"
    echo -e "  ${GREEN}7${NC}) ${BLUE}撤销修改${NC}         丢弃本地未提交的更改"
    echo -e "  ${GREEN}8${NC}) ${BLUE}配置检查${NC}         检查 Git 和 SSH 配置"
    echo -e "  ${GREEN}9${NC}) ${BLUE}导入文件${NC}         从电脑任意位置导入文件到仓库"
    echo ""
    echo -e "  ${GREEN}0${NC}) ${RED}退出${NC}"
    echo ""
    echo -e "${YELLOW}==============================================${NC}"
    echo -n "请选择 [0-9]: "
}

# ============================================
# 程序入口
# ============================================
main() {
    # 首次运行检查
    if [ ! -f "$REPO_DIR/.gitignore" ]; then
        print_warn "首次运行建议执行配置检查和初始化"
        echo ""
    fi

    while true; do
        check_repo || {
            echo "按回车键退出..."
            read -r
            exit 1
        }

        show_menu
        read -r choice

        case $choice in
            1) push_new_version ;;
            2) rollback_to_remote ;;
            3) clone_repo ;;
            4) show_status ;;
            5) show_history ;;
            6) manage_tags ;;
            7) discard_changes ;;
            8) check_config ;;
            9) import_file ;;
            0)
                echo ""
                print_status "再见！"
                exit 0
                ;;
            *)
                print_warn "无效选择，请输入 0-9"
                sleep 1
                ;;
        esac
    done
}

main
