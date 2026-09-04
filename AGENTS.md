# Recall Card - Codex Project Instructions

このファイルは、Recall Card の実装を Codex に依頼するときの常設ルールです。

目的は、Codex が既存仕様・現在のコード・Issue の境界を守りながら、
「調査 → 設計確認 → 実装 → テスト → 差分確認」まで一貫して進められるようにすることです。

---

# 1. Project / Reference Paths

## 1.1 Working Repository

この `AGENTS.md` が置かれている Git リポジトリを実装対象とします。

- Repository root: この `AGENTS.md` のある Git root
- コード変更、テスト、Git 差分確認は原則このリポジトリ内で行う
- リポジトリ外のファイルを勝手にコピー・移動・変更しない

作業開始時に必ず以下を確認してください。

```bash
pwd
git rev-parse --show-toplevel
git branch --show-current
git status
```

---

## 1.2 External Reference Documents

以下は Recall Card の仕様・設計・実装方針を保存している外部参照フォルダです。

必要に応じて、実際の環境に合わせてパスを書き換えてください。

```text
REFERENCE_ROOT_1=/mnt/c/Users/<USER_NAME>/<PATH_TO_RECALL_CARD_DOCS>
REFERENCE_ROOT_2=/mnt/c/Users/<USER_NAME>/<OPTIONAL_SECOND_REFERENCE_DIR>
```

例：

```text
REFERENCE_ROOT_1=/mnt/c/Users/example/Documents/RecallCard
```

### 参照ルール

- 外部参照フォルダは原則 **読み取り専用** として扱う
- 明示的な指示がない限り、外部資料を変更・削除・移動しない
- 実装前に、Issue に関係する資料を確認する
- WSL から Windows 側を参照するときは `/mnt/c/...` の絶対パスを使用する
- 外部資料へアクセスできない場合は、アクセスできたふりをせず、対象パスとエラー内容を報告する
- 外部資料をリポジトリ内へ勝手に複製しない

### 優先的に確認する資料

外部参照フォルダ内に存在する場合、Issue に応じて以下を確認してください。

```text
Recall_Card_本リリース_実装方針_推奨実装順*.md
README.md
Recall_Card_Project_Handoff*.md
Recall_Card_Issue*_Development_Guide*
recall_card_er_diagram_guide.md
recall_card_figma_screen_transition_guide.md
その他 Issue 固有の設計資料
```

すべてを毎回読む必要はありません。
現在の Issue に関係する資料だけを優先してください。

---

# 2. Source of Truth

仕様判断では、次の優先順位を基本とします。

1. **ユーザーが今回明示した Issue / 要件**
2. **現在のリポジトリの実コード・設定・schema・Spec**
3. **本リリース実装方針・Issue 固有資料**
4. **README / ER 図 / 画面遷移図 / 過去の開発ガイド**
5. 一般的な Rails の慣習

重要：

- 過去資料は作成時点の状態を含むため、現在コードと一致するとは限らない
- 資料と実コードが食い違う場合、勝手にどちらかへ寄せない
- 差分を確認し、現在コードを基準に影響範囲を整理する
- 仕様そのものが矛盾している場合は、その矛盾を明示する
- 「資料に書いてあるから」という理由だけで、既存実装を上書きしない

---

# 3. Current Technical Direction

Recall Card は既存の Rails 構成を維持して開発します。

主な構成：

```text
Ruby on Rails
PostgreSQL
Docker Compose
Devise
Hotwire / Turbo / Stimulus
importmap
Bootstrap
RSpec
FactoryBot
Capybara
SimpleCov
Bullet
GitHub Actions
Render
```

## 技術方針

- Ruby / Rails / PostgreSQL / Gem のバージョンは **現在のリポジトリを正** とする
- Codex の判断だけで最新版へ更新しない
- 既存の importmap / Turbo / Stimulus 構成を維持する
- Node.js / npm / Yarn / React / TypeScript を勝手に導入しない
- 新しい JavaScript ライブラリを安易に追加しない
- 新しい Gem は、Issue の実現に必要な場合のみ検討する
- Gem 追加前に、Ruby / Rails 標準機能や既存 Gem で解決できないか確認する
- AI API など、Issue にない外部サービス連携を先行実装しない

