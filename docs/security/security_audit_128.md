# Issue #128 セキュリティ監査・対策

確認日：2026-10-31。対象はdevelopの74de8a8を起点とする現行機能。
本書の「修正」はローカルのコード・検証を指す。本番反映・本番安全性の確認とは区別する。
以下の検証結果は実装フェーズ終了時点の記録。後続でユーザーからcommit・push・PR作成・CI成功後のdevelopへのマージとローカル更新の指示を受けた。
GitHub上の最終結果は対象PRで確認する。本番デプロイ・履歴改変は実施しない。

## 判断の前提

- AGENTS.md、現在の実装・schema・Spec、Issue #128、実装方針第16節を照合した。
- Google認証 #96 は本リリース後へ延期。Issueと外部実装方針に延期理由・将来の紐付け安全要件がすでにあるため重複更新しない。
- Rails 8.1.4 / Ruby 3.4.10 / Devise / importmap / Turbo / Stimulus / Bootstrapを維持する。
- load_defaults 7.2、schemaの7.2表記は#127で意図的に維持したもの。今回の変更対象外。
- 過去のMVP資料の5テーブルではなく、現行schemaの6テーブルを対象にした。
- 既存RSpecの期待値は弱めない。DB変更・migrationはない。
- 既存のPromptTemplate Model Specは、他人の個人テンプレートに結び付く不整合データを意図的に作っていた。新validationと衝突するため、その準備データだけsave!(validate: false)で「過去の不整合」として作成する。available_toによる読み取り時の排除と、通常保存時の拒否を両方維持する。

## 根拠・影響・対策

