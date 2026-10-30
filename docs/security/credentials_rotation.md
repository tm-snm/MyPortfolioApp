# Rails credentials更新手順（Issue #126）

## 今回のローカル対応と、まだ実施していないこと

- 復号鍵とcredentials内の `secret_key_base` を更新した。新しい鍵はローカルの `config/master.key` に保持し、Git追跡を解除した。
- 新鍵による復号、旧鍵による新credentialsの復号失敗、秘密情報の変更を値を出さずに確認した。
- `.gitignore` の既存除外を維持し、`.dockerignore` に鍵の除外を追加した。
- Git追跡・Dockerの実ビルドコンテキスト・本番起動・セッション失効を検証する仕組みを追加した。
- 本番設定変更・本番デプロイ・Git履歴改変・既存イメージ削除は実施していない。マージはユーザーが行う。
- DB構造、Gem、認証方法、ユーザーごとの認可は変更していない。Google認証の追加・設定は行わない。

本番反映前なので、Issue全体の完了ではない。以下の未確認事項を解消し、旧秘密情報の利用不能と本番動作を確認して完了とする。

## 影響調査の結果と限界

| 対象 | 調査結果 | 残る確認・担当 |
|---|---|---|
| Git | 公開リポジトリで復号鍵と暗号化credentialsを追跡していた。確認可能な履歴では2026-08-03の版がある | 古いbranch・clone・fork・ダウンロード物にも残り得る。所有者が配布先を確認する |
| 公開済みcredentials | 確認した公開版の設定は `secret_key_base` のみ。現行・履歴を復号検証した | Git外の過去credentials、別の鍵・サービスへの流用は所有者が確認する |
| ローカル旧Dockerイメージ | 既存の `recall_card-web:latest` の全12レイヤーを調べ、鍵の混入を確認した | 削除は未実施。稼働コンテナ、関連タグ、保存tar、ビルドキャッシュ、配布先は所有者が整理する |
| ローカル新Dockerイメージ | 修正後ソースで検証用イメージをビルドし、全12レイヤーに鍵がないことを確認した | 本番側の新イメージ・キャッシュは本番反映時に所有者が再確認する |
| 本番コード | `bin/render-build.sh` はassetsの処理に加えmigration・seedを実行する。Rails起動時に鍵が必要になる | Renderが実際にこのビルドコマンドを使うかは未確認 |
| Render | リポジトリにBlueprintはない。GitHubのdeployment/status記録・ローカル操作履歴から実設定を確定できなかった | Runtime・環境変数・Secret Files・Environment Groups・過去デプロイをRender所有者が確認する |
| 本番の鍵・秘密情報 | 公開済みの値との一致・使用履歴は未確認 | 更新前の診断と過去設定の確認が必要。現在が別の値でも過去の使用を否定できない |
| DB | 現在コードにActive Record暗号化や独自のDBカラム暗号化は見当たらない | 過去版・本番独自設定・外部保存データに暗号化用途がないか所有者が確認する |

鍵・credentialsの実値、復号内容、Cookie、環境変数一覧を記録・投稿しない。
公開済みの暗号文は旧鍵で今後も復号できる。Git履歴削除だけで秘密情報を失効させることはできない。

## 更新前にRenderで確認する項目（まだ変更しない）

1. 対象サービスのSettingsでRuntimeがRuby NativeかDockerかを確認する。
2. 接続リポジトリ、デプロイbranch、現在稼働中のcommit、Auto-Deploy、Build Command、Start Commandを確認する。
3. Environmentで `RAILS_MASTER_KEY` と `SECRET_KEY_BASE` の設定有無だけ確認する。Linked Environment Groupsにも同名設定がないか調べる。
4. Secret Filesの `master.key` と、起動スクリプトによる `config/master.key` へのコピー・リンクがないか確認する。値は表示・共有しない。
5. 過去デプロイ・設定変更記録から、公開鍵または公開済み `secret_key_base` を使った期間・サービスを確認する。
6. 他用途の暗号化データや秘密情報が見つかった場合は、用途を特定してから移行・失効計画を補う。パスワードやカード本文を一括更新する必要は、現在コードからは認められない。