---

# 4. Git Workflow

基本ブランチ構成：

```text
main
└─ 本番 / Render デプロイ対象

develop
└─ 開発統合ブランチ

feature/<Issue番号>-<機能名>
└─ Issue 単位の実装

fix/<Issue番号>-<内容>
└─ 不具合修正

hotfix/<内容>
└─ 本番緊急修正時のみ
```

基本フロー：

```text
develop
↓
feature/<Issue番号>-<機能名>
↓
Pull Request
↓
develop
↓
リリース時に develop → main
```

## Git の原則

- `main` へ直接 push しない
- 原則 `develop` へ直接実装しない
- **1 Issue = 1 branch = 1 PR** を維持する
- Issue 範囲外の変更を同じ PR に混ぜない
- 作業開始前に現在ブランチと未コミット差分を確認する
- 未コミット変更が存在する状態で、勝手に checkout / reset / stash しない
- 既存ユーザー変更を消さない

## Git 操作の制限

ユーザーから明示されていない限り、以下を勝手に行わない。

```text
git commit
git push
git merge
git rebase
git reset
git clean
git stash
git branch -D
```

ブランチ作成・切替も、既存の作業状態を確認してから行うこと。

ユーザーが「Issue の実装を最初から進めて」と依頼し、
現在 `develop` が clean であることを確認できた場合のみ、
必要に応じて次の流れを提案・実行する。

```bash
git switch develop
git pull origin develop
git status
git switch -c feature/<issue-number>-<short-name>
```

すでに正しい feature ブランチにいる場合は作り直さない。

---

# 5. Issue Implementation Workflow

各 Issue は、原則として以下の順で進めます。

---

## Step 1. Issue の目的を確定する

最初に以下を整理する。

- この Issue で何を実現するのか
- 完成するとユーザーが何をできるようになるのか
- この Issue で変更してよい範囲
- この Issue では変更しない範囲
- 前提となる既存機能
- 関連する外部資料

Issue の目的を超えた「ついで実装」はしない。

---

## Step 2. 作業状態を確認する

最低限：

```bash
pwd
git rev-parse --show-toplevel
git branch --show-current
git status
git diff
```

必要に応じて：

```bash
git log --oneline --decorate -5
git remote -v
```

確認前にファイル変更を始めない。

---

## Step 3. 関連資料を確認する

外部参照フォルダから、現在の Issue に関連する資料を読む。

確認した内容は、実装計画へ反映する。

特に以下を区別する。

```text
現在も有効な確定仕様
過去時点の実装例
将来案
本リリースでの候補
明示的に後回しにされた機能
```

過去資料にあるコード例を、そのまま現在コードへ貼り付けない。

---

## Step 4. 現在のコードを調査する

Issue に応じて、必要な範囲だけ確認する。

```text
routes
Model
Controller
Service
View
Partial
Stimulus Controller
CSS
migration
schema.rb
Spec
Factory
Gemfile
Gemfile.lock
Dockerfile
compose.yaml
initializer
```

重要：

- ファイル名やクラス名を推測しない
- 「存在するはず」で進めない
- まず検索して実物を確認する
- 既存 helper / partial / service / scope があれば再利用を検討する
- 既存テストから現在仕様を読み取る

---

## Step 5. 実装計画を作る

コード変更前に、少なくとも以下を整理する。

```text
変更対象ファイル
追加対象ファイル
DB変更の有無
既存機能への影響
追加・更新するテスト
手動確認項目
```

大きな Issue の場合も、Issue の中で責務を分けて小さく変更する。

不要な大規模リファクタリングを同時に行わない。

---

# 6. Database Changes

DB変更がない Issue では、migration を作らない。

DB変更が必要な場合は、必ず以下の順で進める。

```text
設計確認
↓
migration 生成
↓
migration ファイルを読む
↓
制約確認
↓
migrate
↓
schema.rb の差分確認
↓
Model / Spec
```

migration 実行前に確認する項目：

