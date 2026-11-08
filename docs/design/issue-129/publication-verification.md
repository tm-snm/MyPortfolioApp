# 成果物公開時の検証記録

確認日: 2026-11-09
作業ブランチ: `feature/129-ui-design-specs` / PR base: `develop`

## 変更範囲

本フォルダの設計資料・比較画像・現行画面画像・静的部品見本を初めてGit管理に追加した。
公開前の状態に合わせて文書の共有方針を更新し、新規テキストの末尾空白・改行を整理した。
アプリコード・Gem・設定・schema・migration・既存Specの変更はない。

## 実行結果

| 確認 | 結果 |
|---|---|
| `docker compose exec -T web bundle exec rspec` | 375 examples, 0 failures |
| `docker compose exec -T web bundle exec rubocop` | 105 files inspected, no offenses detected |
| 既存の`bin/check_security_secrets` | history/sourceともに0件。秘密値は出力しない |
| 既存の`bin/check_secret_files` | Rails復号キーが追跡対象外・ignore済み |
| Markdownのローカル参照先 | 全参照先が存在 |
| 画像 | PNG/JPEG計26ファイルのシグネチャ正常 |
| 静的HTML | ID重複なし、labelの参照先あり、外部src/hrefなし |
| JSON | 構文正常 |
| `git diff --cached --check` | 空白エラーなし |

この公開作業ではブラウザ操作を再実行していない。以前の操作確認は[部品見本の確認記録](component-specimens/verification.md)を参照。
実機・支援技術・Rails統合後の確認は[後続への引継ぎ](completion-checklist.md)に記録した。
GitHub上のCI・公開・マージの実績は、#129と対応PRの記録を正とする。