| ID | 根拠と影響 | 重大度・判定 | 対策・再検証 |
|---|---|---|---|
| S01 | 入力フィルタに本文・元AI出力・検索語等がなく、個人の学習内容がパラメータログへ出る | 中・修正 | 入力フィルタ追加。実リクエストのダミー文字列とfiltered_pathを検証 |
| S02 | 検索SQLには値が引用済みSQLへ展開される箇所があり、リクエストフィルタではSQLログを消せない | 中・修正 | developmentはinfo、本番はinfo以上だけ許可。debug指定を拒む本番起動Spec。外部のアクセスログは未確認 |
| S03 | CSP initializerが無効。sanitizeの防御はあるがブラウザ側の制限がない | 中・コード修正、実ブラウザ確認待ち | CSP強制、ランダムnonce、配信元を限定。importmapとヘッダーの整合をSpecで検証 |
| S04 | ダッシュボードがstyle属性で進捗幅を出力 | CSP適合性の修正 | 数値0〜100のCSSクラスへ変更。unsafe-inlineで回避しない |
| S05 | 本番Hostの明示制限がない | 中・コード修正、本番確認待ち | 既存の公開URLのHostを許可。追加HostはAPP_ADDITIONAL_HOSTSで完全名を指定。未許可Hostは403 |
| S06 | 機密画面・JSON・出力にno-storeの明示がなく、Turboの画面スナップショットも別管理 | 中・修正 | ApplicationControllerでno-store、layoutのturbo-cache-control:no-cacheでTurboの保存・復元も禁止。公開画面も同じ扱いにする。ログアウト後のブラウザ履歴復元は実環境でも確認 |
| S07 | お気に入りの戻り先はredirect_backの既定動作に依存 | 防御の明示化。過去版での悪用可能性を断定しない | allow_other_host: falseを指定。外部Refererは内部の既定先へ、内部Refererは保持 |
| S08 | HTTP経路は所有者を絞るが、Tagging・利用設定Modelに所有関係validationがない | 防御追加。現行HTTP経路の漏えいを示すものではない | 同じ所有者のタグ、共通または本人テンプレートだけ保存可能。DBへの非保存を検証 |
| S09 | 認証3経路にアプリ側の大量試行制限がない | 高・ローカル対策、本番全体の有効性は未確認 | Rails rate_limitでIP・Controller別に10回/3分、超過429・Retry-After。時間経過・IP分離・非保存を検証 |
| S10 | recoverableは有効だがログイン画面からの導線がなく、送信元は仮値。メール配送の実設定不明 | 高・導線/設定対応、配送未確認 | 固定HTTPS復旧URL、送信元環境変数、SMTP設定、失敗応答、paranoid有効。トークン有効期限・再使用拒否・SMTP失敗を検証 |
| S11 | crass 1.0.7が[GHSA-pq4g-8rxf-4g29](https://github.com/rgrove/crass/security/advisories/GHSA-pq4g-8rxf-4g29)の対象（CSS sanitizer bypass） | 公開情報のseverity medium・修正 | advisoryの最初の修正版1.0.8へ限定更新。機能の到達可能性とGem自体の検出を区別し、他のGemをまとめて更新しない |
| S12 | 既存CIはRSpec・RuboCop・鍵ファイル除外のみ | 継続検査を追加 | Brakeman、bundler-audit、Gitleaksによるソース・全ローカル参照履歴検査を追加 |

## 監査で維持した既存の防御

- 個別カードはcurrent_user.cards.find。候補・タグ・集計も本人のRelationに限定。
- 個人テンプレートの変更は本人限定。共通テンプレートは閲覧・お気に入り・履歴記録だけ。
- Strong Parametersで所有者ID・関連IDの直接上書きを禁止。
- 検索値は引用し、LIKEの特殊文字もエスケープ。並び順等は許可値へ正規化。
- MarkdownはCommonmarker unsafe:falseとsanitizeの許可リストを併用。
- 通常表示はERBのエスケープ。候補とタグのStimulusはtextContentとDOM生成を利用し、入力をinnerHTMLへ渡さない。
- AIプレビューはDB保存しない。保存時はカードとタグをtransactionでまとめる。
- 退会は同意・現在のパスワードを要求し、他人のデータを残す。
- 本番HTTPSを強制。セッションCookieのSecure・HttpOnly・SameSite=Laxを本番相当Specで確認。
- reset token、Cookie、秘密値を監査記録・スクリーンショット・CI artifactへ残さない。

## ルート・HTTPメソッドの棚卸し

実行コマンド：docker compose exec web bin/rails routes。
ルートを隠すことではなく、Controller入口と所有者範囲で保護する。

| 入口 | メソッド | 条件・確認 |
|---|---|---|
| /、/terms、/privacy、/contact | GET | 公開。個人データ取得なし |
| /users/sign_in | GET / POST | 公開ログイン。POSTはCSRF・試行制限 |
| /users/sign_out | DELETE | CSRF付きログアウト |
| /users/sign_up、/users/cancel | GET | Devise登録開始・入力状態解除 |
| /users | POST | 登録。CSRF・試行制限、所有者指定を受けない |
| /users/edit、/users | GET / PATCH / PUT / DELETE | 編集は本人。退会は現在パスワード・同意。未ログイン拒否 |
| /users/password/new、/users/password/edit | GET | 復旧開始・トークン付きフォーム。トークンをログに出さない |
| /users/password | POST / PATCH / PUT | 要求に試行制限。変更は有効・未使用トークン。CSRF |
| /account/deletion、/dashboard | GET | ログイン必須。集計は本人のみ |
| /cards、/cards/new | GET | 本人の一覧・作成画面 |
| /cards | POST | 本人へ作成。所有者・tag_idsの改ざんを無視 |
| /cards/:id、/cards/:id/edit | GET | 本人だけ |
| /cards/:id | PATCH / PUT / DELETE | 本人だけ。全メソッドの他人拒否・非更新を検証 |
| /cards/autocomplete、/cards/new_from_ai | GET | 本人の候補・貼り付け画面 |
| /cards/preview_from_ai | POST | ログイン・CSRF。HTML/TurboでXSSと非保存を検証 |
| /cards/:id/export_markdown | GET | 本人だけ。attachment、ファイル名処理、no-store |
| /cards/:id/schedule_review、mark_reviewed、learning_metadata | PATCH | 本人だけ。不正値は保存しない |
| /cards/:id/cancel_review | DELETE | 本人だけ |
| /prompt_templates、/prompt_templates/new | GET | ログイン必須。共通＋本人 |
| /prompt_templates | POST | 本人の個人テンプレート作成 |
| /prompt_templates/:id、/prompt_templates/:id/edit | GET | 閲覧は利用可能範囲、編集は本人のみ |
| /prompt_templates/:id | PATCH / PUT / DELETE | 本人のみ。共通・他人を変更不可 |
| /prompt_templates/:id/favorite、unfavorite、record_usage | POST / DELETE / POST | 利用可能なテンプレートに対し本人の設定だけ変更 |
| /recede_historical_location、resume_historical_location、refresh_historical_location | GET | Turbo Native標準の遷移用画面。カード等の個人データ取得なし |

CSRF Specではallow_forgery_protectionを一時的にtrueにし、終了時に必ず戻す。
フォームとclipboardのPOST、破壊操作で無効トークンを拒否し、有効トークンは成功する。
通常のtest環境のCSRF無効を根拠に安全と判断しない。

## 秘密情報検査と例外

- Gitleaks 8.30.1の公式linux/x64配布物をSHA256固定で使用。アプリ依存には追加しない。
- bin/check_security_secretsは、git ls-filesで列挙した追跡ファイルと非ignored新規ファイルを一時領域へコピーしてソース検査する。
- ローカルの.env、master.key、ログ、coverage等のignored実行時ファイルはコピーしない。
- git --all相当で現在のローカル参照から到達する履歴を検査。未取得のremote参照、fork、過去のcloneまで検査済みとはしない。
- 出力はルール・ファイル・行・commit・fingerprintだけ。スキャナーの生ログとraw reportは表示・アップロードしない。
- 鍵ファイル名の検査を、32桁Rails復号鍵ルールと既定の多種パターン検査で補完。
- 既知パターン検査だけでは、未知形式・誤分類・Git外の秘密情報がないことは保証できない。

例外は.gitleaksignoreの4つの個別fingerprintに限定：

1. 881c8a6のconfig/master.key：#126で確認済みの過去の鍵。履歴からの除去・失効済みという意味ではない。本番失効は#126の所有者確認待ち。
2. 0716b09のDeviseコメント：未使用の生成時コメント。現行ソースからsecret_key/pepperの不要コメントを除去。
3. ef38cbdのbin/check_runtime_credentialsの2行：旧秘密情報との一致を調べる一方向SHA256。秘密値ではない。

現行ソースのハッシュ誤検知は、検査スクリプトのパスとEXPOSED_(KEY|SECRET)_DIGESTの行形式の両方に限定して除外。
ルール全体・鍵パス全体・全履歴の無視はしない。新しい検出を理由なくbaselineへ追加しない。

## 本番依存の未確認事項と担当

| 項目 | 未確認の理由・必要な確認 | 担当 |
|---|---|---|
| #126の旧秘密情報失効 | CLOSEDと資料の本番未確認記録が一致しない。旧鍵・旧秘密情報の利用不能と稼働commitを確認 | Render所有者 |
| #127の本番稼働 | developの更新だけでは本番Railsバージョンは確定できない | Render所有者 |
| 大量試行制限の保存先 | 現行は専用FileStore。単一ファイルシステムを共有しないインスタンスには回数を共有しない。再起動、並列性、ストレージ障害にも限界がある | Codexがコード検証、Render所有者がプロセス数・共有ストア/edge制限・負荷を確認 |
| プロキシ・IP判定 | Rails既定のremote_ipを使用。Renderの転送ヘッダー・信頼プロキシを実環境で確認。任意のX-Forwarded-Forを直接採用しない | Render所有者 |
| Host・HTTPS・Cookie | カスタムドメイン、health check、TLS終端、実レスポンスヘッダーを確認 | Render所有者 |
| メール配送 | DEVISE_MAILER_SENDER、SMTP_ADDRESS/PORT/USERNAME/PASSWORDを安全に供給。現在は実配送未確認。実際の受信・URL・失敗時を確認 | メール/Render所有者 |
| メール未確認アカウント | confirmable未使用。reconfirmable設定だけでは確認されない。メール一致での他アカウント統合・共有は実装していない。本人確認を必須にする場合は既存ユーザー移行・配送失敗を別途設計する | ユーザーと実装担当 |
| パスワードポリシー | 既存の6〜128文字を維持。大量試行制限は漏えいパスワードやoffline解析への対策ではない。強度要件・既存利用者への移行をリリース前に判断 | ユーザーと実装担当 |
| アクセスログ・例外収集 | Rails外のRender/プロキシ/外部監視に検索URL・本文・認証情報が残らないか確認 | 運用所有者 |
| ブラウザ・CSP | rack_testはJSを実行しない。PC/スマートフォン、Turboのnonce更新、Bootstrap、Consoleの違反を実ブラウザで確認 | ユーザー |
| Git外の成果物 | 旧Dockerレイヤー・配布物・保存tar・forkは#126の記録と実物を照合。無断削除しない | 所有者 |

大量試行制限とメール復旧の本番有効性が未確認のため、重大・高リスク未解決なしとはまだ宣言しない。
これらはIssue #128の完了条件に残し、単に対象外へ移さない。

## 再現コマンド

WSLのリポジトリルートで実行。本番用コマンドではない。

```bash
# Gemfile / lock変更後の環境再現
docker compose build web
docker compose up -d web
docker compose exec web bundle check

# 対象 → 全体 → lint → security
docker compose exec web bundle exec rspec spec/security spec/helpers spec/requests/security_boundaries_spec.rb spec/requests/authentication_security_spec.rb spec/requests/authentication_spec.rb spec/requests/cards_spec.rb spec/requests/prompt_templates_spec.rb spec/requests/dashboards_spec.rb spec/models/tagging_spec.rb spec/models/prompt_template_preference_spec.rb spec/models/prompt_template_spec.rb spec/system/password_recovery_spec.rb
docker compose exec -e CI=true web bundle exec rspec
docker compose exec web bundle exec rubocop
docker compose exec web bundle exec rubocop bin/check_security_secrets
docker compose exec web bundle exec brakeman --no-pager --quiet --exit-on-warn --exit-on-error
docker compose exec web bundle exec bundler-audit check --update
bash bin/install_security_scanner
docker compose exec -e GITLEAKS_BIN=tmp/security-tools/gitleaks web ruby bin/check_security_secrets
docker compose exec web ruby bin/check_secret_files
bash bin/check_docker_context
```

Git差分ではDeviseの削除コメントを含め秘密値を表示しない。
今回のGem追加は開発/テスト用bundler-audit。実行時の追加サービス、npm、DB拡張はない。

## 手動確認

PCとスマートフォンでテストユーザーA・Bを使う。Cookieやトークンを撮影・共有しない。

1. 登録・ログイン・ログアウト、誤パスワード、未ログインの直接アクセス。
2. テンプレート選択・お気に入り・コピー・使用履歴。共通テンプレートの変更不可。
3. AI貼り付け→Turboプレビュー→再解析→編集→タグ設定→保存→詳細→検索候補→出力。
4. 空入力・必須欠落・不正復習日から修正して再送できること。二重送信制御。
5. BからAの詳細・編集・出力・更新を利用できず、候補・タグ・集計にも混ざらないこと。
6. 復習予定・記録・理解度・重要度、ダッシュボードの棒グラフ、モバイルメニュー。
7. 戻る・進む・再読み込み・ログアウト後の履歴復元。ConsoleとNetworkのCSP/JS/HTTP失敗。
8. 本番配送設定後の再設定メール受信・URL・変更成功・使用済み/期限切れ拒否・配送失敗。
9. 制限の再現はテスト環境で行い、本番に大量要求を送らない。
10. 退会は同意と現在パスワードを必要とし、他人と共通テンプレートを残す。

## 検証結果

以下はローカル検証結果。実装フェーズではpushを行わなかったため、GitHub Actionsの結果は後続の対象PRで別途確認する。

- 対象RSpec：218件、失敗0。既存の不整合データSpec調整後のModel Spec：12件、失敗0。最後に追加したTurboキャッシュ制御の対象Spec：11件、失敗0。
- 最終の全体RSpec：CI=trueで375件、失敗0。SimpleCov行カバレッジ98.57%（483/490）。
- RuboCop：通常対象105ファイルと拡張子なし検査スクリプト1ファイル、指摘0。
- Brakeman 8.0.5：警告0、解析エラー0、終了コード0。
- bundler-audit 0.9.3：crass 1.0.7の公開問題を検出し、1.0.8へ更新後は検出0。advisory DBは920f5cd5e02cbe598f60afb02f533d608133b795。
- Gitleaks 8.30.1：上記4件の履歴例外と限定したハッシュ誤検知除外を適用後、history/sourceとも追加検出0。生ログ・秘密値は出力しない。
- 鍵追跡除外、Docker実ビルドコンテキスト、開発web再ビルド・再作成、bundle check：成功。
- CI YAML構文・重複キー、Bash構文、スキャナーの取得・SHA256検証：成功。
- Git差分確認・空白検査：成功。READMEのCRLFを維持。DB/schema差分なし、ステージ済み変更なし、HEADは作業開始時の74de8a8のまま。
- ローカルブラウザ：未ログインのログイン画面から再設定要求画面へTurbo遷移。PC幅と390px幅で表示を確認し、該当タブのConsoleのerror/warnは0件。実機スマートフォン、ログイン後の主要フロー、本番配送は未確認。
- System Specの復旧フローはrack_testとtest配送。実ブラウザでのパスワード変更や実メール配送を実施したという意味ではない。

## 変更箇所の読み方

| 変更箇所 | 役割・確認する内容 |
|---|---|
| app/controllers/concerns/authentication_rate_limiting.rb、app/controllers/users/sessions_controller.rb、passwords_controller.rb、registrations_controller.rb、config/initializers/authentication_rate_limit.rb、config/routes.rb | Deviseを維持して試行制限・配送失敗処理を追加 |
| app/controllers/application_controller.rb、app/views/layouts/application.html.erb | HTTP/Turboのキャッシュ制御、共通ヘッダー、CSS読み込み |
| config/initializers/content_security_policy.rb、app/views/dashboards/show.html.erb、app/assets/stylesheets/progress_widths.css | CSPの強制と既存表示の両立 |
| config/initializers/filter_parameter_logging.rb、config/environments/development.rb、production.rb、config/initializers/devise.rb | ログ、Host、Cookie、メール設定 |
| app/models/tagging.rb、prompt_template_preference.rb、app/controllers/prompt_templates_controller.rb | 所有関係とリダイレクト先の防御 |
| app/views/devise/shared/_links.html.erb、app/views/devise/passwords/new.html.erb、edit.html.erb | 日本語の復旧導線とフォーム |
| Gemfile、Gemfile.lock | 検査Gem追加とcrassの限定更新 |
| .github/workflows/ci.yml、.gitleaks.toml、.gitleaksignore、bin/check_security_secrets、bin/install_security_scanner | 秘密値を出さない継続検査 |
| spec/requests/security_boundaries_spec.rb、authentication_security_spec.rb | 認可・CSRF・XSS・CSP・キャッシュ・認証の回帰 |
| spec/models/tagging_spec.rb、prompt_template_preference_spec.rb、prompt_template_spec.rb | 所有関係の保存拒否と過去の不整合に対する読み取り分離 |
| spec/security/parameter_filter_spec.rb、secret_scanner_spec.rb、production_credentials_spec.rb | ログ露出防止、スキャナーの失敗時、本番相当起動 |
| spec/rails_helper.rb、spec/system/password_recovery_spec.rb | 試行回数のテスト間分離と復旧の画面フロー |
| README.md、本書 | 検証手順・運用上の残事項 |
