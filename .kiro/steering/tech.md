# Technology Stack

## Architecture

ブラウザ → app（画面配信・HTTP API・XREA ゲートウェイ内蔵）→ XREA API という構成。任意で proton-reader（Proton Pass の読み取り専用サービス）を併設する。app は Cloudflare Workers と Node.js コンテナの両方で動く同一コードベースで、入口だけを実行環境ごとに分ける。ゲートウェイはアカウント単位で要求を直列化する（Workers では Durable Object、Node.js では同一プロセス）。

## Core Technologies

- **Language**: TypeScript 5.9（バックエンド・画面・スクリプト・テストの共通言語、ES Modules）
- **Framework**: Hono 4（HTTP API。Node.js と Workers で共通）、Preact 11（画面。独自 UI コンポーネントのみで構成）
- **Runtime**: Node.js 22 以上 / Cloudflare Workers

## Key Libraries

- `@hono/node-server`: Hono アプリを Node.js の HTTP サーバとして実行
- `esbuild`: app・reader・Worker のバンドル。`vite`（Preact プラグイン）: 画面の開発サーバと本番ビルド
- `openapi-typescript`: XREA の OpenAPI 定義からクライアント型を生成
- `tsx`: 開発・配備・ドキュメント生成などの TypeScript スクリプト実行
- 実行時依存は Hono・Node サーバアダプタ・Preact の3つに絞る。画面の状態管理も独自ストアと hooks で行い、外部の状態管理ライブラリは入れない

## Development Standards

### Type Safety
- `strict` と `noUncheckedIndexedAccess` を有効化。`tsc` は型検査専用（出力なし）

### Code Quality
- Prettier で整形。コメントと文書は日本語で書く

### Testing
- 単体・結合: Vitest（`tests/` を責務別に分割。UI は Testing Library / happy-dom、Workers と Durable Object は Miniflare）
- ブラウザ E2E: Playwright（通常は API をモック。実環境用は別設定）
- 実機テスト（`.live.test.ts`）は通常除外し、`XREA_LIVE` / `DOCKER_LIVE` で有効化する

## Development Environment

### Required Tools
- Node.js 22 以上、Docker（セルフホスト配備とイメージ生成用）

### Common Commands
```bash
# Dev: npm run dev
# Build: npm run build（dist/app・dist/reader・dist/worker・dist/web を生成）
# Test: npm test / npm run typecheck / npx playwright test
```

## Key Technical Decisions

- **認証情報はサーバに保存しない**: 標準は暗号化 cookie 方式。セルフホスト向けに SQLite 方式（`CREDENTIAL_STORE=sqlite`）も選べるが、Workers では cookie 方式のみ
- **実行環境別の入口分離**: `node.ts` / `worker.ts` のように入口と環境依存の実装を分け、Workers 側は `node:` モジュールに依存しない
- **依存は引数で渡す**: fetcher・DNS resolver・保存先などを差し替え可能にし、環境差への対応とテストを容易にする
- **生成物の隔離**: XREA クライアントの生成型は `src/xrea/generated/`、ビルド成果物は `dist/` に閉じ込める
- **proton-reader は最大1インスタンス**: Proton Pass のセッション競合を避けるため。失われても次の要求で自動的に再ログインする

---
_Focus on patterns and decisions, not exhaustive dependency lists_
