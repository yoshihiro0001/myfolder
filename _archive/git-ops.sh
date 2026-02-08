#!/bin/bash

# Git操作ルーティン集
# 使い方: ./git-ops.sh [コマンド名]

set -e

# カラー出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# コマンド一覧
show_help() {
    echo "Git操作ルーティン集"
    echo ""
    echo "使い方: ./git-ops.sh [コマンド名]"
    echo ""
    echo "利用可能なコマンド:"
    echo "  push          📂→☁️ 今のローカル変更を通常プッシュ"
    echo "  pull-overwrite  ☁️→📂 リモートmainの最新でローカルを完全に揃える"
    echo "  backup-tag   今の状態を保存（バックアップタグ）"
    echo "  restore      保存/指定点に戻す（タグ or コミット）"
    echo "  keep         今の状態を保存（git keep）"
    echo "  rollback     保存に戻す（git rollback）"
    echo ""
}

# 📂→☁️プッシュ: 今のローカル変更を通常プッシュ
push_changes() {
    echo -e "${GREEN}📂→☁️ ローカル変更をプッシュ中...${NC}"
    git add -A
    git commit -m "update: $(date +%m/%d-%H:%M)" || {
        echo -e "${YELLOW}変更がないか、コミット済みです${NC}"
        exit 0
    }
    git pull --rebase origin main || {
        echo -e "${YELLOW}リモートとの競合がある可能性があります${NC}"
        exit 1
    }
    git push origin main
    echo -e "${GREEN}✅ プッシュ完了${NC}"
}

# ☁️→📂上書き: リモートmainの最新でローカルを完全に揃える
pull_overwrite() {
    echo -e "${YELLOW}⚠️  警告: ローカルの未コミット変更は失われます${NC}"
    read -p "続行しますか？ (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "キャンセルしました"
        exit 0
    fi
    
    echo -e "${GREEN}☁️→📂 リモートの最新でローカルを上書き中...${NC}"
    git fetch origin
    git checkout main
    git reset --hard origin/main
    echo -e "${GREEN}✅ 上書き完了${NC}"
}

# 今の状態を保存（バックアップタグ）
backup_tag() {
    TAG="backup-$(date +%Y%m%d-%H%M%S)"
    echo -e "${GREEN}📸 バックアップタグを作成中: $TAG${NC}"
    git tag -a "$TAG" -m "snapshot $TAG"
    git push origin "$TAG"
    echo -e "${GREEN}✅ 保存完了: $TAG${NC}"
}

# 保存/指定点に戻す（タグ or コミット）
restore() {
    if [ -z "$1" ]; then
        echo -e "${RED}エラー: タグまたはコミットハッシュを指定してください${NC}"
        echo "使い方: ./git-ops.sh restore <TAG_OR_COMMIT>"
        echo ""
        echo "利用可能なタグ:"
        git tag -l "backup-*" | tail -10
        exit 1
    fi
    
    TARGET=$1
    echo -e "${YELLOW}⚠️  警告: mainブランチを $TARGET に戻します（force push）${NC}"
    read -p "続行しますか？ (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "キャンセルしました"
        exit 0
    fi
    
    echo -e "${GREEN}🔄 $TARGET に戻し中...${NC}"
    git fetch origin --tags
    git checkout main
    git reset --hard "$TARGET"
    git push --force-with-lease origin main
    echo -e "${GREEN}✅ 復元完了: $TARGET${NC}"
}

# 今の状態を保存（git keep）
keep() {
    if [ -z "$1" ]; then
        NAME="backup-$(date +%Y%m%d-%H%M%S)"
    else
        NAME=$1
    fi
    
    COMMIT=$(git rev-parse HEAD)
    echo -e "${GREEN}💾 状態を保存中: $NAME ($COMMIT)${NC}"
    
    # .git-keepディレクトリに保存情報を記録
    mkdir -p .git-keep
    echo "$COMMIT" > ".git-keep/$NAME"
    echo "$(date +%Y-%m-%d\ %H:%M:%S)" >> ".git-keep/$NAME"
    git log -1 --pretty=format:"%s" >> ".git-keep/$NAME"
    echo "" >> ".git-keep/$NAME"
    
    # タグも作成
    git tag -a "keep-$NAME" -m "keep snapshot: $NAME" "$COMMIT" 2>/dev/null || true
    
    echo -e "${GREEN}✅ 保存完了: $NAME${NC}"
    echo "  コミット: $COMMIT"
}

# 保存に戻す（git rollback）
rollback() {
    if [ ! -d ".git-keep" ]; then
        echo -e "${RED}エラー: .git-keepディレクトリが見つかりません${NC}"
        exit 1
    fi
    
    # 最新のkeepファイルを取得
    LATEST_KEEP=$(ls -t .git-keep/ | head -1)
    if [ -z "$LATEST_KEEP" ]; then
        echo -e "${RED}エラー: 保存された状態が見つかりません${NC}"
        exit 1
    fi
    
    COMMIT=$(head -1 ".git-keep/$LATEST_KEEP")
    echo -e "${GREEN}🔄 最新の保存状態に戻します: $LATEST_KEEP${NC}"
    echo "  コミット: $COMMIT"
    
    read -p "続行しますか？ (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "キャンセルしました"
        exit 0
    fi
    
    git checkout "$COMMIT"
    echo -e "${GREEN}✅ 復元完了${NC}"
    echo "現在のブランチは detached HEAD 状態です"
    echo "新しいブランチを作成するか、mainブランチにマージしてください"
}

# メイン処理
case "$1" in
    push)
        push_changes
        ;;
    pull-overwrite)
        pull_overwrite
        ;;
    backup-tag)
        backup_tag
        ;;
    restore)
        restore "$2"
        ;;
    keep)
        keep "$2"
        ;;
    rollback)
        rollback
        ;;
    help|--help|-h|"")
        show_help
        ;;
    *)
        echo -e "${RED}エラー: 不明なコマンド: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac

