# Rails 8.1更新記録（Issue #127）

## 更新の目的と選定根拠

確認日：2026-10-30。Rails 7.2.3.1から8.1.4へ更新する。
Rails 7.2系は保守終了しており、更新前のBrakeman 8.0.5はEOLRails警告1件を検出した。
公式のリリース一覧とRubyGemsで8.1系の最新パッチ8.1.4を確認した。
8.1.3.1のセキュリティ修正を含む後続版を採用し、実装開始時点の公開情報を基準とした。
将来追加される脆弱性まで安全を保証するものではない。

- [Rails保守方針](https://rubyonrails.org/maintenance)：8.1系のセキュリティ保守期限は2027-10-10。
- [公式リリース一覧](https://www.rubyonrails.org/releases)
- [Rails 8.1.4の配布情報](https://rubygems.org/gems/rails/versions/8.1.4)
- [2026-07-29のセキュリティ更新](https://rubyonrails.org/2026/7/29/Rails-Versions-7-2-3-2-8-0-5-1-and-8-1-3-1-have-been-released)
- [公式アップグレードガイド](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html)

## 互換性と変更範囲

| 項目 | 更新前 | 更新後・判断 |
|---|---|---|
| Ruby | 3.4.10 | 維持。Rails 8.1.4のRuby >= 3.2条件を満たす |
| Rails | 7.2.3.1 | 8.1.4に固定 |
| rails-i18n | 7.0.10 | 8.1.0。旧版のrailties < 8制約を解消 |
| Devise | 5.0.4 | 維持。既存のメール・パスワード認証を検証 |
| PostgreSQL / pg | 17.10 / 1.6.3 | 維持。検索・集計・保存等を既存Specで検証 |
| rspec-rails | 8.0.4 | 維持 |
| その他 | Sprockets / importmap / Turbo / Stimulus / Bootstrap | 構成・バージョンを維持 |

[rails-i18n 8.1.0の依存条件](https://rubygems.org/gems/rails-i18n/versions/8.1.0/dependencies)
はrailties >= 8.0.0, < 9。
Bundlerの保守的な更新で、Rails構成Gemと必要な依存だけを変更した。
追加されたaction_text-trixとuriはRailsの推移的依存（Railsが必要とするGem）。
Action Textのengineやリッチテキスト機能を有効化していない。
不要となったbenchmark、cgiのlockエントリは依存解決により除去された。

- load_defaults 7.2を維持し、Rails 8.0 / 8.1の新しい既定値を一括適用しない。
- ControllerとカードRequest Specの非推奨なunprocessable_entityをunprocessable_contentへ変更。HTTP 422と保存拒否の仕様は同じ。
- current_userによる所有データの分離、Strong Parameters、validation、transaction、Markdownのsanitizeを維持。
- DB構造変更・migration追加・既存migration書き換えはない。schema.rbも維持する。
- Google認証 #96、新認証方式、UI刷新、Propshaft、Solid Queue、npm等の導入は対象外。
- セキュリティ検査のCI追加と横断監査は#128。今回はBrakemanをローカルで実行する。

## 段階的な確認と再現方法

7.2.3.1の基準確認後、8.0.5.1を中間検証に使用し、8.1.4へ進めた。
8.0.5.1は最終成果物・デプロイ対象ではない。
中間版ではto_timeのタイムゾーン保持変更の非推奨警告が出た。
8.1で警告は解消し、日付・復習・日本時間の集計を既存Specで検証する。

以下はWSLのリポジトリルートで実行する。ローカルのDocker環境用であり、本番操作ではない。
既存ComposeはGemをイメージ内に保持し、bundle用volumeは使わないため、
Gemfile.lockの更新後はwebイメージを再ビルドしてそろえる。

```bash
cd /home/kusur/projects/recall_card
docker compose build web
docker compose up -d web
docker compose exec web bundle check
docker compose exec web bin/rails --version
docker compose exec web bin/rails zeitwerk:check
docker compose exec web bin/rails db:migrate:status
```

今回に必要なmigrationはない。DBのreset、drop、schema:load、seedの手動実行は不要。
鍵・credentialsの管理は[Issue #126の手順](security/credentials_rotation.md)を維持する。

## 検証結果

- 更新前Rails 7.2.3.1：対象RSpec 203件、失敗0。
- 更新前Brakeman 8.0.5：解析エラー0、保守終了警告1件。
- 中間Rails 8.0.5.1：対象RSpec 203件、失敗0。
- Rails 8.1.4：対象RSpec 309件、失敗0。
- Docker webイメージの再ビルド・再作成：成功。bundle check成功、Rails 8.1.4を確認。
- 再ビルド後の対象RSpec：309件、失敗0。
- 再ビルド後の全体RSpec：CI=trueでeager loadを有効にして343件、失敗0。
- 全体RSpecのSimpleCov行カバレッジ：98.45%（445 / 452行）。
- RuboCop：96ファイル、指摘0。
- Brakeman 8.0.5：警告0、解析エラー0。exit-on-warn / exit-on-errorを指定して終了コード0。
- zeitwerk:check：成功。既存9件のmigrationはすべてup。migration実行は不要だった。

最終RSpec・静的検査の実行コマンド：

```bash
# 対象RSpec
docker compose exec web bundle exec rspec \
  spec/models spec/requests/authentication_spec.rb spec/requests/cards_spec.rb \
  spec/requests/prompt_templates_spec.rb spec/requests/review_schedules_spec.rb \
  spec/requests/learning_metadata_spec.rb spec/requests/account_deletions_spec.rb \
  spec/helpers spec/services spec/system/major_user_flow_spec.rb \
  spec/system/form_errors_spec.rb spec/security
# 全体RSpec（GitHub Actionsそのものを実行したわけではない）
docker compose exec -e CI=true web bundle exec rspec
docker compose exec web bundle exec rubocop
docker compose exec web bundle exec brakeman --no-pager --quiet --exit-on-warn --exit-on-error
```

既存Specの期待する認可・保存条件は削除・緩和していない。
System Specはすべてrack_testであり、JavaScriptを実行しない。
RSpec成功はTurbo / Stimulusのブラウザ動作確認を代替しない。

## ブラウザ手動確認（ユーザー確認済み）

2026-10-31、ユーザーから手動確認で問題なしとの報告を受けた。
以下は再確認用の手順。Codexによる実ブラウザ操作を実施したという意味ではない。

PCとスマートフォンで、削除してよいテストユーザーA・Bを使用する。

1. 登録、ログイン、ログアウト、誤パスワードの日本語エラー、未ログインの保護ページ遷移。
2. テンプレート選択・お気に入り・コピー・使用履歴、個人テンプレートの作成・編集。
3. AI貼り付け→Turboプレビュー→編集→タグ設定→保存→Markdown詳細→検索。
4. 空の貼り付け、タイトル・本文未入力、不正な復習日で保存されず、入力修正後に操作できること。
5. タグ追加・削除、検索候補、コピー失敗時の案内、送信中のボタン制御、戻る・進む後の再操作。
6. 復習予定・復習記録・理解度・重要度・予定解除、ダッシュボード、Markdownファイル出力。
7. BがAの詳細・編集・出力URLを利用できず、候補・一覧・集計にもAのデータが混入しないこと。
8. 退会は同意・正しい現在パスワードを必要とし、本人と所有データだけが削除されること。
9. Console / Networkに新規エラーやassets失敗がなく、CSRF保護下のフォーム・fetchが動くこと。

通常のtest環境はCSRF保護が無効。手動確認ではdevelopmentまたは本番相当で確認する。
Cookie・パスワード・秘密情報をスクリーンショットやログへ残さない。

## Render反映計画（未実施・別途指示後）

1. 所有者が#126の本番反映・旧秘密情報失効の完了記録を確認する。
   #126はCLOSEDだが、リポジトリ内のcredentials更新手順には本番未確認と記載が残る。
   CLOSEDだけを根拠に本番対応済みと扱わず、必要なら記録を更新する。
2. 実際のRuntime、接続branch、稼働commit、Build / Start Command、Auto-Deployを確認する。
   リポジトリにRender Blueprintはなく、実設定は推測しない。
3. 直前の稼働commit・イメージ、lock、設定の対応関係と、通常運用のDBバックアップ・復旧可否を確認する。
   migrationが不要でも既存ビルド処理がDBへ書き込む可能性を確認する。
4. 現行bin/render-build.shはbundle install、assets:precompile、assets:cleanに加えて
   db:migrateとdb:seedを実行する。seedは共通テンプレートを更新するため、対象commitの内容を確認する。
   今回新しいmigrationはない。これらのコマンドを本資料から無条件に本番実行しない。
5. ユーザーのレビュー・マージ判断と別途のデプロイ指示後、承認したcommitをビルド・反映する。
   Ruby NativeならRuby 3.4.10とlock、Dockerなら更新したイメージでGemを一致させる。
   #126の新鍵と対応credentialsを維持し、値を表示・埋め込みしない。
6. 起動・assets・HTTPS・ログイン・主要フロー・ログを確認し、稼働commitと結果を記録する。
   鍵・secret_key_baseを今回変更する計画はないが、更新前のセッションや開いたフォームも確認する。

## 切り戻し計画（未実施）

- 起動失敗・継続的な5xx・主要操作不能などがあれば、影響を確認し、所有者が切り戻しを判断する。
- 直前の検証済み稼働commitと対応する依存へ戻し、assetsも同じ版で再ビルドする。
  コードを戻すだけでGemfile.lock、イメージ、設定の組合せを混在させない。
- #126の新credentials・新鍵・再混入防止策を維持する。公開済み秘密情報を有効に戻さない。
  #126以前のcommit / イメージへ戻す操作は、通常の切り戻し対象に含めない。
- DB構造変更はないため今回のためのdb:rollbackは不要。デプロイ後のユーザーデータを消さない。
  seed等が更新したデータはコードの切り戻しだけでは戻らないため、差分を確認して別途判断する。
- 旧Rails 7.2への復帰は保守終了状態へ戻るため緊急時の一時措置。
  8.1への修正反映が終わるまでIssue #127完了とはしない。
- 起動、ログイン、所有データ、主要フローを再確認して結果を記録する。

## 反映状況と残る確認

ローカル実装・対象RSpec・全体RSpec・RuboCop・Brakeman・Git差分確認は完了。
2026-10-31、ユーザーの手動確認完了後、commit・push・PR作成と、CI成功後のdevelopへのマージを依頼された。
GitHub Actionsの結果とマージ状況は対象PRで確認する。
本番設定変更・デプロイは実施しない。Renderの確認が残るため、developへのマージだけでIssue全体の完了とはしない。
