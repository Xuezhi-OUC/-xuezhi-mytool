#!/bin/bash
# ============================================
# Git 管理器 v2.0 (通用版)
# 通用 Git 管理脚本，适用任何 Git 仓库
# 用法:
#   直接运行 → 管理当前目录所在仓库
#   传参路径  → 管理指定目录的仓库
#   复制到项目根目录运行即可
# ============================================

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================
# 辅助函数
# ============================================

print_banner() {
    clear
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}         Git 管理器 (通用版)${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error()  { echo -e "${RED}[✗]${NC} $1"; }
print_warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
print_info()   { echo -e "${BLUE}[i]${NC} $1"; }

press_any_key() {
    echo ""
    echo -e "${YELLOW}按回车键返回菜单...${NC}"
    read -r
}

# 自动检测仓库
detect_repo() {
    local target_dir="${1:-.}"
    cd "$target_dir" 2>/dev/null || {
        print_error "无法进入目录: $target_dir"
        return 1
    }

    # 向上查找 .git
    while [ ! -d ".git" ] && [ "$PWD" != "/" ] && [ "$PWD" != "C:/" ]; do
        cd ..
    done

    if [ ! -d ".git" ]; then
        print_error "当前目录不是 Git 仓库"
        echo -n "是否初始化？(y/n): "
        read -r choice
        if [ "$choice" = "y" ]; then
            git init
            print_status "Git 仓库已初始化"
            echo -n "输入远程仓库地址 (例如 git@github.com:用户/仓库.git，直接回车跳过): "
            read -r url
            if [ -n "$url" ]; then
                git remote add origin "$url"
                print_status "远程仓库已添加: $url"
            fi
        else
            return 1
        fi
    fi

    # 读取仓库信息
    REPO_NAME=$(basename "$(pwd)")
    REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "未设置")
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
    REPO_DIR=$(pwd)

    # 判断主分支名
    MAIN_BRANCH="main"
    git show-ref --verify --quiet refs/heads/master && MAIN_BRANCH="master"
    git show-ref --verify --quiet refs/heads/main && MAIN_BRANCH="main"

    return 0
}

# ============================================
# 功能 1: 上传新版本
# ============================================
push_new_version() {
    print_banner
    echo -e "${BLUE}--- 上传新版本 ---${NC}"
    echo ""

    echo -e "${YELLOW}当前文件状态:${NC}"
    git status -s
    echo ""

    echo -e "${YELLOW}请输入版本说明 (例如 V2: 添加XX功能):${NC}"
    read -r commit_msg

    [ -z "$commit_msg" ] && { print_error "版本说明不能为空"; press_any_key; return; }

    echo ""
    echo -e "${YELLOW}将执行:${NC}"
    echo "  git add ."
    echo "  git commit -m \"$commit_msg\""
    echo "  git pull && git push"
    echo ""
    echo -n "确认提交并推送？(y/n): "
    read -r confirm
    [ "$confirm" != "y" ] && { print_warn "已取消"; press_any_key; return; }

    # 提交
    echo ""
    git add .
    git commit -m "$commit_msg"
    local commit_ok=$?
    [ $commit_ok -ne 0 ] && print_warn "本地提交跳过（无变更）" || print_status "本地提交成功: $commit_msg"

    # 推送
    if git remote -v | grep -q origin; then
        print_info "正在同步远程..."
        git pull origin "$MAIN_BRANCH" --rebase --autostash
        if [ $? -ne 0 ]; then
            print_error "同步失败，可能有冲突"; press_any_key; return
        fi
        print_status "远程同步完成"
        git push origin "$MAIN_BRANCH"
        [ $? -eq 0 ] && print_status "推送成功！" || { print_error "推送失败"; press_any_key; return; }
    else
        print_warn "未设置远程仓库，仅在本地提交"; press_any_key; return
    fi

    # 打标签
    echo ""
    local latest_tag=$(git tag -l | sort -V | tail -1)
    [ -n "$latest_tag" ] && echo -e "${YELLOW}最近标签: $latest_tag${NC}" || echo -e "${YELLOW}暂无标签${NC}"
    echo -n "是否创建标签归档此版本？(y/n): "
    read -r tag_confirm
    if [ "$tag_confirm" = "y" ]; then
        echo -n "标签名称 (例如 v1.0 / v1.1 / v2.2): "
        read -r tag_name
        if [ -n "$tag_name" ]; then
            git tag -a "$tag_name" -m "$commit_msg"
            git push origin "$tag_name"
            print_status "标签 $tag_name 已创建并推送"
        fi
    fi

    press_any_key
}