Shellが利用できる場合、今回の `bin/check_runtime_credentials` を安全な経路で一時ファイルとして渡し、
アプリのルートディレクトリで実行すると、現在の値と公開済み値の一致を判定できる。
スクリプト内には公開済み値のSHA256フィンガープリントだけがあり、鍵・秘密情報そのものはない。
診断は設定を変更せず、DBへの問い合わせも行わない。更新前の非ゼロ終了は想定される。

```bash
# 更新前の本番Shellで、アプリルートにいることを確認してから実行する。
RAILS_ENV=production bundle exec ruby /tmp/check_runtime_credentials
```

| 診断結果 | 意味・更新後の期待値 |
|---|---|
| `key_required` | 鍵必須設定。更新後はtrue |
| `credentials_readable` | credentialsにsecret_key_baseがある。true |
| `explicit_secret_override` | SECRET_KEY_BASEによる上書きあり。false |
| `effective_secret_from_credentials` | 実際の秘密情報とcredentialsが一致。true |
| `decryption_key_matches_exposed` | 公開済み復号鍵と一致。false |
| `credentials_secret_matches_exposed` | credentials内の公開済み秘密情報と一致。false |
| `effective_secret_matches_exposed` | 実際に使用する秘密情報が公開済み値と一致。false |

Shellにアクセスできない場合は、設定の比較・過去の使用履歴を未確認として記録し、所有者が確認できる環境・担当を用意する。
本番の設定を推測して「影響なし」「失効済み」と判定しない。

## Renderへの反映手順（レビューと別途指示の後に実施）

### 1. 切替を準備する

- 新しい `config/master.key` を権限を絞った安全な保管先へ保存する。新しいcredentialsに対応する鍵が失われると復号できない。
- 既存セッションとログイン状態保持Cookieの失効、再ログイン、開きっぱなしフォームの再読み込みが必要になることを想定する。
- 現在の配信対象はmain。develop向けPRの作成・レビューを先に進め、mainへ反映する前にRenderのRuntime・環境変数・Auto-Deployの状態を確認する。
- **mainへマージする前に、所有者がAuto-Deployを一時停止する。** 設定準備中の旧コードや、旧鍵と新credentialsの不一致による自動デプロイを防ぐ。
- mainへのマージはユーザーが行い、反映対象のcommitを確定する。その後、新しい鍵をSave onlyで準備し、対応するmainを手動デプロイする。

### 2. 新しい鍵と上書き設定を同時に準備する

1. Render → 対象サービス → Environmentを開く。
2. `RAILS_MASTER_KEY` を新しいローカル鍵に置き換える。未設定なら追加する。値は安全な方法で入力し、チャットやコマンド出力に残さない。
3. `SECRET_KEY_BASE` があれば上書きを削除し、新credentialsの値にそろえる。共有Environment Groupから供給される場合も確認する。
4. 古いSecret File・コピー処理があれば供給経路を整理する。環境変数を一本化する前に、他サービスへの影響を確認する。
5. この時点では **Save only** を選ぶ。**Save and deploy** で旧ビルドを新鍵だけに切り替えない。

Environment GroupやSecret Filesの更新は別サービスの再デプロイも誘発し得る。
共有設定にしか旧値がない場合は、サービス単位の新鍵設定と上書き設定の見直しを先に計画し、影響先を確定してから更新する。

### 3. 対応する新credentialsのcommitを再ビルド・デプロイする

- 新しい鍵・新credentials・鍵必須設定・Git追跡解除を含むcommitを指定してデプロイする。
- 古いビルドやイメージへの混入を避けるため、Renderの **Clear build cache & deploy** 等で再ビルドする。イメージ指定方式なら、修正後ソースから新しく作ったイメージを使う。
- Ruby Nativeの場合：実際のBuild Commandでassets処理から起動まで成功するか確認する。現在の `bin/render-build.sh` はmigration・seedも実行するため、その内容を再確認してから使う。今回の変更にmigrationはない。
- Dockerの場合：`.dockerignore` によって鍵を含めずビルドし、実行時は `RAILS_MASTER_KEY` で供給する。現在のDockerfileはビルド中にRailsを起動しない。
- 実際のDockerビルドに独自のRails実行工程があれば、鍵の必要性とsecret mountを別途確認する。実鍵を `ARG`・`ENV`・`COPY` に埋め込まない。
- 起動成功と稼働commitを確認し、Auto-Deployを変更した場合は適切な状態に戻す。

