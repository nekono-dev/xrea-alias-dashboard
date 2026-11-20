# Product Overview

XREA Alias Dashboard は、XREA のメール転送アドレス（エイリアス）をワンボタンで発行・管理する Web アプリ。発行したアドレスは指定のメールボックスへ転送される。複数の利用者が、それぞれ自分の XREA アカウントで使う前提で、認証情報はサーバに保存せず利用者ごとに画面から登録する。

## Core Capabilities

- エイリアスの発行・一覧・転送先変更・削除（名前を空にすると `quiet.river42` 形式のランダム名を生成）
- XREA にメールボックスを持つアドレスの一覧表示（コピーのみ、変更・削除は不可）
- 任意の Proton Pass 連携: 読み取り専用トークンで全 Vault を参照し、各アドレスがどのサービスで使われているか（エントリ名）を一覧に表示する。書き込みは行わない
- PWA 対応: ホーム画面に追加してアプリとして使える。端末に保存するのは画面ファイルだけで、API の応答は保存しない

## Target Use Cases

- 個人・小規模チームが、サービス登録用の使い分けアドレスを XREA で量産・管理する
- セルフホスト（Docker）と Cloudflare Workers のどちらでも同じ構成で動かす

## Value Proposition

- **認証情報をサーバに持たない**: 暗号化した cookie（HttpOnly・SameSite=Strict・7日で期限切れ）に保持するのが標準方式。セルフホストでは SQLite 保存方式も選べる。Proton Pass のパスワードは通信にもログにも載せない
- **配備形態を選ばない**: app（ゲートウェイ内蔵）と任意の proton-reader という構成が、クラウドでもセルフホストでも共通
- **XREA の制限に沿った安全な操作**: ゲートウェイがアカウントごとに要求を直列化し、1秒間隔の制限を守る

---
_Focus on patterns and purpose, not exhaustive feature lists_
