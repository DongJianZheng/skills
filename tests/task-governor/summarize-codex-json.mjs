#!/usr/bin/env node

import fs from "node:fs";

const [logPath, label, elapsed] = process.argv.slice(2);
if (!logPath || !label || elapsed === undefined) {
  console.error("用法: summarize-codex-json.mjs <jsonl> <标签> <耗时秒数>");
  process.exit(2);
}

const events = fs.readFileSync(logPath, "utf8")
  .split("\n")
  .filter(Boolean)
  .map((line) => JSON.parse(line));

const items = events
  .filter((event) => event.type === "item.completed")
  .map((event) => event.item);
const commands = items.filter((item) => item?.type === "command_execution");
const messages = items.filter((item) => item?.type === "agent_message");
const completed = [...events].reverse().find((event) => event.type === "turn.completed");
const usage = completed?.usage ?? {};
const totalTokens = (usage.input_tokens ?? 0) + (usage.output_tokens ?? 0);
const commandOutputChars = commands.reduce(
  (total, item) => total + String(item.aggregated_output ?? item.output ?? "").length,
  0,
);
const conclusion = String(messages.at(-1)?.text ?? "未取得最终结论")
  .replace(/\s+/g, " ")
  .trim()
  .slice(0, 300);

console.log(`\n===== ${label} =====`);
console.log(`耗时: ${elapsed}s`);
console.log(`命令次数: ${commands.length}`);
console.log(`命令输出字符: ${commandOutputChars}`);
console.log(`Token: ${totalTokens}（输入 ${usage.input_tokens ?? 0} / 输出 ${usage.output_tokens ?? 0}）`);
console.log(`结论摘要: ${conclusion}`);
