# Gitセットアップ手順

## 初回セットアップ

以下のコマンドを順番に実行してください：

```bash
cd /Users/kashiharayoshihiro/projects/自分フォルダ

# 1. Gitリポジトリを初期化
git init

# 2. リモートリポジトリを追加
git remote add origin https://github.com/yoshihiro0001/myfolder.git

# 3. ブランチ名をmainに設定
git branch -M main

# 4. 初回コミット
git add -A
git commit -m "Initial commit"

# 5. 初回プッシュ
git push -u origin main
```

## Git操作スクリプトの使い方

`git-ops.sh` スクリプトを使用して、よく使うGit操作を簡単に実行できます。

### 基本的な使い方

```bash
./git-ops.sh [コマンド名]
```

### 利用可能なコマンド

#### 1. 📂→☁️プッシュ
ローカルの変更をコミットしてプッシュします。

```bash
./git-ops.sh push
```

これは以下のコマンドと同等です：
```bash
git add -A && git commit -m "update: $(date +%m/%d-%H:%M)" && git pull --rebase origin main && git push origin main
```

#### 2. ☁️→📂上書き
リモートのmainブランチの最新でローカルを完全に上書きします（未コミットの変更は失われます）。

```bash
./git-ops.sh pull-overwrite
```

#### 3. バックアップタグ作成
現在の状態にバックアップタグを付けます。

```bash
./git-ops.sh backup-tag
```

#### 4. 指定点に戻す
タグまたはコミットハッシュを指定して、その状態に戻します。

```bash
./git-ops.sh restore backup-20240101-120000
# または
./git-ops.sh restore abc1234
```

#### 5. 状態を保存（git keep）
現在の状態を保存します（カスタム名を指定可能）。

```bash
./git-ops.sh keep
# または名前を指定
./git-ops.sh keep my-backup-name
```

#### 6. 保存に戻す（git rollback）
最新の保存状態に戻します。

```bash
./git-ops.sh rollback
```

## ヘルプの表示

```bash
./git-ops.sh help
# または
./git-ops.sh
```

## 注意事項

- `pull-overwrite` と `restore` コマンドは、ローカルの未コミット変更を失う可能性があります。実行前に確認を求められます。
- `restore` コマンドは force push を使用するため、共有リポジトリでは注意が必要です。