# ============================================
# 功能 2: 回档
# ============================================
rollback_to_remote() {
    print_banner
    echo -e "${BLUE}--- 回档 - 用远程版本覆盖本地 ---${NC}"
    echo ""
    print_warn "警告：此操作将丢弃所有本地未提交的修改！"
    echo ""

    git remote -v | grep -q origin || { print_error "未设置远程仓库"; press_any_key; return; }

    echo -n "确认要回档？(y/n): "
    read -r confirm
    [ "$confirm" != "y" ] && { print_warn "已取消"; press_any_key; return; }

    echo ""
    echo -e "${RED}最终确认：用远程版本完全覆盖本地？(yes/no):${NC}"
    read -r final_confirm
    [ "$final_confirm" != "yes" ] && { print_warn "已取消"; press_any_key; return; }

    print_info "正在获取远程最新版本..."
    git fetch origin || { print_error "连接远程失败"; press_any_key; return; }

    print_info "正在重置到 $MAIN_BRANCH ..."
    git reset --hard "origin/$MAIN_BRANCH" && {
        print_status "回档成功！"
        echo ""; echo -e "${GREEN}当前版本:${NC}"; git log --oneline -3
    } || print_error "回档失败"

    press_any_key
}

# ============================================
# 功能 3: 下载仓库
# ============================================
clone_repo() {
    print_banner
    echo -e "${BLUE}--- 下载远程仓库 ---${NC}"
    echo ""
    echo -n "远程仓库地址: "
    read -r clone_url
    [ -z "$clone_url" ] && { print_warn "已取消"; press_any_key; return; }

    echo -n "保存目录名 (回车使用默认名): "
    read -r dir_name

    if [ -n "$dir_name" ]; then
        git clone "$clone_url" "$dir_name"
    else
        git clone "$clone_url"
    fi

    [ $? -eq 0 ] && print_status "克隆成功！" || print_error "克隆失败"
    press_any_key
}

# ============================================
# 功能 4: 查看状态
# ============================================
show_status() {
    print_banner
    echo -e "${BLUE}--- 仓库状态 ---${NC}"
    echo ""
    echo -e "${YELLOW}仓库:${NC} $REPO_NAME"
    echo -e "${YELLOW}分支:${NC} $CURRENT_BRANCH"
    echo -e "${YELLOW}远程:${NC} $REMOTE_URL"
    echo ""; echo -e "${YELLOW}当前状态:${NC}"; git status
    echo ""; echo -e "${YELLOW}远程信息:${NC}"; git remote -v
    press_any_key
}

