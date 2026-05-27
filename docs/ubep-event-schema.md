# UBEP Event Schema

## 1. 文档定位

- 状态：Draft v0.1
- 目标：为 `UBEP`（`Uya Build Event Protocol`）定义稳定事件 envelope、事件类型和生命周期顺序
- 对应 TODO：`docs/uyabuild-todo.md` `P5-1`

本文件只定义 schema 契约，不要求当前实现已经发出全部事件。

## 2. 设计原则

- 事件流优先服务 CLI、CI、IDE 和历史分析，不要求消费方解析控制台文本。
- 首发以 `ndjson` 为权威流格式，`json` 视图由同一事件对象聚合得到。
- 事件字段采用“稳定核心 + 可追加 payload”模式：已有字段不可重命名或变更含义，只允许追加新字段。
- 事件生命周期按单次构建 run 有序递增；消费方可按 `seq` 重建顺序。

## 3. 通用 Envelope

每条 UBEP 事件都共享如下顶层字段：

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `version` | `number` | 是 | schema 版本，MVP 固定为 `1` |
| `event` | `string` | 是 | 事件类型名 |
| `run_id` | `string` | 是 | 对应 `.uya-build/runs/<run-id>/` |
| `seq` | `number` | 是 | 当前 run 内单调递增序号，从 `1` 开始 |
| `phase` | `number` | 是 | 当前命令进入的实现阶段号，例如 `2`/`3` |
| `workspace` | `string` | 是 | `workspace.name` |
| `subcommand` | `string` | 是 | `build` / `test` / `plan` / `why` 等 |
| `timestamp_ms` | `number` | 是 | 事件产生时的 Unix 毫秒时间戳 |
| `payload` | `object` | 是 | 事件特有字段集合 |

兼容性规则：

- 顶层 envelope 字段在 `version = 1` 内保持稳定。
- `payload` 允许只追加字段，不删除已有字段。
- 事件消费者必须忽略未知字段。

## 4. 事件类型

MVP 事件集合固定为以下类型。

### 4.1 `BuildStarted`

表示一次构建 run 已创建，参数解析和 workspace 发现已经完成。

`payload` 必填字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `requested` | `string[]` | 用户显式请求的目标表达式 |
| `matched` | `string[]` | 解析后的目标标签集合 |
| `state_dir` | `string` | 当前 `.uya-build` 根目录 |

### 4.2 `WorkspaceLoaded`

表示 `uya.build` / `uya.toml` 已加载并完成基础分析。

`payload` 必填字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `root` | `string` | workspace 根目录 |
| `entrypoint` | `string` | 根 `uya.build` 相对路径 |
| `files` | `string[]` | 本次分析加载的构建文件列表 |
| `strict` | `boolean` | `workspace.strict` 当前值 |

### 4.3 `TargetConfigured`

表示某个 target 已完成 schema 校验、label 规范化和 provider 归属。

`payload` 必填字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `label` | `string` | 目标标签 |
| `kind` | `string` | 规则种类 |
| `package` | `string` | package 路径 |
| `providers` | `string[]` | 对外暴露的 provider 名称 |

### 4.4 `ActionPlanned`

表示 planner 已生成一个 action，并完成输入输出契约与 action key 计算。

`payload` 必填字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `label` | `string` | owner target 标签 |
| `kind` | `string` | action 对应规则种类 |
| `action_key` | `string` | 计算后的动作键 |
| `pool` | `string` | 资源池名 |
| `execution_mode` | `string` | `pure` / `host` / `volatile` |
| `inputs` | `string[]` | 声明输入路径集合 |
| `outputs` | `string[]` | 声明输出路径集合 |
| `deps` | `string[]` | 上游 action 所属标签集合 |

### 4.5 `ActionCacheChecked`

表示 action 已完成本地缓存/种子输出/预执行复用判断。

`payload` 必填字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `action_key` | `string` | 动作键 |
| `status` | `string` | `local-hit` / `seeded-output` / `success-no-change` / `pending-execution` |
| `input_root_digest` | `string` | 当前输入摘要 |
| `output_root_digest` | `string \| null` | 当前工作区里已观察到的输出摘要 |

### 4.6 `ActionScheduled`

表示 action 已进入调度器，等待执行或已被判定为可复用。