```text
foreign key
null
default
index
unique index
dependent の整合性
既存データへの影響
rollback 可能性
```

Docker 環境では原則：

```bash
docker compose exec web bin/rails db:migrate
docker compose exec web bin/rails db:migrate:status
git diff db/schema.rb
```

## 禁止

明示的な指示なしに以下を実行しない。

```bash
docker compose down -v
bin/rails db:drop
bin/rails db:reset
bin/rails db:schema:load
bin/rails db:setup
```

データ消失につながる操作は必ず避ける。

---

# 7. Rails / Docker Command Policy

Rails / Bundler 関連コマンドは、原則 Docker Compose 内で実行する。

例：

```bash
docker compose up -d
docker compose ps

docker compose exec web bin/rails routes
docker compose exec web bin/rails console
docker compose exec web bin/rails db:migrate
docker compose exec web bin/rails db:migrate:status

docker compose exec web bundle exec rspec
docker compose exec web bundle exec rubocop
```

ホスト側 Ruby 環境と Docker 内 Ruby 環境を混同しない。

## Docker build

コード変更だけなら、通常は build し直さない。

次の場合は現在の Docker 構成を確認して判断する。

```text
Gemfile / Gemfile.lock
Dockerfile
compose.yaml
OS package
runtime dependency
```

Gem を変更しただけで機械的に `docker compose build` せず、
現在の volume / bundle 管理方法を確認する。

---

# 8. Implementation Rules

## 8.1 Scope

- Issue 範囲外の機能を先行実装しない
- 将来 Issue のカラムやモデルを先回りして作らない
- 「便利だから」という理由だけで機能追加しない
- 同じ Issue に無関係な UI 改修やリファクタリングを混ぜない
- 必要最小限の変更で既存コードへ統合する

---

## 8.2 Existing Architecture

既存の責務分離を尊重する。

例：

```text
Model       : 永続データ・validation・association・domain logic
Controller  : HTTP request / response と処理の調整
Service     : Controller/Model に置くと責務が重くなる処理
View        : 表示
Stimulus    : ブラウザ上の小さな UI 動作
Spec        : 期待する振る舞い
```

既存 Service Object がある処理を Controller へ重複実装しない。

---

## 8.3 Authentication / Authorization

ユーザー所有データでは、現在の認可方式を維持する。

特に Card / Tag / ユーザー所有 PromptTemplate 等で、

```ruby
Model.all
Model.find(params[:id])
```

を安易に使わず、既存の `current_user` スコープを確認する。

他ユーザーのデータを、

- 表示
- 更新
- 削除
- autocomplete 候補
- JSON response

へ混入させない。

---

## 8.4 HTML / Markdown / Security

ユーザー入力や AI 貼り付け内容は信頼しない。

- `html_safe` を安易に使用しない
- Markdown → HTML 変換時は XSS 対策を確認する
- raw_content をデバッグ目的で不用意に公開しない
- HTML を保存する必要がない場合は DB へ元テキストを保持する
- 表示時変換と永続データを分離する

---

# 9. Testing Strategy

変更後は、いきなり全テストだけを実行するのではなく、
まず変更箇所に近いテストを実行する。

例：

```bash
docker compose exec web bundle exec rspec spec/requests/cards_spec.rb
docker compose exec web bundle exec rspec spec/models/card_spec.rb
docker compose exec web bundle exec rspec spec/services/card_parser_spec.rb
```

その後、PR 前に可能な限り全体確認：

```bash
docker compose exec web bundle exec rspec
docker compose exec web bundle exec rubocop
```

## テスト種別

Issue に応じて使い分ける。

```text
Model Spec
Request Spec
System Spec
Service Spec
```

### テストで確認する観点

必要に応じて：

```text
正常系
validation / 異常系
未ログイン
他ユーザー
DBへ保存される / されない
検索・絞り込み
画面遷移
既存フローの回帰
```

Spec を通すためだけに本来の仕様を弱めない。

既存 Spec と新仕様が衝突した場合は、
「Spec が古い」のか「実装が誤っている」のかを判断してから変更する。

---

# 10. Manual Verification

