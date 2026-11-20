#!/usr/bin/env bash
# 初期の配置物: cc-sdd-bootstrap（installer-core）が各プロジェクトに置く、cc-sdd を固定版で導入するスクリプト。
# SessionStart のフックがこのスクリプトを呼ぶ。この動きは session-install の spec が引き継ぎ、一般化する。
#
# 使い方: .agent-hooks/cc-sdd-bootstrap/install-cc-sdd.sh --claude
#
# 導入するもの（いずれも cc-sdd の成果物で MIT。本リポジトリとはライセンスが異なるため .gitignore の対象でコミットしない）
#   - スキル: .claude/skills/kiro-*/
#   - 設定の雛形: .kiro/settings/templates/
#   - 標準の決まりの文書: .kiro/settings/cc-sdd-guide.md（CLAUDE.md から @ で取り込む。CLAUDE.md 自体は書き換えない）
# 版はこのファイルの CC_SDD_VERSION だけに書く。上げるときは版を変え、導入物を入れ直して動作を確かめる。
#
# 失敗の記録: 導入の前に .cache/cc-sdd-install.failed を書き、成功したら消す（SessionStart は止められないため、
# 次の UserPromptSubmit のフック（install-gate.mjs）が、記録を見てプロンプトを止める）。
set -euo pipefail

# 導入の版（3.1.0 に固定。@latest にすると導入のたびに導入物が変わる）
CC_SDD_VERSION="3.1.0"

if [ "${1:-}" != "--claude" ] || [ "$#" -ne 1 ]; then
  echo "使い方: .agent-hooks/cc-sdd-bootstrap/install-cc-sdd.sh --claude" >&2
  exit 2
fi

# 呼び出し元のカレントに依らず、リポジトリのルートで導入する
cd "$(dirname "$0")/../.."

failure_record=".cache/cc-sdd-install.failed"

# 導入対象の一覧。cc-sdd の既定の一覧から、文書（doc_main）の出力先だけを CLAUDE.md から .kiro/settings/cc-sdd-guide.md に変える
manifest="$(mktemp)"
trap 'rm -f "$manifest"' EXIT
cat > "$manifest" << 'JSON'
{
  "version": 1,
  "artifacts": [
    {
      "id": "skills",
      "source": { "type": "templateDir", "fromDir": "templates/agents/{{AGENT}}/skills", "toDir": "{{AGENT_COMMANDS_DIR}}" }
    },
    {
      "id": "doc_main",
      "source": { "type": "templateFile", "from": "templates/agents/{{AGENT}}/docs/CLAUDE.md", "toDir": "{{KIRO_DIR}}/settings", "rename": "cc-sdd-guide.md" }
    },
    {
      "id": "settings_templates",
      "source": { "type": "templateDir", "fromDir": "templates/shared/settings/templates", "toDir": "{{KIRO_DIR}}/settings/templates" }
    }
  ]
}
JSON

# 導入の前に記録を書く。完了したら消す。途中で中断（時間切れなど）されても、記録が残って次の入力で止まる
mkdir -p .cache
printf '%s\n' "cc-sdd の導入が完了していません（導入中、または中断）。" > "$failure_record"
# 導入物は固定版で入れ直す（既存のファイルも上書きする）。cc-sdd の出力はセッションに入れないよう標準エラーへ回す
if npx --yes "cc-sdd@${CC_SDD_VERSION}" --yes --overwrite force --manifest "$manifest" --claude-skills --lang ja >&2; then
  rm -f "$failure_record"
  # SessionStart の標準出力はセッションのコンテキストに入る。導入直後のセッションでは、新しいスキルがスキル一覧に
  # 現れないことがある（一覧は起動時に読まれるため）。その場合に SKILL.md を直接読めるよう案内する
  echo "cc-sdd ${CC_SDD_VERSION} の導入物を更新しました（.claude/skills/kiro-*・.kiro/settings/）。CLAUDE.md は変更していません。"
  echo "スキル一覧に載らないスキル（kiro-discovery・kiro-impl など）は、依頼に対応する .claude/skills/<名前>/SKILL.md を Read して、その手順を最後まで実行してください。"
else
  status=$?
  printf '%s\n' "cc-sdd の導入に失敗しました（終了コード ${status}）。再試行: .agent-hooks/cc-sdd-bootstrap/install-cc-sdd.sh --claude" > "$failure_record"
  echo "cc-sdd の導入に失敗しました（終了コード ${status}）。次の入力からプロンプトが止まります。再試行: .agent-hooks/cc-sdd-bootstrap/install-cc-sdd.sh --claude" >&2
  exit "$status"
fi
