# 42-init_repos

gh CLI と設定ファイルを使って、**自分の GitHub アカウント（または Organization）** に 42 のプロジェクト用リポジトリを一括作成・初期化するスクリプト。

---

このリポジトリは、**42 の課題用 GitHub リポジトリ**を一括で作成・初期設定するための Bash スクリプトを提供します。

- `OWNER` に指定したユーザー名 or Organization 名の配下に、`REPOS` の一覧に書いた名前でリポジトリを自動作成
- `gh` CLI を使って Description と Topics を自動設定
- ローカルのベースディレクトリに clone（または既存 clone を再利用）
- まだコミットが 1 つもないリポジトリには、`README.md` を作成して初回コミット＆ push

42 の課題リポジトリをまとめて用意したいときに、「1 個ずつブラウザから作るのが面倒くさい」を解決するためのツールです。

---

## 特長

- **ユーザー / Organization 単位でまとめて作成**

  `OWNER` で指定した GitHub ユーザー名 or Organization 名の配下に、`REPOS` の名前でリポジトリを作成します。
  - 例:
    - `OWNER="your-github-username"` → 自分のアカウント直下に作成
    - `OWNER="42-your-org"` → Organization 配下に作成

- **Description / Topics を自動設定**

  `gh repo edit` を使って、
  - `42 project: ${repo}` という Description
  - `42`, `42tokyo`, `42-${safe_repo}` といった Topics
  を自動で付与します。

- **ローカル clone も自動管理**

  `BASE_DIR/リポジトリ名` に clone します。すでに `.git` がある場合は、そのディレクトリを再利用します。

- **初回 README コミットも自動**

  コミットが 1 つもないリポジトリに対しては、`master` ブランチを作り、`README.md` を作成して初回コミットを push します。

---

## 前提条件

このスクリプトを利用するには、以下のツール・状態が必要です。

