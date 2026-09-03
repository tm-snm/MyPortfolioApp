# Recall Card Project Instructions

## このファイルの目的と適用範囲

- このファイルは Recall Card リポジトリ固有の開発ルールを定める。
- 作業対象は `/home/kusur/projects/recall_card` 配下に限定する。
- グローバルの `AGENTS.md` を継承し、このファイルではプロジェクト固有のルールを補足する。
- このファイルと上位の指示が矛盾する場合は、優先度の高い指示に従う。

## リポジトリとGitHub Project

- GitHubリポジトリ：`tm-snm/MyPortfolioApp`
- GitHub Project：[Recall Card Project](https://github.com/users/tm-snm/projects/3)
- GitHub上の確認や操作には、原則としてブラウザではなくGitHub CLI（`gh`）を使用する。
- `gh`を使用する前に、作業ディレクトリ、現在のブランチ、remote、`git status`、`gh auth status --hostname github.com`を確認する。
- GitHub ProjectのStatusは参照のみとし、Codexは変更しない。

## Issue単位の作業

- 原則として `1 Issue = 1ブランチ = 1PR` とする。
- 実装を始める前に、対象Issueの番号を確定する。
- ユーザーからIssue番号が明示されていない場合、CodexがIssueを勝手に選ばず、ユーザーへ確認する。
- 着手前にIssue本文の「目的・背景」「実装内容」「完了条件」「対象外」「依存Issue」を確認する。
- Issueに直接関係する最小限の作業だけを行う。
- Issueに関係しないリファクタリング、先行実装、ついで修正、別機能の追加は行わない。
- Issueを越える変更が必要だと分かった場合は、変更前に理由と影響範囲を説明し、ユーザーへ確認する。

## 情報源の優先順位

実装方針を判断するときは、次の順に優先する。

1. ユーザーからの最新の明示指示
2. GitHub上の対象Issue本文
3. 現在のコード、テスト、設定、DBスキーマ
4. `Recall_Card_本リリース_実装方針_推奨実装順.md`
5. READMEなどの補助資料

実装方針ファイルは次の場所にある。

- WSL：`/mnt/c/Users/kusur/RUNTEQ/卒業課題/Recall_Card_本リリース_実装方針_推奨実装順.md`
- Windows：`C:\Users\kusur\RUNTEQ\卒業課題\Recall_Card_本リリース_実装方針_推奨実装順.md`

- Issueと実装方針ファイルが矛盾する場合は、GitHub上のIssueを優先する。
- 現在のコードと資料に差異がある場合は、推測で修正せず、実際の挙動とIssueの完了条件を基準に判断する。
- 要件や期待結果が曖昧で、実装結果が大きく変わる場合はユーザーへ確認する。

## 着手前のGit確認

1. `/home/kusur/projects/recall_card` がGitルートであることを確認する。
2. `git remote -v`で`origin`が対象リポジトリを指していることを確認する。
3. `git branch --show-current`と`git status --short --branch`を確認する。
4. 未コミット変更や未追跡ファイルがある場合は、破棄、上書き、stashを行わず作業を止めて報告する。
5. `git switch develop`で`develop`へ移動する。
6. `git pull --ff-only origin develop`で`develop`を最新化する。
7. pull失敗、競合、想定外の差分があれば、勝手に解消せず作業を止めて報告する。
8. 最新の`develop`から`feature/<Issue番号>-<短い英語名>`形式の作業ブランチを作成する。
9. ブランチ作成後、現在ブランチと作業ツリーが期待どおりか再確認する。

## ブランチ保護

- `main`には干渉しない。
- `main`へのcheckout、commit、push、rebase、merge、PR作成を行わない。
- 作業用ブランチの起点とPRのbaseは`develop`とする。
- `develop`へ直接commitしない。
- force push、履歴改変、無断のrebase、ユーザーの変更の破棄を行わない。
- `develop`から`main`への反映はユーザーが手動で行う。

## 実装方針

- 変更前に既存コード、命名、責務分担、テスト方針を確認し、現在の設計に合わせる。
- Rails 7、Hotwire、Turbo、Stimulus、importmap、Devise、PostgreSQL、RSpecの既存構成を優先する。
- Node.js、React、TypeScript、新しいJavaScriptライブラリ、外部サービスを、Issueの要求またはユーザーの承認なしに追加しない。
- 新しいgemなどの本番依存を追加する前に、必要性、代替案、影響を説明する。
- DB変更、公開仕様変更、認証・認可変更は、実行前に設計と影響範囲を説明する。
- migrationは生成後に内容を確認し、カラム型、NULL、default、外部キー、index、既存データへの影響を検証してから適用する。
- `current_user`によるユーザーデータ分離を維持し、他ユーザーのデータを取得・更新・表示しない。
- APIキー、認証情報、個人情報などの秘密情報を、コード、ログ、テスト出力、commit、PRへ含めない。
- Issue本文の「対象外」に記載された項目は実装しない。

## テストと確認

- GitHub Actionsでは、PRに対して全RSpecとRuboCopが実行される。
- ローカルでは最低限、変更箇所に直接関係するRSpecと、変更したRubyファイルを対象とするRuboCopを実行する。
- 認証、認可、ユーザーデータ分離、DB変更などの高リスク部分では、関連する正常系・異常系テストをローカルでも省略しない。
- UI変更では、対象画面の主要な正常系を手動確認する。Issueで指定されている場合はPC・スマートフォンの両方を確認する。
- 全RSpecや全RuboCopのローカル実行は必須とせず、GitHub Actionsの結果で補完する。ただし、Issueまたはユーザーが要求した場合は実行する。
- ローカルで実行できなかった確認は、理由、代替確認、GitHub Actionsで確認する項目を明記する。
- 完了前に`git status`、`git diff`、変更ファイル一覧を確認し、Issueの各完了条件との対応を見直す。

## commit・push・PR

- ユーザーが対象Issueの実装を明示的に依頼した場合、その依頼には関連テスト後のcommit、push、PR作成までを含む。
- commitとPRには、対象Issueに関係する変更だけを含める。
- commitメッセージとPR本文は、日本語で変更目的が分かるように記載する。
- PRのbaseは必ず`develop`、headは対象Issueの作業ブランチとする。
- 通常はレビュー可能なPRとして作成し、未完了項目や既知の問題がある場合だけDraftにする。
- PR本文には、Issue番号、変更内容、設計判断、確認方法、テスト結果、未確認事項、レビューしてほしい観点を記載する。
- `develop`向けPRではIssueの自動クローズを前提にせず、`Refs #<Issue番号>`で関連付ける。
- PR作成後に、URL、PR番号、Draft状態、base/headブランチを`gh pr view`で確認する。
- GitHub ActionsのRSpecとRuboCopの結果を確認する。
- CI失敗がIssue範囲内の変更に起因する場合は修正し、再pushして結果を確認する。
- CI失敗がIssue範囲外に起因する場合は、無関係な修正を行わず、原因と状況を報告する。
- CodexはPRをマージしない。

## 作業完了時の報告

作業完了時は、日本語で次の内容を報告する。

- 対応したIssue番号と目的
- 変更したファイル
- 主な変更内容と設計判断
- 実行したテストと結果
- 手動確認の内容と結果
- GitHub Actionsの結果
- 実行できなかった確認と残っている注意点
- PRのURL、番号、base/head、Draft状態
- 今回の変更を理解するためのポイント、または次に確認するとよい箇所