### 4. 反映後に検証する

```bash
# Render Shellでアプリルートから実行。出力は判定だけ。
RAILS_ENV=production bundle exec ruby bin/check_runtime_credentials
```

診断が期待値どおりで終了コード0になることを確認する。
さらに、切替前からログインしていたブラウザと「ログイン状態を保持する」を使っていたブラウザで、
保護ページが旧状態では利用できず、既存パスワードで再ログインできることを確認する。

- PC・スマートフォンでログイン、ログアウト、未ログインの保護ページ遷移を確認する。
- 誤ったパスワードではログインできず、他ユーザーのカードが表示・変更されないことを確認する。
- 既存カード・タグ・復習情報を読めること、AI貼り付け→プレビュー→保存→検索が動くことを確認する。
- validationで不正データが保存されないこと、Turbo・Stimulusの送信ボタンやコピーが動くことを確認する。
- Browser Console・Network・Render Logsに新たなエラーがないことを確認する。Cookie・秘密値を記録しない。
- 古いフォームのCSRFエラーが再読み込み・再ログイン後に解消することを確認する。
- Deviseのパスワード再設定・ログイン状態保持も確認する。パスワード再設定は実際のメール配送設定が利用可能な場合に確認する。

### 5. 既存成果物と残存秘密情報を整理する

- ローカル旧イメージ・キャッシュ・保存tar・レジストリ・Renderの旧ビルドなど、確認できた配布先を一覧化する。
- 稼働中の対象と共有キャッシュへの影響を確認してから、所有者が対象を限定して廃棄する。一括pruneや無関係なDockerデータ削除は行わない。
- 削除できない旧ビルドがあれば、参照・再デプロイを避ける運用と、含まれる秘密情報の失効を記録する。
- 古いclone・branchから再混入しないよう関係者へ更新手順を共有する。Git履歴改変は別途承認された計画で行う。
- 診断した現在値だけでなく、他サービスへの流用・過去に復号可能だった秘密情報の更新も確認する。

## 失敗した場合

- 起動しない場合、新credentialsと `RAILS_MASTER_KEY` の組合せ、環境別credentials、Environment Groupsの上書きを最初に確認する。
- 鍵の値・credentialsの復号内容をログへ出さない。秘密値をコマンド引数に指定しない。
- 漏えいした旧鍵・旧secret_key_baseを有効に戻す切り戻しは行わない。
- 新鍵と新秘密情報を維持したまま修正ビルドを出す。コードを戻す必要がある場合も、新credentials・新鍵・再混入防止は維持する。
- 他の暗号化データが見つかった場合、破棄・再暗号化を先走らず、独立した復旧・移行手順を決める。

## ローカル検証結果

- 対象RSpec（`spec/security`、認証・カード・テンプレートRequest Spec、主要フローSystem Spec）：169件、失敗0。
- 全体RSpec：343件、失敗0。SimpleCovの行カバレッジ96.68%。
- RuboCop：通常対象96ファイルと、拡張子なしRuby検査スクリプト2ファイルで指摘0。
- CI YAMLの構文・重複キー検査、Bash構文、Git追跡除外、Docker実コンテキスト検査：成功。
- ローカル本番相当起動・新鍵による復号・旧鍵拒否・旧セッション失効・runtime診断：成功。
- 変更ファイルの新旧鍵・秘密情報平文混入検査：0件。新しい鍵ファイルの権限は0600。
- Git差分は秘密鍵削除の内容を表示せず確認。READMEの既存CRLFを維持し、`core.whitespace=cr-at-eol` で差分の空白検査に成功。
- 既存Spec由来の `:unprocessable_entity` 非推奨警告は残る。今回のIssue範囲外として変更していない。
- 本番への診断・反映、PC・スマートフォンの実ブラウザ確認は未実施。GitHub Actionsの結果は対象PRで確認する。

## 参考

- [Rails 7.2 セッションと秘密情報](https://guides.rubyonrails.org/v7.2/security.html#session-storage)
- [Render環境変数・Secret Files・Environment Groups](https://render.com/docs/configure-environment-variables)
- [RenderとDockerの秘密情報](https://render.com/docs/docker-secrets)
- [Dockerビルドコンテキスト](https://docs.docker.com/build/concepts/context/#dockerignore-files)