- Unix 系環境（Linux / macOS / WSL など）
- `bash`
- `git`
- [GitHub CLI (`gh`)](https://cli.github.com/)
- GitHub アカウント
  - `OWNER` に指定したユーザー / Organization へのリポジトリ作成権限
  - 事前に `gh auth login` 済みであること

---

## ファイル構成（例）

```text
.
├── 42_init_repos.sh           # メインのスクリプト
└── 42_repos_config.sh         # 設定ファイル（OWNER, BASE_DIR, REPOS を定義）
````

`42_init_repos.sh` と **同じディレクトリ** に `42_repos_config.sh` を置く前提になっています。

---

## 設定ファイル：`42_repos_config.sh`

このファイルで、対象の所有者（ユーザー or Organization）、ローカルの clone 先ディレクトリ、作成したいリポジトリ一覧を定義します。

```bash
# GitHub ユーザー名 or Organization 名
OWNER="your-github-username"   # 例: "jikuhar" や "42-kjikuhar"

# ローカルのベースディレクトリ
BASE_DIR="$HOME/42-repos"

# 作成・設定したいリポジトリ名一覧
REPOS=(
  "Libft"
  "get_next_line"
  "ft_printf"
  "pipex"
  "push_swap"
  # "so_long"
  # "FdF"
  # ...
)
```

* `OWNER`

  * GitHub の「所有者名」を指定します。
  * **自分のアカウントに作りたい場合**は、自分の GitHub ユーザー名を書けば OK です。

    * 例: `"your-github-username"`
  * リポジトリをまとめて管理したい場合や、個人アカウントにリポジトリが増えすぎるのが嫌な場合は、専用の Organization を作って、そちらの名前を指定するのがおすすめです。

* `BASE_DIR`

  * ローカルで clone する親ディレクトリです。
  * 実際には `${BASE_DIR}/${repo}` というパスに clone されます。

* `REPOS`

  * 作成・設定したいリポジトリ名の配列です。
  * ここに列挙した名前で `OWNER/リポジトリ名` が作成されます。

---

## 使い方

1. このリポジトリを clone するか、`42_init_repos.sh` と `42_repos_config.sh` をローカルに配置する

2. `42_repos_config.sh` を編集して、`OWNER`, `BASE_DIR`, `REPOS` を自分用に設定する

3. GitHub CLI のログインを確認する

   ```bash
   gh auth status
   ```

4. スクリプトに実行権限を付与する（必要なら）

   ```bash
   chmod +x 42_init_repos.sh
   ```

5. 実行

   ```bash
   ./42_init_repos.sh
   ```

---

## スクリプトの動作の流れ

`REPOS` の各要素（`repo`）に対して、次の処理を行います。

1. **GitHub 上にリポジトリが存在するか確認**

   ```bash
   gh repo view "${OWNER}/${repo}"
   ```

   * すでに存在する場合:
     → 「すでに存在」と表示して次のステップへ。
   * 存在しない場合:
     → `gh repo create` で **public** リポジトリとして作成します。

2. **Description / Topics を設定**

   ```bash
   gh repo edit "${OWNER}/${repo}" \
     --description "42 project: ${repo}" \
     --add-topic 42 \
     --add-topic 42tokyo \
     --add-topic "42-${safe_repo}"
   ```

   * `safe_repo` は、`repo` を小文字化し、`_` を `-` に置き換えた文字列です。
   * 例: `get_next_line` → `42-get-next-line`

3. **ローカルへの clone / 再利用**

   * `${BASE_DIR}/${repo}/.git` が存在する場合:
     → そのディレクトリを再利用して `cd`。
   * 存在しない場合:

     ```bash
     git clone "https://github.com/${OWNER}/${repo}.git" "${BASE_DIR}/${repo}"
     cd "${BASE_DIR}/${repo}"
     ```

4. **初回コミットの有無をチェック**

   ```bash
   git rev-parse --quiet --verify HEAD
   ```

   * コミットがすでにある場合:
     → 「コミットあり」とみなして README の自動生成はスキップし、次のリポジトリへ。
   * コミットが 1 つもない場合:
     → 以下の初期化を行います。

5. **初期化（README + master ブランチ）**

   * `master` ブランチを作成

     ```bash
     git switch -c master 2>/dev/null || git checkout -b master
     ```

   * シンプルな `README.md` を作成

     ```bash
     echo "# ${repo}" > README.md
     git add README.md
     git commit -m "Add initial README"
     ```

   * `origin master` に push

     ```bash
     git push -u origin master
     ```

---

## カスタマイズ例

### 1. Private リポジトリとして作成したい場合

スクリプト内の:

```bash
gh repo create "${full}" --public -y
```

を

```bash
gh repo create "${full}" --private -y
```

に変更してください。

### 2. デフォルトブランチを `main` にしたい場合

`master` を使っている箇所を `main` に変えることで対応できます。

* ブランチ作成部分

  ```bash
  git switch -c main 2>/dev/null || git checkout -b main
  ```

* push 部分

  ```bash
  git push -u origin main
  ```

### 3. Topics を変更したい場合

`gh repo edit` の `--add-topic` 引数を、自分の運用に合わせて変更してください。

---

## 運用のおすすめ

* **まずはシンプルに：自分のアカウント直下に作成**
  `OWNER` に自分の GitHub ユーザー名を指定するだけで、すぐに使い始められます。

* **リポジトリが増えてきたら：専用 Organization を作成**
  42 の課題用リポジトリが増えて、

  * 「自分のアカウント直下がごちゃごちゃしてきた…」
  * 「42 用だけ別の場所にまとめたい」

  という場合は、`42-xxxx` のような専用 Organization を作成し、`OWNER` をその Organization 名に切り替える運用をおすすめします。

---

## よくありそうな質問

### Q. 途中でエラーが出た場合は？

* どのリポジトリまで処理されたかログを確認し、問題のあるリポジトリだけ `REPOS` に残して再実行する、などの運用をおすすめします。
* `set -euo pipefail` を使っているため、**どこかでコマンドが失敗した時点で即終了**する仕様です。

### Q. 既存のリポジトリに対しても使える？

* はい。すでに GitHub 上に存在するリポジトリの場合は、

  * `gh repo view` に成功 → 作成はスキップ
  * `gh repo edit` で Description / Topics の更新のみ行われます。
* ローカル clone がすでにある場合も再利用されます。

---

## ライセンス

このプロジェクトは [MIT License](./LICENSE) のもとで公開されています。
詳しくはリポジトリ直下の `LICENSE` ファイルを参照してください。

---

## 貢献（Contributing）

* Issue / Pull Request は歓迎です。
* バグ報告や機能追加の提案の際は、使用環境（OS、`gh` のバージョンなど）を書いてもらえると助かります。

---

## 作者

* もともと 42 Tokyo 学生向けに作られたスクリプトですが、42 関係者であれば誰でも再利用できるように公開しています。
* Fork して自分のアカウント / Organization 用にカスタマイズして使ってください。

* 作者: jiku0730(intra: kjikuhar) ([GitHub](https://github.com/jiku))
