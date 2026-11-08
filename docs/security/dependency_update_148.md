# Issue #148 依存Gemセキュリティ更新記録

確認日：2026-11-09（日本時間）。最新origin/develop `06b8d16`から`fix/148-security-dependencies`を作成した。
ローカル実装・検証の記録。本番反映やCI実行、PC/スマートフォンの実ブラウザ確認は別途必要。

## 選定と依存制約

公式リポジトリのSecurity Advisory 43件をGitHub APIで再取得し、影響範囲・修正版を照合した。
更新前の最新bundler-auditは64エントリ、GHSAで重複除外すると43件で、Issueの一覧と完全一致。
Nokogiriの複数プラットフォームを別の問題として数えない。追加GHSAはなかった。

| Gem | 更新前 | 公式修正下限 | 採用版 |
|---|---|---|---|
| actionmailbox | 8.1.4 | 8.1.4.1 | [8.1.4.1](https://rubygems.org/gems/actionmailbox/versions/8.1.4.1) |
| actionpack | 8.1.4 | 8.1.4.1 | [8.1.4.1](https://rubygems.org/gems/actionpack/versions/8.1.4.1) |
| actionview | 8.1.4 | 8.1.4.1 | [8.1.4.1](https://rubygems.org/gems/actionview/versions/8.1.4.1) |
| activestorage | 8.1.4 | 8.1.4.1 | [8.1.4.1](https://rubygems.org/gems/activestorage/versions/8.1.4.1) |
| activesupport | 8.1.4 | 8.1.4.1 | [8.1.4.1](https://rubygems.org/gems/activesupport/versions/8.1.4.1) |
| addressable | 2.9.0 | 2.9.1 | [2.9.2](https://rubygems.org/gems/addressable/versions/2.9.2) |
| loofah | 2.25.2 | 2.25.3 | [2.25.3](https://rubygems.org/gems/loofah/versions/2.25.3) |
| nokogiri | 1.19.4 | 1.19.5 | [1.19.7](https://rubygems.org/gems/nokogiri/versions/1.19.7) |
| rack | 3.2.6 | 3.2.8 | [3.2.8](https://rubygems.org/gems/rack/versions/3.2.8) |
| rails-html-sanitizer | 1.7.1 | 1.7.2 | [1.7.2](https://rubygems.org/gems/rails-html-sanitizer/versions/1.7.2) |

- Railsは8.1.4.1に完全固定。RailsメタGemの等号依存により、Action Cable/Mailer/Text、Active Job/Model/Record、Railtiesも同版へ揃える。
- Action View 8.1.4.1はrails-html-sanitizer `~> 1.6, >= 1.7.2`、sanitizerはLoofah `~> 2.25, >= 2.25.3`、LoofahはNokogiri `>= 1.19.5`を要求する。
- Addressableはpublic_suffix `>= 2.0.2, < 8.0`を維持。Capybaraのtestグループ経由で、productionだけのbundleには含まれない。実本番のインストール対象は未確認。
- RubyGems APIで下限版と採用版のRuby/依存要件を確認。Rails/Loofah/sanitizerはRuby >= 3.2.0、Nokogiri >= 3.2、Addressable >= 2.2、Rack >= 2.4.0。Ruby 3.4.10で満たす。
- `bundle update rails addressable loofah nokogiri rack rails-html-sanitizer --conservative --patch --strict`で対象だけを指定。修正下限を最新版とは扱わず、解決された同系列のAddressable 2.9.2、Nokogiri 1.19.7も公式配布情報で確認した。
- Gem追加・削除なし。Nokogiriの8つのバイナリ対象とPLATFORMS全9項目、Bundler 2.6.9、Ruby、Devise、PostgreSQL、load_defaults 7.2は維持。
- 独自patch、ignore追加、CI緩和、DB/migration/schema変更なし。READMEの現行版だけを更新し、#127/#128の過去の検証記録は書き換えない。

## 公式告知43件と利用条件

「使用箇所なし」は今回のアプリソース検索の結果で、将来の利用や本番設定まで保証しない。
攻撃成立・被害を43件すべて確認したという意味ではない。未使用条件でもlock上の検出は更新で解消する。
各行の再監査結果は後述の最新DBでの監査に基づく。

| 公式GHSA | 対象Gem | 利用条件・現行との照合 | 採用版 | 再監査 |
|---|---|---|---|---|
| [GHSA-5957-c7qm-m469](https://github.com/rails/rails/security/advisories/GHSA-5957-c7qm-m469) | actionmailbox | Mailgun ingressの署名済みリクエスト再利用。Action Mailbox engineを読み込まない。 | 8.1.4.1 | 検出なし |
| [GHSA-2586-8ghr-69fj](https://github.com/rails/rails/security/advisories/GHSA-2586-8ghr-69fj) | actionpack | CacheStoreの並行logout。現行productionはCookieStoreで、この条件と異なる。 | 8.1.4.1 | 検出なし |
| [GHSA-2gff-2mmg-m73p](https://github.com/rails/rails/security/advisories/GHSA-2gff-2mmg-m73p) | actionpack | プロキシがForwardedを透過し、IP依存制限を使う場合。認証制限あり。本番ヘッダー処理は未確認。 | 8.1.4.1 | 検出なし |
| [GHSA-gmj8-hvj3-49mw](https://github.com/rails/rails/security/advisories/GHSA-gmj8-hvj3-49mw) | actionpack | CookieStore以外でSameSite未指定の場合。productionはCookieStoreかつsame_siteを明示。 | 8.1.4.1 | 検出なし |
| [GHSA-r9jg-fmfx-2gv6](https://github.com/rails/rails/security/advisories/GHSA-r9jg-fmfx-2gv6) | actionpack | 共有キャッシュ配下の公開ネゴシエーション応答。所有データはno-store。実配信経路は未確認。 | 8.1.4.1 | 検出なし |
| [GHSA-rwvh-fw6r-pwvp](https://github.com/rails/rails/security/advisories/GHSA-rwvh-fw6r-pwvp) | actionpack | ActionController::Live/send_streamの停止クライアント。アプリに使用箇所なし。 | 8.1.4.1 | 検出なし |
| [GHSA-wm3x-v3qw-4jh3](https://github.com/rails/rails/security/advisories/GHSA-wm3x-v3qw-4jh3) | actionpack | Parameters#each_keyの戻り値を一括代入する場合。現行require/permitで該当呼び出しなし。 | 8.1.4.1 | 検出なし |
| [GHSA-x6mj-8jx9-qhqv](https://github.com/rails/rails/security/advisories/GHSA-x6mj-8jx9-qhqv) | actionpack | Active Storage proxyとcookie rotation等と共有キャッシュの組合せ。Storage engineは無効。 | 8.1.4.1 | 検出なし |
| [GHSA-2p2f-4rq4-gjwc](https://github.com/rails/rails/security/advisories/GHSA-2p2f-4rq4-gjwc) | actionview | HTML5 sanitizer後のhighlight/simple_formatの文字列処理。メモはsimple_formatを使うため安全表示を回帰確認。 | 8.1.4.1 | 検出なし |
| [GHSA-68p9-83h6-5wpj](https://github.com/rails/rails/security/advisories/GHSA-68p9-83h6-5wpj) | actionview | 利用者がHTML属性名を指定する場合。アプリに該当する属性名入力なし。 | 8.1.4.1 | 検出なし |
| [GHSA-rq8q-p985-fjq7](https://github.com/rails/rails/security/advisories/GHSA-rq8q-p985-fjq7) | actionview | strip_tags出力をHTML属性へ挿入する場合。アプリにstrip_tags呼び出しなし。 | 8.1.4.1 | 検出なし |
| [GHSA-v6rj-xm57-3p59](https://github.com/rails/rails/security/advisories/GHSA-v6rj-xm57-3p59) | actionview | highlightの正規表現・置換文字列処理。アプリにhighlight呼び出しなし。 | 8.1.4.1 | 検出なし |
| [GHSA-3f4q-8x5m-76v8](https://github.com/rails/rails/security/advisories/GHSA-3f4q-8x5m-76v8) | activestorage | 動画preview/analysisと入力されたファイル名等。Storage engine・添付宣言なし。 | 8.1.4.1 | 検出なし |
| [GHSA-3w93-6hmw-whh4](https://github.com/rails/rails/security/advisories/GHSA-3w93-6hmw-whh4) | activestorage | GCS直接uploadとcache_control。Storage engine・添付宣言なし。 | 8.1.4.1 | 検出なし |
| [GHSA-4v2w-w6g6-f8f8](https://github.com/rails/rails/security/advisories/GHSA-4v2w-w6g6-f8f8) | activestorage | Storage proxy streaming中のストレージエラー。Storage engineは無効。 | 8.1.4.1 | 検出なし |
| [GHSA-f3w6-w445-fwh9](https://github.com/rails/rails/security/advisories/GHSA-f3w6-w445-fwh9) | activestorage | 画像analysisの処理とファイルパス。Storage engine・添付宣言なし。 | 8.1.4.1 | 検出なし |
| [GHSA-hfr4-8rjc-97m2](https://github.com/rails/rails/security/advisories/GHSA-hfr4-8rjc-97m2) | activestorage | GCS直接uploadのサイズ制限回避。Storage engine・添付宣言なし。 | 8.1.4.1 | 検出なし |
| [GHSA-p2pm-g2h6-7j5j](https://github.com/rails/rails/security/advisories/GHSA-p2pm-g2h6-7j5j) | activestorage | Storageの長大なfilename処理。Storage engine・添付宣言なし。 | 8.1.4.1 | 検出なし |
| [GHSA-v924-7rp8-4mxh](https://github.com/rails/rails/security/advisories/GHSA-v924-7rp8-4mxh) | activestorage | 動画/画像処理と外部コマンド・ファイル参照。Storage engine・添付宣言なし。 | 8.1.4.1 | 検出なし |
| [GHSA-2w9f-fxwj-w2qf](https://github.com/rails/rails/security/advisories/GHSA-2w9f-fxwj-w2qf) | activesupport | MessagePack serializerでの安全な文字列の復元。アプリにMessagePack serializer指定なし。 | 8.1.4.1 | 検出なし |
| [GHSA-8474-xrp6-wh69](https://github.com/rails/rails/security/advisories/GHSA-8474-xrp6-wh69) | activesupport | safe_constantizeに攻撃者指定の長大文字列を渡す場合。アプリに直接呼び出しなし。 | 8.1.4.1 | 検出なし |
| [GHSA-4w5q-wg7v-w6gp](https://github.com/sporkmonger/addressable/security/advisories/GHSA-4w5q-wg7v-w6gp) | addressable | 複数の展開変数を持つURIテンプレート。AddressableはtestのCapybara経由、アプリ直接使用なし。 | 2.9.2 | 検出なし |
| [GHSA-539f-xcgw-2gjg](https://github.com/sporkmonger/addressable/security/advisories/GHSA-539f-xcgw-2gjg) | addressable | display_uriの不可視文字・双方向文字によるホスト誤認。Capybara経由で、アプリ直接使用なし。 | 2.9.2 | 検出なし |
| [GHSA-8gmh-2hhj-2hv9](https://github.com/sporkmonger/addressable/security/advisories/GHSA-8gmh-2hhj-2hv9) | addressable | ドット区間を含むURIの正規化。CapybaraのURL処理を全RSpecのSystem Specで確認。 | 2.9.2 | 検出なし |
| [GHSA-9crm-g4mf-wc5j](https://github.com/sporkmonger/addressable/security/advisories/GHSA-9crm-g4mf-wc5j) | addressable | display_uriの不正Punycodeホスト表示。Capybara経由で、アプリ直接使用なし。 | 2.9.2 | 検出なし |
| [GHSA-9f42-57jx-vpp3](https://github.com/sporkmonger/addressable/security/advisories/GHSA-9f42-57jx-vpp3) | addressable | 複数変数を持つURIテンプレート。Capybara経由で、アプリ直接使用なし。 | 2.9.2 | 検出なし |
| [GHSA-j82w-28jv-3pmj](https://github.com/sporkmonger/addressable/security/advisories/GHSA-j82w-28jv-3pmj) | addressable | 展開式を持つURIテンプレート。Capybara経由で、アプリ直接使用なし。 | 2.9.2 | 検出なし |
| [GHSA-qq38-m9mg-xjj5](https://github.com/sporkmonger/addressable/security/advisories/GHSA-qq38-m9mg-xjj5) | addressable | URIパス正規化の過剰処理。CapybaraのURL処理を既存System Specで確認。 | 2.9.2 | 検出なし |
| [GHSA-345x-3rq2-jfrm](https://github.com/flavorjones/loofah/security/advisories/GHSA-345x-3rq2-jfrm) | loofah | SVG参照要素の外部URI許可。Markdown許可タグにSVGを含まない。 | 2.25.3 | 検出なし |
| [GHSA-h6v6-rg66-fqj4](https://github.com/flavorjones/loofah/security/advisories/GHSA-h6v6-rg66-fqj4) | loofah | HTML5 scrubberで属性値を再シリアライズする場合。HTML表示経路の関連Specで確認。 | 2.25.3 | 検出なし |
| [GHSA-jcff-cj73-4w4f](https://github.com/flavorjones/loofah/security/advisories/GHSA-jcff-cj73-4w4f) | loofah | allowed_uri?単独呼び出しのHTML文字参照。アプリに直接呼び出しなし。sanitize経路と区別。 | 2.25.3 | 検出なし |
| [GHSA-m3x9-938q-5767](https://github.com/flavorjones/loofah/security/advisories/GHSA-m3x9-938q-5767) | loofah | CSS url()内のエスケープされた括弧。Markdownはstyle属性を許可しない。 | 2.25.3 | 検出なし |
| [GHSA-mf2j-8f84-cc9q](https://github.com/flavorjones/loofah/security/advisories/GHSA-mf2j-8f84-cc9q) | loofah | SVG参照の空白正規表現。SVGを許可せずCRuby 3.4.10を使用。 | 2.25.3 | 検出なし |
| [GHSA-p9wj-w8xq-vjx6](https://github.com/flavorjones/loofah/security/advisories/GHSA-p9wj-w8xq-vjx6) | loofah | allowed_uri?単独呼び出しのセミコロンなし文字参照。アプリに直接呼び出しなし。 | 2.25.3 | 検出なし |
| [GHSA-3w22-6jfg-527w](https://github.com/sparklemotion/nokogiri/security/advisories/GHSA-3w22-6jfg-527w) | nokogiri | XML属性の子ノード参照後に属性値を置換する特殊なAPI使用。アプリに該当する直接使用なし。 | 1.19.7 | 検出なし |
| [GHSA-4p39-36wj-23h4](https://github.com/sparklemotion/nokogiri/security/advisories/GHSA-4p39-36wj-23h4) | nokogiri | HTML5 noscript等の再シリアライズ。Markdownでnoscriptを許可しない。属性値の安全表示は関連Specで確認。 | 1.19.7 | 検出なし |
| [GHSA-v995-44v6-5fqm](https://github.com/sparklemotion/nokogiri/security/advisories/GHSA-v995-44v6-5fqm) | nokogiri | JRubyでNONETとDTD/entity読込を組み合わせる場合。現行はCRuby。 | 1.19.7 | 検出なし |
| [GHSA-2j8w-xcrc-x985](https://github.com/rack/rack/security/advisories/GHSA-2j8w-xcrc-x985) | rack | 不正Hostからの絶対URL生成。公式はRailsのoverrideを区別。公開URL設定の既存Helper Specを実行。 | 3.2.8 | 検出なし |
| [GHSA-5v64-555j-wjxm](https://github.com/rack/rack/security/advisories/GHSA-5v64-555j-wjxm) | rack | multipart解析のバッファ肥大。画面の有無で除外しない。本番の本文容量制限は未確認。 | 3.2.8 | 検出なし |
| [GHSA-p8x9-v4hv-2w4g](https://github.com/rack/rack/security/advisories/GHSA-p8x9-v4hv-2w4g) | rack | 複数boundaryによるWAF等との解釈差。本番の入口制限は未確認。Rack自体を更新。 | 3.2.8 | 検出なし |
| [GHSA-wvg4-6p58-3gh3](https://github.com/rack/rack/security/advisories/GHSA-wvg4-6p58-3gh3) | rack | Rack::Staticのpath別header_rulesとドット区間。アプリにRack::Staticの直接設定なし。 | 3.2.8 | 検出なし |
| [GHSA-cpgf-5mjf-73p7](https://github.com/rails/rails-html-sanitizer/security/advisories/GHSA-cpgf-5mjf-73p7) | rails-html-sanitizer | SVG参照要素を許可した場合の正規表現DoS。SVGを許可せず、CRuby 3.4.10を使用。 | 1.7.2 | 検出なし |
| [GHSA-h7wh-q2qr-458c](https://github.com/rails/rails-html-sanitizer/security/advisories/GHSA-h7wh-q2qr-458c) | rails-html-sanitizer | 複数スレッドで異なるsanitize許可設定を使う場合。Puma・独自許可リストがあり照合対象。現行設定で攻撃成立は未確認。 | 1.7.2 | 検出なし |

## 回帰確認の範囲

既存の所有者分離・Strong Parameters・実CSRF・認証試行制限・パスワード復旧のSpecを利用する。
Helper Specに通常改行と文字参照/制御文字/データURLの安全表示、カードRequest Specにメモの改行・不正HTML/URL除去を追加。
Commonmarkerは危険URLを空hrefやパーセント符号化として残す場合があるため、削除の形だけでなく実行可能な危険スキームが残らないことを確認する。
ライブラリ内部43件の再実装や、再現性の低い並行競合テスト、巨大リクエストは追加しない。

## 実行結果

以下は今回更新後のローカル実行結果。すべて終了コード0。GitHub Actions実行結果とは区別する。

| 確認 | コマンド（ComposeはWSLのrepo root） | 結果 |
|---|---|---|
| web再ビルド・再起動 | `docker compose build web` → `docker compose up -d web` | 成功。DB volumeを維持 |
| 依存・実行版 | `docker compose exec -T web bundle check` / `bin/rails --version` | 成功、Rails 8.1.4.1 |
| 関連RSpec | `docker compose exec -T web bundle exec rspec spec/helpers/application_helper_spec.rb spec/requests/security_boundaries_spec.rb spec/requests/authentication_security_spec.rb spec/requests/cards_spec.rb` | 123件、失敗0 |
| 全RSpec | `docker compose exec -T -e CI=true web bundle exec rspec` | 378件、失敗0。SimpleCov 98.57%（483/490） |
| RuboCop | `docker compose exec -T web bundle exec rubocop` | 105ファイル、指摘0 |
| Brakeman | `docker compose exec -T web bundle exec brakeman --no-pager --quiet --exit-on-warn --exit-on-error` | 8.0.5、警告0、解析エラー0 |
| 最新依存監査 | `docker compose exec -T web bundle exec bundler-audit check --update --format json` | 0.9.3、results空、43件すべて解消、追加検出なし |
| 秘密情報 | `docker compose exec -T -e GITLEAKS_BIN=tmp/security-tools/gitleaks web ruby bin/check_security_secrets` | Gitleaks 8.30.1、history/sourceとも0件 |
| Rails鍵除外 | `docker compose exec -T web ruby bin/check_secret_files` | 未追跡・ignore成功 |
| Docker context | `bash bin/check_docker_context` | 鍵除外・暗号化credentials保持成功 |
| autoload | `docker compose exec -T web bin/rails zeitwerk:check` | 成功 |
| migration状態 | `docker compose exec -T web bin/rails db:migrate:status` | 既存9件すべてup。migrateは不要・未実行 |
| HTTP起動確認 | localhostのログイン画面へGET | 200。実ブラウザ操作は未実施 |

最新監査DB：`7e90cbd88d767c9281acefbb8854c80e0cad6060`、1352 advisories、表示上の最終更新2026-11-07 21:07:00 -0500。
初回の新規Helper Specは、安全な空href/符号化URLまで削除を要求した期待値で1件失敗した。アプリの処理は変更せず、実行可能な危険スキームと生の制御文字を拒否する期待値に修正し、関連→全体を再実行して上記の成功を確認した。

最終差分で対象GemとRails追随分だけの更新、新Gem追加・削除なし、PLATFORMS/Ruby/Bundler維持を照合済み。schema・アプリコード・Dockerfile・CI・ignore設定に変更はない。

空白検査はREADMEの既存CRLFを維持するため、`git -c core.whitespace=cr-at-eol diff --check`で成功。ステージ済み変更なし、HEADは作業開始時の`06b8d16`のまま。

## 残る手動確認・本番確認

- 担当：ユーザー。PC/スマートフォンでログイン→テンプレートコピー→貼付→プレビュー/編集→保存→詳細→検索/タグ→復習。本文の表・コード・リンク、メモ改行、validation時の入力保持を確認する。
- 担当：ユーザー。Turbo/Stimulus、コピー、モバイルメニュー、Console/CSP、ログアウト後・他ユーザー拒否をテストデータで確認する。System Specはrack_testのためJavaScript動作や実機確認を代替しない。
- 担当：本番運用者（#128/#100）。稼働commit/配備Gemを確認する。今回はデプロイ未実施で、developの依存変更だけでは本番の解消と扱わない。
- 担当：本番運用者（#128/#100）。入口プロキシが利用者のForwarded/X-Forwarded-Forを除去・上書きし、正規のクライアントIPを渡すことを設定と小さな検証で確認する。X-Forwarded-Forを付与しない透過構成はRails更新だけでは保護できない。両ヘッダーが不整合だと更新後にIpSpoofAttackErrorとなる可能性がある。
- 担当：本番運用者。Cookie/HTTPS、共有キャッシュ、リクエスト本文容量とmultipartの入口制限を設定画面等で確認する。リポジトリだけでは実際の制限値を確定できず、今回値・秘密情報を取得しない。
- 担当：ユーザー。本番メール配送と復旧フローは別途確認。ローカルSpecはtest配送で外部メールを送らない。
- PR/CIは別途許可後。commit・push・PR作成・mergeは今回行わない。
