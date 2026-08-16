# Codex Skills

这个仓库收录可以直接复用的 Codex Skills。当前提供 `task-governor`：让 Codex 按任务清单推进，减少无效读取、重复测试、计划外扩展和不可靠的完成声明。

## task-governor 是什么

`task-governor` 不会让模型凭空变聪明，也不承诺固定节省多少 Token。它解决的是执行过程中的浪费：

- 先读任务清单，只查看相关文件，缺信息再扩大范围；
- 优先完成约 80% 的核心路径，不顺手增加计划外功能；
- 先做一条能推翻主结论的关键检查，有风险再追加测试；
- 用真实实现核对进度，未验证内容必须明确标注；
- 高风险删除、凭据、生产操作和外部发布必须先确认。

适合有 PRD、Issue、实施计划或任务清单的中长任务。简单问答、格式转换和一次性单文件修改通常没有必要调用。

## 安装

```bash
git clone https://github.com/DongJianZheng/skills.git
mkdir -p ~/.codex/skills
cp -R skills/task-governor ~/.codex/skills/
```

按照 [OpenAI 官方 Skills 用例](https://learn.chatgpt.com/use-cases/reusable-codex-skills) 的说明，放在 `~/.codex/skills` 下的 Skill 可以在不同仓库中使用；项目内的 Skill 也可以随仓库提交，供团队复用。

## 使用

在 Codex 桌面端或 CLI 的任务中直接写：

```text
使用 $task-governor，以 docs/workflow-plan.html 为任务清单。
优先完成 80% 核心路径，保持输出精简，只做关键测试。
```

需要并行时必须明确授权，例如：

```text
允许最多 3 路安全并行；子任务不得修改同一文件或共享迁移资源。
```

默认交付格式：

```text
模型：<实际模型；不可见时明确说明>；原因：<一句话>
结果：<现在可用或已变更的内容>
变更：<文件或产物>
验证：<关键命令或检查> → <结果>
未验证：<明确边界>
```

## 真实 A/B 测试

2026-08-16 在同一项目、同一任务、同一只读权限和 `gpt-5.6-terra` 下测试：

| 指标 | 未调用 Skill | 调用 task-governor |
|---|---:|---:|
| 耗时 | 54 秒 | 43 秒 |
| 命令次数 | 5 | 4 |
| 命令输出字符 | 339,927 | 163,688 |
| Token | 239,453 | 149,819 |
| 结论 | 引用了不存在的路径 | 定位真实源码，复核正确 |

这是一组真实任务结果，不是通用基准。它不能证明所有任务都能节省 37%，只能说明在该次跨文件核验中，读取范围、消耗和结论质量都得到改善。

### 在自己的项目复跑

依赖：Codex CLI、Node.js 18+、zsh，并且已经安装 `task-governor`。

```bash
./tests/task-governor/ab-test.sh \
  /绝对路径/项目目录 \
  /绝对路径/任务清单.md \
  "判断计划中的第一阶段是否已经完整实现，并给出代码证据"
```

如需固定模型：

```bash
TASK_GOVERNOR_MODEL=gpt-5.6-terra \
  ./tests/task-governor/ab-test.sh /项目目录 /任务清单.md "核验任务"
```

脚本顺序执行两次只读 `codex exec --json`，唯一提示差异是第二组调用 `$task-governor`；随后汇总耗时、命令次数、命令输出字符、Token 和结论摘要。临时原始日志在结束时删除，不会修改被测项目。

## 仓库结构

```text
.
├── README.md
├── task-governor/
│   ├── SKILL.md
│   └── agents/openai.yaml
└── tests/task-governor/
    ├── ab-test.sh
    └── summarize-codex-json.mjs
```

Skill 本体只保留 Codex 执行时需要的内容；面向用户的说明和评测脚本放在 Skill 目录之外，避免增加每次调用的上下文。