# ============================================
# 功能 5: 提交历史
# ============================================
show_history() {
    print_banner
    echo -e "${BLUE}--- 提交历史 ---${NC}"
    echo ""
    echo -e "${YELLOW}最近提交:${NC}"
    git log --oneline --graph --all -20
    echo ""; echo -e "${YELLOW}版本标签:${NC}"; git tag -l

    echo ""
    echo -n "查看详细？(输入数字 N 查看最近 N 条, 回车跳过): "
    read -r n
    if [ -n "$n" ] && [ "$n" -eq "$n" ] 2>/dev/null; then
        git log --oneline --graph --all -"$n"
        echo ""
        echo -n "查看某次提交详情？(输入 commit hash, 回车跳过): "
        read -r hash
        [ -n "$hash" ] && git show --stat "$hash"
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
        echo -e "${YELLOW}现有标签:${NC}"; git tag -l
        echo ""
        echo "1) 创建新标签"
        echo "2) 推送标签到远程"
        echo "3) 删除标签"
        echo "4) 返回主菜单"
        echo ""
        echo -n "请选择 [1-4]: "
        read -r tag_choice

        case $tag_choice in
            1)
                echo -n "标签名称 (例如 v1.0): "
                read -r tag_name
                echo -n "标签说明: "
                read -r tag_msg
                if [ -n "$tag_name" ]; then
                    git tag -a "$tag_name" -m "$tag_msg"
                    print_status "本地标签 $tag_name 已创建"
                    echo ""
                    echo -n "推送到远程？(y/n): "
                    read -r push_tag
                    [ "$push_tag" = "y" ] && git push origin "$tag_name" && print_status "已推送"
                fi
                press_any_key ;;
            2)
                echo "1) 推送单个   2) 推送全部"
                echo -n "请选择 [1-2]: "
                read -r pc
                case $pc in
                    1) echo -n "标签名: "; read -r t; git push origin "$t" ;;
                    2) git push --tags ;;
                esac
                print_status "完成"; press_any_key ;;
            3)
                echo -n "要删除的标签名: "
                read -r dname
                if [ -n "$dname" ]; then
                    git tag -d "$dname"
                    echo -n "同时删除远程标签？(y/n): "
                    read -r dr
                    [ "$dr" = "y" ] && git push origin --delete "$dname"
                    print_status "已删除"
                fi
                press_any_key ;;
            *) return ;;
        esac
    done
}

# ============================================
# 功能 7: 撤销修改
# ============================================
discard_changes() {
    print_banner
    echo -e "${BLUE}--- 撤销本地修改 ---${NC}"
    echo ""
    echo -e "${YELLOW}已修改的文件:${NC}"; git status -s
    echo ""
    echo "1) 撤销所有未提交的修改"
    echo "2) 撤销单个文件的修改"
    echo "3) 删除所有未跟踪文件"
    echo ""
    echo -n "请选择 [1-3] (回车取消): "
    read -r choice
    case $choice in
        1) echo -n "确认？(yes/no): "; read -r c; [ "$c" = "yes" ] && git restore . && print_status "已恢复" ;;
        2) echo -n "文件路径: "; read -r f; [ -n "$f" ] && git restore "$f" && print_status "$f 已恢复" ;;
        3) echo -n "确认？(yes/no): "; read -r c; [ "$c" = "yes" ] && git clean -fd && print_status "已清理" ;;
    esac
    press_any_key
}

# ============================================
# 功能 8: 配置检查
# ============================================
check_config() {
    print_banner
    echo -e "${BLUE}--- Git 配置检查 ---${NC}"
    echo ""
    echo -e "${YELLOW}用户信息:${NC}"
    git config --global user.name  >/dev/null 2>&1 && echo "  Name: $(git config --global user.name)"  || print_warn "用户名未设置"
    git config --global user.email >/dev/null 2>&1 && echo "  Email: $(git config --global user.email)" || print_warn "邮箱未设置"
    echo ""
    echo -e "${YELLOW}项目信息:${NC}"
    echo "  仓库: $REPO_NAME"
    echo "  远程: $REMOTE_URL"
    echo "  分支: $CURRENT_BRANCH"
    echo ""
    echo -e "${YELLOW}SSH 测试:${NC}"
    ssh -T git@github.com 2>&1
    press_any_key
}

