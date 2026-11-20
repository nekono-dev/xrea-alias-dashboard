# Project Structure

## Organization Philosophy

`src/` はサービス・責務単位の分割。HTTP 層（ルートの組み立て）と業務処理を分け、実行環境（Node.js / Workers）で変わる部分は入口と環境依存モジュールに閉じ込める。新しいコードは既存の責務分割に沿って置く。

## Directory Patterns

### サービス・責務単位のモジュール
**Location**: `/src/`（`app`・`credentials`・`gateway`・`reader`・`shared`・`xrea`）
**Purpose**: `app` は API の組み立て・設定・静的配信と環境別の入口、`credentials` は認証情報の暗号化と保存方式、`gateway` は XREA 操作の業務処理と要求直列化、`reader` は Proton Pass の読み取り、`shared` は共通エラー・ログ・内部通信認証、`xrea` は XREA API の型付きクライアント
**Example**: 認証情報の保存方式を足すなら `src/credentials/` に置き、`app` 側は組み立てだけを変更する

### 画面（Preact アプリ）
**Location**: `/web/`
**Purpose**: `components/` に UI 部品、`sw/` に Service Worker、`public/` に PWA 宣言・アイコン。状態管理は `web/src/store.ts` の独自ストア
**Example**: 一覧の部品は `components/AliasList.tsx` のように機能名で置く

### XREA API の仕様資料
**Location**: `/api/`
**Purpose**: アプリの実装ではなく、公式ドキュメントのスナップショット・補正定義（`overlay.yaml`）・生成した OpenAPI を保持する。クライアント型はここから生成する
**Example**: API の仕様変更は `scripts/xrea-docs/` の取得・生成手順で `api/` と `src/xrea/generated/` を更新する

### 運用スクリプトと手順書
**Location**: `/scripts/`・`/docs/`・`/config/`
**Purpose**: `scripts/` は開発起動、クラウド配備・撤去・疎通確認、ドキュメント生成、アイコン生成。`docs/` は配備と運用の手順書。`config/` は XREA サーバ一覧などの運用設定
**Example**: 配備手順を変えたら `scripts/cloud/` と `docs/cloud-deploy.md` をセットで直す

### テスト
**Location**: `/tests/`
**Purpose**: 概ね `src/` の責務分割に対応させる。追加で cloud・Docker・E2E を置く
**Example**: ゲートウェイの単体テストは対応する責務のディレクトリに置く

## Naming Conventions

- **Files**: UI コンポーネントは PascalCase + `.tsx`（`AliasList.tsx`）、一般モジュールは camelCase + `.ts`（`gatewayClient.ts`）
- **役割を示すファイル名**: `config.ts`・`service.ts`・`routes.ts`・`client.ts` のように、置き場所と役割で名前を決める
- **実行環境別の実装**: `node.ts` / `worker.ts`、`nodeResolver.ts` / `dohResolver.ts` のように環境名を付けて並べる
- **テスト**: 単体・結合は `.test.ts(x)`、E2E は `.spec.ts`、実機用は `.live.test.ts`

## Import Organization

```typescript
import { Something } from './local'        // 同一責務内は相対パス
import { Other } from '../shared/errors'   // 責務をまたぐ場合は src からの相対パス
```

**Path Aliases**:
- 画面（`web/`）のビルドは Vite の解決に従う。`src/` 側は相対パスを基本とし、生成型は `src/xrea/generated/` から取り込む

## Code Organization Principles

- HTTP 層と業務処理を分離する（ルートは `routes.ts`、処理は `service.ts` 側）
- 環境差は入口と差し替え可能な依存（fetcher・resolver・保存先）で吸収し、業務処理に環境分岐を持ち込まない
- 秘密値と認証情報は、リポジトリ・ログ・シェル履歴に残さない形で扱う（手順書の流儀を守る）

---
_Focus on patterns and principles, not exhaustive directory listings_
