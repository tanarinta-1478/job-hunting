# 就活タスク管理アプリ

Gmailの就活メールから企業情報・タスクを取り込んで管理する、サーバー不要の単一HTMLアプリ。
`index.html` をブラウザで直接開くだけで動作する（Node.js・ビルド不要）。

## セットアップ

```sh
# 1. 認証情報を含むデータファイルをテンプレートから作成
copy sync-data.example.js sync-data.js      # Windows
# cp sync-data.example.js sync-data.js       # macOS/Linux

# 2. index.html をブラウザで開く
```

その後、Claude Code に「Gmail同期して」と伝えると、就活メールを読み取って
`sync-data.js` を更新する。ブラウザで F5（再読み込み）すると取り込まれる。

## ファイル構成と公開可否

| ファイル | 内容 | Git |
|---|---|---|
| `index.html` | アプリ本体（汎用コード、個人情報なし） | ✅ コミットOK |
| `sync-data.example.js` | データファイルのダミーテンプレート | ✅ コミットOK |
| `.gitignore` | 除外設定 | ✅ コミットOK |
| `README.md` | 本ファイル | ✅ コミットOK |
| **`sync-data.js`** | **実データ（就活マイページのID/パスワード、テストセンターID、応募企業一覧等の個人情報・認証情報を含む）** | ❌ **コミット禁止**（`.gitignore`で除外済み） |

## セキュリティ方針

- **認証情報・個人データは `sync-data.js` に隔離**し、`.gitignore` でリポジトリから除外する。
- リポジトリに置くのは `sync-data.example.js`（ダミー値のみ）。
- `index.html` は認証情報を持たず、`<script src="sync-data.js">` で外部データファイルを読み込む。
  `sync-data.js` が存在しなくてもアプリは空の状態で正常に起動する。
- `notes` 欄にマイページのID/パスワード等を書かない運用を推奨（必要時は各社マイページで直接確認）。

## データの保存先

企業・タスク・ストーリー等の状態はブラウザの `localStorage` に保存される
（`shukatsu_v2` ほか）。`sync-data.js` はあくまで「Gmailからの取り込み用ブリッジ」。