ブラウザ確認が必要な Issue では、最低限以下を意識する。

```text
正常系
主要な失敗ケース
PC
スマートフォン
未ログイン
他ユーザー
主要な画面遷移
Turbo / Stimulus の動作
ブラウザ Console
```

Codex 自身がブラウザ確認できない環境では、

- 確認したと断言しない
- ユーザー向けの具体的な手動確認手順を出す
- 自動テストで確認できた範囲と、手動確認が残る範囲を分ける

---

# 11. Regression Check

Issue の対象機能だけでなく、変更の影響を受ける既存コアフローを確認する。

Recall Card の主要フロー：

```text
ログイン
↓
テンプレート選択
↓
テンプレートコピー
↓
外部AI
↓
AI出力貼り付け
↓
プレビュー・編集
↓
カード保存
↓
カード詳細
↓
検索 / タグ / 復習
```

変更内容に応じて必要な範囲だけ回帰確認する。

---

# 12. Quality Check Before Completion

作業完了前に最低限：

```bash
git status
git diff
```

必要に応じて：

```bash
git diff --cached
docker compose exec web bundle exec rspec
docker compose exec web bundle exec rubocop
docker compose exec web bin/rails routes
docker compose exec web bin/rails db:migrate:status
```

確認すること：

```text
Issue 範囲外の変更がない
不要ファイルがない
schema.rb の差分が意図どおり
Gemfile.lock の差分が意図どおり
秘密情報がない
デバッグコードが残っていない
不要な console.log / puts がない
既存テストを無理に削除していない
```

---

# 13. Secrets / Security

次の情報を表示・コミット・資料へ書き込まない。

```text
.env の実値
RAILS_MASTER_KEY
config/master.key
DATABASE_URL
DB password
Render Deploy Hook
OAuth Client Secret
API Key
SSH private key
個人アクセストークン
```

秘密情報を確認する必要がある場合も、値そのものではなく、

```text
環境変数が存在するか
設定キー名が正しいか
読み込みコードが正しいか
```

を確認する。

---

# 14. Final Report Format

実装作業を完了したら、結果を以下の順で簡潔に報告する。

## 1. 実施内容

- 何を変更したか
- Issue の目的をどう満たしたか

## 2. 変更ファイル

```text
path/to/file
path/to/another_file
```

各ファイルの役割も短く説明する。

## 3. 重要な設計判断

- なぜその実装にしたか
- 既存構成をどう再利用したか
- 採用しなかった案が重要なら、その理由

## 4. テスト結果

実行したコマンドと結果を分けて記載する。

```text
PASS
FAIL
未実行
```

を曖昧にしない。

## 5. 手動確認

- Codex 側で確認できたもの
- ユーザー側でブラウザ確認が必要なもの

を分ける。

## 6. 残課題

Issue 外として残したものがあれば明示する。

---

# 15. Explanation Policy

このプロジェクトでは、コードが動くだけでなく、
ユーザー自身が変更内容を説明・再現・応用できることを重視する。

重要な変更では以下を説明する。

```text
何が起きているか
なぜこの実装が必要か
このコードが何をしているか
データがどのように流れるか
別の場面でどう応用できるか
```

ただし、実装を止めて長い講義だけを始めない。

まず正しい実装・検証を行い、その後に重要点を整理する。

---

# 16. Actions That Require Extra Caution

以下は特に慎重に扱う。

```text
DB破壊
migration の書き換え
認証方式変更
認可変更
User 削除
dependent 設定
Gem の大規模更新
Rails / Ruby バージョン更新
JavaScript build system 変更
Render 本番設定
Git history 書き換え
秘密情報
```

Issue に必要な場合でも、影響範囲を確認してから変更する。

---

# 17. Core Principle

Recall Card の開発では、機能数を増やすことよりも、

> AIで解決した内容を、簡単に残し、後から再利用できる

という中心価値を壊さず改善することを優先する。

実装判断では常に、

```text
既存コア体験を壊さない
↓
Issue の目的を最小変更で満たす
↓
テスト可能にする
↓
ユーザーが説明できる状態にする
```

の順で考える。
