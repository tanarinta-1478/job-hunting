# 就活タスク管理アプリ — 作業ガイド

サーバー不要の単一HTMLアプリ。`index.html` をブラウザで直接開くだけで動く（Node.js・ビルド・テストなし）。
Gmailの就活メールを読み取って `sync-data.js` に書き出し、ブラウザ側で取り込む。

## ファイル構成

| ファイル | 役割 | Git |
|---|---|---|
| `index.html` | アプリ本体（約110KB・バニラJS） | ✅ コミットOK |
| `sync-data.js` | Gmail→アプリのデータブリッジ。**個人情報を含む** | ❌ `.gitignore`で除外済み。絶対にコミットしない |
| `sync-data.example.js` | スキーマを示すダミーテンプレート | ✅ コミットOK |

データの本体はブラウザの `localStorage`（`shukatsu_v2` ほか）に入る。`sync-data.js` は取り込み用の橋渡しでしかない。

## 「Gmail同期して」と言われたときの手順

1. Gmailツールを読み込む（MCPが切断されていることがあるので毎回確認）
   `ToolSearch` で `select:mcp__claude_ai_Gmail__search_threads,mcp__claude_ai_Gmail__get_thread`
2. `label:就活` を前回同期日以降で検索する（例：`label:就活 after:2026/09/07`）。
   1ページ50件が上限なので、`nextPageToken` で前回同期日に到達するまで遡る。
3. 合否・締切・イベントを抽出する。メール本文に合否が書かれず「マイページを確認」とだけ書かれている場合は、
   **勝手に合格・不合格と判断せず、本人に確認を促すタスクを立てる**。
4. `sync-data.js` の `window.gmailSyncData = [` の直後に、新しいセクションを**先頭に**差し込む（新しい順に並べる）。
5. `index.html` をブラウザで開く（`Start-Process`）。ユーザーがF5を押して取り込む。
6. 締切と優先度をまとめて日本語で報告する。

### 編集方法

ファイルが大きい（120KB超）ので、全体を書き直さずに先頭へ差し込む。
差し込むブロックはスクラッチパッドにファイルとして書き出してから `awk` で挿入するのが安全
（シェルのヒアドキュメントは日本語や絵文字で壊れることがある）。

```bash
awk 'NR==FNR{buf=buf $0 ORS; next} $0=="window.gmailSyncData = [" {printf "%s", buf; found=1; next} {print} END{if(!found) exit 3}' 新ブロック.txt sync-data.js > tmp.js && cp tmp.js sync-data.js
```

編集後は必ず括弧の対応を確認する（Node.jsが無いので構文チェックはこれで代用）。

```bash
awk '{n=gsub(/{/,"{"); m=gsub(/}/,"}"); o+=n-m} END{print "brace:",o}' sync-data.js   # 0になること
awk '{n=gsub(/\[/,"["); m=gsub(/\]/,"]"); o+=n-m} END{print "bracket:",o}' sync-data.js # 0になること
```

## sync-data.js のスキーマ

```js
// 受けない企業。localStorageからも削除され、再追加されない
window.gmailSyncPurge = ["メールID", ...];

window.gmailSyncData = [
  // 新規企業
  { "emailSourceId": "メールID", "name": "...", "industry": "...", "status": "...",
    "deadline": "YYYY-MM-DD", "priority": 1, "notes": "...", "tasks": [{ "title": "...", "deadline": "" }] },

  // 既存企業の更新（nameは既存エントリーと完全一致させる）
  { "emailSourceId": "メールID", "_mergeWith": { "name": "..." }, "status": "...", "notes": "...", "tasks": [] },
];
```

- `emailSourceId` は重複取込を防ぐキー。本人申告による訂正など、メールが無い場合は `fix_<会社>_<内容>_<日付>` の形で一意な文字列を作る。
- `passExcluded: true` … 選考免除の招待参加を「合格実績」から除外する。
- `_forceStatus: true` … 通常はステータスを前進させることしかできないが、本人申告による訂正で巻き戻したいときだけ使う。

## ステータス

```
気になる → 未応募 → ES提出済 → 書類選考中 → 一次面接 → 二次面接 → 最終面接
        → インターン合格 → 内定 → 合格辞退 → 不合格 → 辞退
```

- 終端ステータス：`内定` `合格辞退` `不合格` `辞退`
- Gmail同期は**前進のみ**。終端へは常に進めるが、終端からは戻せない（`_forceStatus` を除く）。
- 合格実績としてカウントされるのは `インターン合格` `内定` `合格辞退`（`passExcluded` が立っていないもの）。
- `インターン合格` はインターン・仕事体験の選考通過。**内定と混同しない。**

## 運用ルール

- **認証情報は絶対に記録しない。** メールにマイページのID・パスワード・テストセンターID・
  適性検査のオーダー番号が平文で書かれていることがあるが、`notes` に書かず「マイページで確認」とだけ残す。
- **不合格企業のイベント案内も取り込む**（本選考リベンジのため）。ただし `gmailSyncPurge` の企業は除く。
- 合否が不明なときは推測しない。確認タスクを立てて本人に聞く。
- `sync-data.js` をコミットしない。リポジトリはGitHubに公開されている。