# ============================================
# 功能 9: 导入外部文件
# ============================================
import_file() {
    print_banner
    echo -e "${BLUE}--- 导入外部文件到仓库 ---${NC}"
    echo ""
    echo -e "${YELLOW}源文件路径 (例如:${NC}"
    echo "  Windows: C:/Users/.../文件.txt"
    echo "  Git Bash: /c/Users/.../文件.txt"
    echo -e "${YELLOW}):${NC}"
    read -r src_path

    src_path=$(eval echo "$src_path")
    [ ! -f "$src_path" ] && { print_error "文件不存在"; press_any_key; return; }

    local filename=$(basename "$src_path")
    local filesize=$(du -h "$src_path" 2>/dev/null | cut -f1)
    print_status "找到文件: $filename ($filesize)"
    echo ""
    echo -e "${YELLOW}保存到仓库中的路径${NC}"
    echo -n "(直接回车放根目录，或输入子目录如 docs/文件.txt): "
    read -r dest_path
    [ -z "$dest_path" ] && dest_path="$filename"

    local full_dest="$REPO_DIR/$dest_path"
    if [ -f "$full_dest" ]; then
        print_warn "仓库中已存在: $dest_path"
        echo -n "覆盖？(y/n): "
        read -r overwrite
        [ "$overwrite" != "y" ] && { print_warn "已取消"; press_any_key; return; }
    fi

    mkdir -p "$(dirname "$full_dest")"
    cp "$src_path" "$full_dest" || { print_error "复制失败"; press_any_key; return; }
    print_status "已复制到: $dest_path"

    echo ""
    echo -n "版本说明 (例如 添加 $filename): "
    read -r commit_msg
    [ -z "$commit_msg" ] && commit_msg="添加文件: $filename"

    echo ""; echo -e "${YELLOW}将执行:${NC}"
    echo "  git add \"$dest_path\""
    echo "  git commit -m \"$commit_msg\""
    git remote -v | grep -q origin && echo "  git push"
    echo ""
    echo -n "确认？(y/n): "
    read -r confirm
    [ "$confirm" != "y" ] && { print_warn "已取消 (文件已在仓库中)"; press_any_key; return; }

    git add "$dest_path"
    git commit -m "$commit_msg"
    local commit_ok=$?
    [ $commit_ok -ne 0 ] && { print_warn "提交跳过"; press_any_key; return; }

    if git remote -v | grep -q origin; then
        print_info "正在同步远程..."
        git pull origin "$MAIN_BRANCH" --rebase --autostash
        git push origin "$MAIN_BRANCH" && print_status "已提交并推送！" || print_error "推送失败"
    else
        print_status "本地提交成功"
    fi
    press_any_key
}

# ============================================
# 主菜单
# ============================================
show_menu() {
    print_banner
    echo -e "${GREEN}仓库:${NC} $REPO_NAME"
    echo -e "${GREEN}分支:${NC} $CURRENT_BRANCH"
    echo -e "${GREEN}远程:${NC} $REMOTE_URL"
    echo -e "${GREEN}状态:${NC} $(git status -s 2>/dev/null | wc -l) 个文件待提交"
    echo ""
    echo -e "${YELLOW}================== 操作菜单 ==================${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC}) ${BLUE}上传新版本${NC}       add → commit → pull → push (+ 打标签)"
    echo -e "  ${GREEN}2${NC}) ${BLUE}回档${NC}             远程版本覆盖本地"
    echo -e "  ${GREEN}3${NC}) ${BLUE}下载仓库${NC}         全新克隆远程仓库"
    echo ""
    echo -e "  ${GREEN}4${NC}) ${BLUE}查看状态${NC}         分支 / 修改 / 远程信息"
    echo -e "  ${GREEN}5${NC}) ${BLUE}提交历史${NC}         版本历史 + 标签"
    echo -e "  ${GREEN}6${NC}) ${BLUE}标签管理${NC}         创建 / 推送 / 删除"
    echo -e "  ${GREEN}7${NC}) ${BLUE}撤销修改${NC}         丢弃本地未提交更改"
    echo -e "  ${GREEN}8${NC}) ${BLUE}配置检查${NC}         Git 身份 / SSH"
    echo -e "  ${GREEN}9${NC}) ${BLUE}导入文件${NC}         从电脑任意位置导入文件"
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
    detect_repo "$1" || {
        echo "按回车键退出..."; read -r; exit 1
    }

    cd "$REPO_DIR" || exit 1

    while true; do
        REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "未设置")
        CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
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
            0) echo ""; print_status "再见！"; exit 0 ;;
            *) print_warn "无效选择，请输入 0-9"; sleep 1 ;;
        esac
    done
}

main "$1"