`payload` 必填字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `action_key` | `string` | 动作键 |
| `status` | `string` | 当前调度状态 |
| `order` | `number` | action 在 DAG 中的拓扑顺序 |

### 4.7 `ActionStarted`

表示 action 已真正开始执行。

`payload` 必填字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `action_key` | `string` | 动作键 |
| `label` | `string` | owner target 标签 |
| `command` | `string[]` | 命令行 |
| `action_root` | `string` | 临时工作目录 |

### 4.8 `ActionFinished`

表示 action 执行结束，不论成功失败。

`payload` 必填字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `action_key` | `string` | 动作键 |
| `status` | `string` | `executed-local` / `execution-failed` / 其他最终状态 |
| `exit_code` | `number` | 进程退出码 |
| `stdout_digest` | `string \| null` | `stdout` CAS digest |
| `stderr_digest` | `string \| null` | `stderr` CAS digest |
| `tracked_reads` | `string[]` | 追踪到的读路径 |
| `tracked_writes` | `string[]` | 追踪到的写路径 |
| `hidden_inputs` | `string[]` | 隐藏输入 |
| `undeclared_outputs` | `string[]` | 未声明输出 |

### 4.9 `ActionWarning`

表示执行未失败，但有需要消费方展示的兼容/严格模式告警。

`payload` 必填字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `action_key` | `string` | 动作键 |
| `code` | `string` | 稳定告警码 |
| `message` | `string` | 人类可读描述 |
| `detail` | `string` | 额外上下文 |

### 4.10 `TargetCompleted`

表示某个用户可见 target 已得出最终结果。

`payload` 必填字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `label` | `string` | 目标标签 |
| `status` | `string` | 最终状态 |
| `artifacts` | `string[]` | 产物路径集合 |

### 4.11 `BuildMetrics`

表示当前 run 的聚合统计。

`payload` 必填字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `actions` | `number` | action 总数 |
| `cache_hits` | `number` | `local-hit` 数量 |
| `seeded` | `number` | `seeded-output` 数量 |
| `no_change` | `number` | `success-no-change` 数量 |
| `pending` | `number` | 仍待执行数量 |

### 4.12 `BuildFinished`

表示 run 结束。

`payload` 必填字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `status` | `string` | `ok` / `failed` |
| `root_digest` | `string` | 本次构建/规划的根摘要 |
| `diagnostic_code` | `string \| null` | 顶层失败诊断码 |
| `diagnostic_message` | `string \| null` | 顶层失败信息 |

## 5. 生命周期顺序

单次 `build` / `test` run 的标准顺序固定为：

1. `BuildStarted`
2. `WorkspaceLoaded`
3. `TargetConfigured` `*`
4. `ActionPlanned` `*`
5. `ActionCacheChecked` `*`
6. `ActionScheduled` `*`
7. `ActionStarted` `*`
8. `ActionWarning` `*`
9. `ActionFinished` `*`
10. `TargetCompleted` `*`
11. `BuildMetrics`
12. `BuildFinished`

说明：

- `*` 表示该事件可以出现零次到多次。
- 若 action 被 `local-hit` / `seeded-output` / `success-no-change` 直接复用，则它必须至少发出 `ActionPlanned`、`ActionCacheChecked`、`ActionScheduled`，但不会发出 `ActionStarted` / `ActionFinished`。
- 若 build 在分析期失败，可在 `WorkspaceLoaded` 之前结束，但仍必须发出 `BuildFinished`。

## 6. 输出格式

`ndjson` 是权威顺序流：

- 每行一个完整事件对象
- 按 `seq` 严格递增输出
- 适合 CLI 流式消费与 CI 日志收集

`json` 是聚合视图：

- `events` 字段保存完整事件数组
- `summary` 字段保存 `BuildMetrics` 与最终诊断

## 7. 当前实现映射

当前仓库（2026-05-27）的落盘实现还处于 Phase 5 之前的过渡态：

- `meta/events/<run-id>` 已落盘为 line-delimited JSON
- 已有事件子集：`BuildPlanned`、`ActionPlanned`
- 事件 payload 已复用 `run_id`、`root_digest`、`action_key`、`label`、`status` 等字段

后续 `P5-2` / `P5-3` 的目标是把现有过渡事件对齐到本文件定义的 UBEP schema，并补齐 `BuildStarted/ActionStarted/ActionFinished/BuildFinished` 生命周期。
