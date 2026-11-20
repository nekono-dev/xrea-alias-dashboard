#!/usr/bin/env node
/**
 * 初期の配置物: cc-sdd-bootstrap（installer-core）が各プロジェクトに置く、導入の失敗の記録を見てプロンプトを止める
 * フック（UserPromptSubmit）。この動きは session-install の spec が引き継ぎ、一般化する。
 *
 * 理由: SessionStart は終了コードで止められない（Claude Code の仕様）。止められるのは UserPromptSubmit。
 * 記録は導入スクリプト（install-cc-sdd.sh）が書き、成功したら消す。
 *
 * 使い方: node .agent-hooks/cc-sdd-bootstrap/install-gate.mjs user-prompt-submit
 * 判定は標準出力の JSON（decision: "block"）で返す。
 *
 * 失敗時の方針: 例外は標準エラーに出し、終了 0 にする（記録の判定ができないときに作業を止めない）。
 */
import fs from "node:fs"
import path from "node:path"
import { fileURLToPath } from "node:url"

const scriptDir = path.dirname(fileURLToPath(import.meta.url))
export const repoRoot = path.resolve(scriptDir, "../..")

/** 導入の失敗の記録と、再試行の方法。 */
export const installFailures = [
  {
    name: "cc-sdd",
    record: ".cache/cc-sdd-install.failed",
    retry: ".agent-hooks/cc-sdd-bootstrap/install-cc-sdd.sh --claude",
  },
]

/** 記録のあるものだけを返す。 */
export const pendingInstallFailures = root =>
  installFailures.filter(failure => fs.existsSync(path.join(root, failure.record)))

/** 利用者に示す理由（再試行の方法を含む）。 */
export const installBlockReason = failures =>
  [
    "導入が完了していないため（失敗・中断を含む）、プロンプトを止めています。新しいセッションを開くと、導入が再試行されます。すぐに直す場合は、Claude の外（通常のターミナル）で次のコマンドを実行してください。成功してから、もう一度入力してください。",
    ...failures.map(failure => `- ${failure.name}: ${failure.retry}（記録: ${failure.record}）`),
  ].join("\n")

/** UserPromptSubmit の判定。記録が無ければ null（何もしない）。 */
export const decideUserPromptSubmit = root => {
  const failures = pendingInstallFailures(root)
  if (failures.length === 0) return null
  return {
    hookSpecificOutput: {
      hookEventName: "UserPromptSubmit",
      // 表示からプロンプトの本文を外す（会話の記録からは外れない）
      suppressOriginalPrompt: true,
    },
    decision: "block",
    reason: installBlockReason(failures),
  }
}

const main = () => {
  const event = process.argv[2]
  if (event !== "user-prompt-submit") throw new Error(`未知のイベント: ${event}`)
  const output = decideUserPromptSubmit(repoRoot)
  if (output) process.stdout.write(`${JSON.stringify(output)}\n`)
}

const isDirectRun =
  process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)
if (isDirectRun) {
  try {
    main()
  } catch (error) {
    // 判定できないときは通す（作業を止めない）
    process.stderr.write(`install-gate: ${error instanceof Error ? error.message : String(error)}\n`)
    process.exit(0)
  }
}
