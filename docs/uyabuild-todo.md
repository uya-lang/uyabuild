# UyaBuild 实施 TODO

## 1. 文档定位

- 文档状态：Draft v0.1
- 对应设计：[uyabuild-detailed-design.md](./uyabuild-detailed-design.md)
- 目标：把 `UyaBuild` 从研究结论推进到可自举、可迁移、可在 `uya` 主仓落地的实现计划

本 TODO 文档遵循三个原则：

- 先收口 bootstrap 和核心语义，再扩能力。
- 先保证本地正确性和可解释性，再扩远程缓存与云集成。
- 先让旧系统进入图，再逐步替换成结构化规则。

## 2. 优先级定义

| 级别 | 含义 |
|---|---|
| `P0` | 不完成就无法形成可运行 MVP |
| `P1` | 强烈建议在 MVP 或第一轮试点前完成 |
| `P2` | 可以在默认化后补齐 |

## 3. 阶段总览

| 阶段 | 目标 | 优先级 |
|---|---|---|
| Phase 0 | bootstrap 边界与工程基线 | `P0` |
| Phase 1 | DSL、Parser、Analyzer、Typed IR | `P0` |
| Phase 2 | CAS、Snapshotter、Planner、Meta Store | `P0` |
| Phase 3 | 本地执行器、沙箱、依赖追踪、严格模式 | `P0` |
| Phase 4 | 内建规则包：`cxx`、`node`、`oci`、`legacy.shell` | `P0` |
| Phase 5 | UBEP、`query/aquery/why/replay` | `P1` |
| Phase 6 | Make/CMake/Bazel/npm/Docker 互操作 | `P1` |
| Phase 7 | `uya` 主仓迁移与默认入口切换 | `P0` |
| Phase 8 | 远程缓存、CI、性能回归、大仓试点 | `P2` |

## 4. 全局前置项

- [x] `P0` 明确 `UyaBuild` 在 `uya` 主仓中的模块目录布局。
- [x] `P0` 定义文档、代码、测试、基准的统一命名规范。
- [x] `P0` 建立样例仓集合：
  - 单文件最小 C/C++ 项目
  - Node workspace 项目
  - Docker 多阶段镜像项目
  - `legacy.shell` 兼容样例
- [x] `P0` 建立基准指标采集脚本，用于比较 `null build`、单文件修改、缓存命中率。

## 5. Phase 0：bootstrap 与工程基线

### 5.1 目标

确保 `UyaBuild` 可以在不引入自举循环的前提下启动开发，并为后续性能和正确性验证建立基线。

### 5.2 TODO

当前仓库已完成一套可运行的 Phase 0 基线实现，见 [phase0-engineering-baseline.md](./phase0-engineering-baseline.md)。

| ID | 优先级 | 任务 | 依赖 | 验收标准 |
|---|---|---|---|---|
| `P0-1` | `P0` | 定义 `make bootstrap` 或 `bootstrap.sh` 最小职责边界 | 无 | 仅负责从纯 `uya` 源码生成首个 `bin/uyabuild` |
| `P0-2` | `P0` | 约定 bootstrap 之后所有开发入口统一为 `uyabuild ...` | `P0-1` | 文档与命令帮助文本一致 |
| `P0-3` | `P0` | 搭建 `UyaBuild` 最小 CLI 骨架，支持 `uyabuild build`、`uyabuild query` 命令占位 | `P0-2` | CLI 可解析参数并输出稳定错误 |
| `P0-4` | `P0` | 选定状态目录布局 `.uya-build/` | `P0-3` | 目录结构在设计与实现中一致 |
| `P0-5` | `P1` | 建立 benchmark 样本仓与基线记录 | `P0-3` | 能保存第一次性能基线 |
| `P0-6` | `P1` | 建立 golden test 约定和 fixtures 目录 | `P0-3` | 可运行最小 golden 测试 |

### 5.3 退出条件

- `bootstrap` 边界清晰且不再承载日常开发逻辑。
- `UyaBuild` 有可运行 CLI 主体。
- 样例仓和基准框架已可复用。

## 6. Phase 1：DSL、Parser、Analyzer、Typed IR

### 6.1 目标

把根 `uya.build` 作为主入口解析为稳定的 typed IR，并在分析期消灭隐式行为与 schema 不确定性；同时支持可选 `uya.toml` 兼容导入。

### 6.2 TODO

当前状态（2026-05-26）：

- `P1-8` 已完成：`bin/uyabuild` 的 Phase 1 分析现已支持 `glob()` 展开、`config "..."` 声明驱动的 `select()` 配置展开，以及 `build/query/plan --config <name[,name...]>` 共享入口。
- 已补充配置矩阵样例仓与回归：`fixtures/workspaces/config-matrix/`、`plan-config-matrix-json`、`build-config-matrix`、`plan-unknown-config`，用于验证分支展开和错误诊断。

| ID | 优先级 | 任务 | 依赖 | 验收标准 |
|---|---|---|---|---|
| `P1-1` | `P0` | 定义 `uya.build` 词法与语法规范 | `P0-3` | 文档化 grammar 初稿完成 |
| `P1-2` | `P0` | 实现 AST 节点与源码位置信息 | `P1-1` | 语法错误能指向文件和行列 |
| `P1-3` | `P0` | 实现 `workspace`、`config`、`use`、`include`、目标声明解析 | `P1-2` | 根 `uya.build` 与被包含文件可成功解析 |
| `P1-4` | `P0` | 实现 label 解析与规范化 | `P1-3` | `//pkg:path`、相对标签解析一致 |
| `P1-5` | `P0` | 建立 schema 校验框架 | `P1-3` | 未知字段、类型错误在分析期失败 |
| `P1-6` | `P0` | 定义 Typed IR 数据结构 | `P1-4`, `P1-5` | Parser 输出可稳定转换为 IR |
| `P1-7` | `P1` | 实现单文件模式、分离模式与可选 `uya.toml` 兼容导入 | `P1-3`, `P1-6` | 根 `uya.build` 可独立工作，兼容模式下冲突字段可被检测 |
| `P1-8` | `P1` | 已完成：实现 `glob()`、`select()`、配置展开 | `P1-6` | 样例仓的配置矩阵可展开 |
| `P1-9` | `P1` | 定义 provider 机制和跨规则字段暴露 | `P1-6` | `cxx.library -> cxx.binary` provider 链可表达 |
| `P1-10` | `P1` | 实现错误码和诊断分级 | `P1-5` | 诊断具备稳定 code 与建议文本 |
| `P1-11` | `P1` | 输出 `uya plan --json` 的 IR 快照格式 | `P1-6` | IR 可序列化并用于回归测试 |

### 6.3 退出条件

- 根 `uya.build` 单文件模式可用，`uya.toml` 兼容模式行为清晰。
- schema 校验和 label 解析可靠。
- typed IR 可作为后续 planner 的唯一输入。

## 7. Phase 2：CAS、Snapshotter、Planner、Meta Store

### 7.1 目标

建立内容寻址的最小构建数据面，让系统可以稳定判断“什么变了”和“应该执行什么”。

### 7.2 TODO

当前状态（2026-05-22）：

- `bin/uyabuild` 已进入 Phase 2 主路径：`uyabuild plan --json` 会输出 typed IR + action graph；`uyabuild build` 会执行目标闭包、输入快照、action key 计算、CAS/meta 持久化，并在已有输出时返回 `seeded-output` / `local-hit`。
- bootstrap seed 已完成的主项：`P2-1`、`P2-2`、`P2-4`、`P2-5`、`P2-6`、`P2-7`、`P2-8`、`P2-9`、`P2-10`。
- 已收口的新能力：`uya` 工具链现已提供稳定的 `std.crypto.blake3.blake3_digest`；`bin/uyabuild` 的 snapshot/CAS/action key/index key 已统一切换到 `blake3`；`meta/` 现在会生成 NoSQLite 风格的集合与索引文档；`success-no-change` 已可基于上一版成功输出触发，并让仅依赖未变化输出的下游动作继续保持 `local-hit`；本地执行日志会以专用 CAS 对象写入 `.uya-build/cas/logs/`，并把 `stdout/stderr` digest 记录进动作元数据。

| ID | 优先级 | 状态 | 任务 | 依赖 | 验收标准 |
|---|---|---|---|---|---|
| `P2-1` | `P0` | `已完成` | 实现 `blake3` 摘要与路径规范化工具 | `P1-6` | 文件与目录摘要稳定可复现 |
| `P2-2` | `P0` | `已完成` | 实现 Snapshotter 与目录 Merkle tree | `P2-1` | 目录输入可生成单一 root digest |
| `P2-3` | `P0` | `已完成` | 设计 CAS 对象布局 | `P2-1` | 文件、目录、日志对象可写入 CAS |
| `P2-4` | `P0` | `已完成` | 设计 NoSQLite 集合与索引模型：`build_runs/actions/artifacts/events/cache_entries` | `P2-3` | 可创建元数据集合并完成基本查询 |
| `P2-5` | `P0` | `已完成` | 实现 Typed IR 到 Target Graph 的转换 | `P1-6` | 图中可解析目标依赖关系 |
| `P2-6` | `P0` | `已完成` | 实现 Planner：Target Graph -> Action DAG | `P2-5` | 单目标可规划出动作列表 |
| `P2-7` | `P0` | `已完成` | 实现 action key 计算 | `P2-2`, `P2-6` | 修改输入/命令/环境后键会变化 |
| `P2-8` | `P1` | `已完成` | 实现 early cutoff 所需的输出摘要比较 | `P2-7` | 输出未变化时可标记 no-change |
| `P2-9` | `P1` | `已完成` | 实现基础本地缓存索引 | `P2-4`, `P2-7` | 相同动作可命中本地缓存 |
| `P2-10` | `P1` | `已完成` | 实现 `uya plan --json` 动作图输出 | `P2-6` | 动作图可用于调试和 golden test |

### 7.3 退出条件

- 内容快照、动作键、动作图都已可用。
- NoSQLite 元数据集合与索引结构稳定到足以支持执行和查询。
- 本地缓存索引已具备最小闭环。

当前判断：Phase 2 的 planner/meta/early-cutoff/bootstrap cache 闭环已经形成，`blake3` 后端切换已收口，可继续推进后续执行器与规则包工作。

## 8. Phase 3：执行器、沙箱、依赖追踪、严格模式

### 8.1 目标

让构建动作在受控环境中执行，并能把实际读写依赖记录下来，为严格模式和可观测性打基础。

### 8.2 TODO

当前状态（2026-05-26）：

- `bin/uyabuild build` 已进入 Phase 3 本地执行路径：待执行的 `legacy.shell` / `task` 动作会在私有临时工作区中运行，并把 `stdout` / `stderr` 分离采集到 `.uya-build/tmp/actions/<run-id>/<action-key>/`。
- 已完成的首批闭环：本地 Executor 骨架、动作临时工作区、日志采集、原子输出提交、环境变量白名单、`pure/host/volatile` 执行模式，以及 `executed-local` / `execution-failed` 元数据落盘。
- `execution_mode` 现已生效：`pure` 仅物化声明输入与依赖输出，`host` 会额外物化兼容所需的工作区内容，`volatile` 会跳过本地缓存与 `success-no-change` 复用路径。
- Linux 兼容执行路径现已接入 `strace` 依赖追踪：动作元数据会记录 `tracked_reads` / `tracked_writes`、`hidden_inputs`、`undeclared_outputs`；`workspace.strict = true` 时，隐藏输入和未声明输出会在输出提交前直接失败。
- `uyabuild build --jobs <n>` 现已启用并行调度：`cpu` 池使用作业并发上限，`link` / `docker` / `network` 和其他非 `cpu` 池按池名串行化，`plan --json` / 动作元数据也会显式记录 `pool`。
- Linux 本地执行现已默认关闭宿主网络；只有显式声明 `allow_network = true` 的动作才会跳过 `unshare -Urn` 隔离并使用宿主网络。
- ActionRecord 现已同时写入 `meta/actions/` 与 `.uya-build/cas/action-records/`：`meta/actions/<action-key>` 保留最新快照，`meta/actions/<run-id>-<action-key>` 保留历史记录，索引会指向历史 doc 以支持后续查询。
- `cxx.library` / `cxx.binary` 现已接入最小本地执行路径：执行器会预创建声明输出父目录，`/usr/bin/c++` 在 `pure` 模式下复用宿主工具链完成编译/链接，并允许声明输出目录内的瞬时编译中间文件通过严格模式校验；`node` / `oci` 动作和 macOS 依赖追踪后端仍待后续收口。

| ID | 优先级 | 任务 | 依赖 | 验收标准 |
|---|---|---|---|---|
| `P3-1` | `P0` | 实现本地 Executor 骨架 | `P2-6` | 可执行单个动作并返回状态 |
| `P3-2` | `P0` | 创建动作私有工作目录和输出目录 | `P3-1` | 动作之间工作目录隔离 |
| `P3-3` | `P0` | 实现 stdout/stderr 缓冲采集 | `P3-1` | 并行动作日志不交错 |
| `P3-4` | `P0` | 实现原子输出提交 | `P3-2` | 失败动作不污染正式输出 |
| `P3-5` | `P0` | 实现环境变量白名单机制 | `P3-1` | 未放行变量默认不可见 |
| `P3-6` | `P0` | 已完成：实现 `pure/host/volatile` 执行模式 | `P3-1` | 不同模式的缓存和权限策略生效 |
| `P3-7` | `P0` | 已完成：实现基础依赖追踪接口 | `P3-1` | 动作可记录读写路径 |
| `P3-8` | `P1` | 部分完成：已接入 Linux 依赖追踪实现，macOS 待补 | `P3-7` | 隐藏输入与越权写出可被捕获 |
| `P3-9` | `P0` | 已完成：实现 strict/compat 模式开关 | `P3-7` | 严格模式下隐藏依赖会失败 |
| `P3-10` | `P1` | 已完成：实现资源池与并行调度 | `P3-1`, `P2-6` | `link/docker/network` 池生效 |
| `P3-11` | `P1` | 已完成：实现网络默认关闭策略 | `P3-6` | 未显式声明的动作不可访问网络 |
| `P3-12` | `P1` | 已完成：把 ActionRecord 写入 NoSQLite 和 CAS | `P3-3`, `P2-4` | 可查询历史执行记录 |

### 8.3 退出条件

- 本地动作可在隔离环境中稳定执行。
- 日志、输出、依赖追踪闭环已形成。
- 严格模式与兼容模式行为可验证。

## 9. Phase 4：内建规则包

### 9.1 目标

让 `UyaBuild` 首发就覆盖最关键的三条现代链路：C/C++、Node 前端、Docker 镜像；同时保留 `legacy.shell` 作为迁移缓冲层。

### 9.2 TODO

当前状态（2026-05-26）：

- `P4-1` 已完成：`bin/uyabuild` 现已通过统一的 Rule Pack / Rule Kind 注册表声明 schema、provider、planner、scanner 元数据；`legacy.shell`、`task`、`cxx.*`、`node.*`、`oci.image` 都改为经由注册表接线，后续新增规则包无需再把映射散落进多处条件分支。
- `P4-2` 已完成：`legacy.shell` 规则已具备 schema 校验、planner 接线、本地执行、输入输出声明、严格模式依赖追踪和错误诊断；相关 unit、golden、e2e 回归已稳定覆盖。
- `P4-3` 已完成：`cxx.library` / `cxx.binary` 现已可在 `pure` 本地执行器里完成最小 C++ 构建闭环；`cxx-minimal` 样例仓已可通过 `uyabuild build //app:hello` 产出并运行 `out/bin/hello`，`custom-state-dir`、e2e 和全量回归已覆盖该路径。
- `P4-4` 已完成：`cxx.library` / `cxx.binary` 现已支持显式 `discover = cpp.headers()` 触发的递归 `#include` 扫描；新补充的 `cxx-header-scan` 样例仓和 `planner/cxx-header-discover`、e2e 回归可验证扫描到的私有头文件会进入 action inputs，并在头文件改动后触发正确重建。
- 现有回归已覆盖注册表接线后的四类内建规则：`legacy.shell` 与最小 `cxx` 执行路径已接入本地执行器，`node` / `oci` 的执行后端继续留在后续条目推进。

| ID | 优先级 | 任务 | 依赖 | 验收标准 |
|---|---|---|---|---|
| `P4-1` | `P0` | 已完成：定义 Rule Pack 接口：schema/provider/planner/scanner | `P1-6`, `P2-6` | 新规则包可通过统一接口注册 |
| `P4-2` | `P0` | 已完成：实现 `legacy.shell` 规则 | `P4-1`, `P3-9` | 可包装 shell 脚本并追踪输入输出 |
| `P4-3` | `P0` | 已完成：实现 `cxx.library` / `cxx.binary` schema 与 planner | `P4-1` | 最小 C++ 项目可构建 |
| `P4-4` | `P0` | 已完成：接入头文件 include 扫描 | `P4-3`, `P3-7` | 修改头文件会触发正确增量重建 |
| `P4-5` | `P1` | 实现 `cxx.test` 规则 | `P4-3` | `uya test` 可执行 C/C++ 测试 |
| `P4-6` | `P0` | 实现 `node.workspace` / `node.app` 规则 | `P4-1` | Node workspace 项目可安装与构建 |
| `P4-7` | `P1` | 实现 lockfile 和 workspace 图扫描 | `P4-6` | 修改相关 package 会触发正确构建 |
| `P4-8` | `P0` | 实现 `oci.image` 规则，后端对接 Buildx | `P4-1`, `P3-6` | Docker 多阶段镜像可构建并产出 metadata |
| `P4-9` | `P1` | 支持 `cache-from/cache-to/provenance` | `P4-8` | 镜像规则可配置缓存与 provenance |
| `P4-10` | `P1` | 实现 `artifact/service/bundle` 聚合规则 | `P4-1` | 前端产物、镜像和清单可被聚合发布 |

### 9.3 退出条件

- 四个首发规则包全部可用。
- 三种样例仓均能在 `UyaBuild` 下跑通。
- `legacy.shell` 能承接遗留脚本，但具备升级路径。

## 10. Phase 5：UBEP、Query、Why、Replay

### 10.1 目标

把“为什么构建”变成可回答的问题，而不是调试时手工猜测。

### 10.2 TODO

| ID | 优先级 | 任务 | 依赖 | 验收标准 |
|---|---|---|---|---|
| `P5-1` | `P1` | 定义 UBEP 事件 schema | `P3-12` | 事件字段和生命周期固定 |
| `P5-2` | `P1` | 实现 `ndjson/json` 事件输出 | `P5-1` | CLI 和 CI 可消费结构化事件 |
| `P5-3` | `P1` | 记录 `BuildStarted/ActionStarted/ActionFinished/BuildFinished` | `P5-2` | 一次构建具备完整事件流 |
| `P5-4` | `P1` | 实现 `query` 的 `deps/rdeps/kind/filter` | `P2-5`, `P2-4` | 可以查询目标图 |
| `P5-5` | `P1` | 实现 `aquery` 查看动作命令和输入输出 | `P2-6`, `P2-4` | 动作图可被直接检查 |
| `P5-6` | `P1` | 实现 `why` 的脏因树 | `P2-7`, `P3-12` | 能解释一次重建的最小原因链 |
| `P5-7` | `P1` | 实现 `replay` | `P3-12`, `P2-3` | 失败动作可在本地复现 |
| `P5-8` | `P2` | 实现 `diff-run` 比较两次构建的动作差异 | `P5-3`, `P5-6` | 可定位缓存 miss 来源 |

### 10.3 退出条件

- `query/aquery/why/replay` 形成闭环。
- 构建失败、缓存 miss、隐藏依赖问题可被结构化定位。

## 11. Phase 6：互操作与迁移工具

### 11.1 目标

让旧系统先进入图，再逐步被替换，而不是要求用户一次性重写。

### 11.2 TODO

| ID | 优先级 | 任务 | 依赖 | 验收标准 |
|---|---|---|---|---|
| `P6-1` | `P1` | 实现 `external.make` 规则 | `P4-2` | 可包装 `make <target>` |
| `P6-2` | `P1` | 实现 `uya import make`，输出初始 `legacy.shell` 节点 | `P6-1` | 可导入常见非递归 Makefile 子集 |
| `P6-3` | `P1` | 实现 `external.cmake` 规则 | `P4-2` | 可把 CMake 子项目接入图 |
| `P6-4` | `P1` | 接入 CMake File API 和 Presets 读取 | `P6-3` | 能读取 codemodel 并生成节点 |
| `P6-5` | `P1` | 支持 `compile_commands.json` 产出或透传 | `P4-3`, `P6-4` | IDE 工具链可继续使用 |
| `P6-6` | `P1` | 实现 `external.bazel` 包装和 BEP 消费 | `P5-2` | 可接入 Bazel 子系统执行和状态 |
| `P6-7` | `P1` | Node 规则接入 npm workspace 互操作细节 | `P4-6` | `npm ci`、`npm run build` 路径语义正确 |
| `P6-8` | `P1` | `oci.image` 对接 Buildx metadata/provenance | `P4-8` | 元数据可被写回构建图 |
| `P6-9` | `P2` | 评估导出 Ninja 后端的路径 | `P2-6`, `P4-3` | 至少有原型和适用边界说明 |

### 11.3 退出条件

- 主流遗留入口都能被包装。
- CMake、npm、Docker 至少具备可用互操作路径。
- Make 迁移不再依赖人工手工转译所有目标。

## 12. Phase 7：`uya` 主仓迁移

### 12.1 目标

让 `uya` 仓库本身成为 `UyaBuild` 的第一个 dogfood 场景，并把默认入口从 `Makefile` 切到 `uya`。

### 12.2 TODO

| ID | 优先级 | 任务 | 依赖 | 验收标准 |
|---|---|---|---|---|
| `P7-1` | `P0` | 盘点现有 `Makefile` 目标、环境变量、脚本依赖 | `P6-1` | 输出完整迁移清单 |
| `P7-2` | `P0` | 建立 `//bootstrap`、`//compiler`、`//tests`、`//dist` 初始目标图 | `P1-6`, `P2-5` | 主链路目标全部可表达 |
| `P7-3` | `P0` | 先以 `legacy.shell` 包装现有核心流程 | `P4-2`, `P7-1` | `uyabuild build/test/check/release` 可转发跑通 |
| `P7-4` | `P0` | 将 `uya` 编译主链逐步替换为 `cxx.*` 结构化规则 | `P4-3`, `P4-4` | 编译链路不再依赖大段 shell |
| `P7-5` | `P1` | 将测试链替换为 `cxx.test` 或结构化 `task` | `P4-5` | `uyabuild test //tests/...` 成为主入口 |
| `P7-6` | `P1` | 将 release/install 流程建模为 `artifact/service/bundle` | `P4-10` | 发布流程可被 query/why 分析 |
| `P7-7` | `P0` | 更新 `uya` 开发文档和 CI 入口 | `P7-3` | 文档默认命令为 `uyabuild ...` |
| `P7-8` | `P0` | 将顶层 `Makefile` 收缩为 bootstrap 和兼容转发层 | `P7-7` | 日常开发无需直接使用 `make` |
| `P7-9` | `P1` | 建立对比基准：旧 Make 与新 UyaBuild 的 null build/增量表现 | `P7-4` | 有明确性能和正确性对比报告 |

### 12.3 退出条件

- `uya` 主仓默认开发入口切换完成。
- 顶层 `Makefile` 不再承载核心工程逻辑。
- 至少编译、测试、发布三条主链路已进入结构化图。

## 13. Phase 8：远程缓存、CI、性能与试点

### 13.1 目标

在本地语义稳定后，再扩展到 CI 缓存与中大型仓库试点，避免过早分布式化。

### 13.2 TODO

| ID | 优先级 | 任务 | 依赖 | 验收标准 |
|---|---|---|---|---|
| `P8-1` | `P2` | 设计远程缓存协议适配层 | `P2-9`, `P5-2` | 明确本地与远程对象模型映射 |
| `P8-2` | `P2` | 先实现远程缓存只读命中模式 | `P8-1` | CI 可消费已有缓存 |
| `P8-3` | `P2` | 再实现受控写入模式 | `P8-2` | 可配置写回策略 |
| `P8-4` | `P2` | 集成 CI 指标采集与构建报告 | `P5-2` | 命中率、关键路径、失败动作可视化 |
| `P8-5` | `P2` | 开展中型 monorepo 子集试点 | `P6-4`, `P6-7`, `P6-8` | 试点仓至少覆盖多语言场景 |
| `P8-6` | `P2` | 进行 1 万目标以上规划性能回归 | `P2-6`, `P3-10` | 达到设计中的 p95 目标 |
| `P8-7` | `P2` | 评估是否引入本地守护进程优化大仓加载 | `P8-5` | 有结论和边界，不影响无 daemon 主路径 |

### 13.3 退出条件

- CI 能稳定利用缓存。
- 大仓试点结果达到预期。
- 是否继续向远程执行扩展有客观依据。

## 14. 横向工作流 TODO

### 14.1 测试与质量

- [x] `P0` 建立 parser/analyzer/planner/executor 的单元测试矩阵。
- [x] `P0` 建立 golden test：输入 DSL -> IR / plan / why 输出。
- [x] `P0` 建立 end-to-end 样例仓回归测试。
- [x] `P1` 建立隐藏依赖、未声明输出、写源码树等错误样例集。
- [x] `P1` 建立兼容模式与严格模式行为对比测试。
- [ ] `P1` 建立 `replay` 的一致性测试。

### 14.2 性能与基准

- [ ] `P0` 定义 `null build`、单文件修改、单头文件修改、Node lockfile 变更、Docker context 变更五类标准场景。
- [ ] `P1` 建立动作键热点统计与 NoSQLite 索引/查询热点分析。
- [ ] `P1` 建立 CAS 存储增长与 GC 观察脚本。
- [ ] `P2` 建立多核并行与资源池调优基准。

### 14.3 文档与迁移材料

- [ ] `P0` 编写 `uya.build` 语法参考。
- [ ] `P0` 编写 `从 Make 迁移到 UyaBuild` 指南。
- [ ] `P1` 编写 `CMake 子项目接入` 指南。
- [ ] `P1` 编写 `Node workspace` 和 `Docker Buildx` 使用指南。
- [ ] `P1` 编写 `why/aquery/replay` 调试手册。

## 15. 风险清单与预防性任务

| 风险 | 影响 | 预防性任务 |
|---|---|---|
| `Uya` 文件系统或进程标准库能力不足 | 拖慢主体实现 | 尽早验证 CLI、IO、并发、进程 API 能力 |
| 依赖追踪跨平台实现复杂 | 严格模式落地受阻 | 先把 Linux/macOS 路线做稳，Windows 延后 |
| `legacy.shell` 使用过久 | 系统退化成新的 shell 编排器 | 设定兼容窗口与升级考核 |
| 规则包膨胀 | 形成新的宏地狱 | 所有规则包必须 schema 化、版本化 |
| 远程缓存过早引入 | 放大不可复现问题 | 本地 hermetic 和 null build 达标前禁止推进 |

## 16. MVP Definition of Done

满足以下条件可认为 MVP 完成：

- 根 `uya.build` 可稳定解析为 typed IR，并支持可选 `uya.toml` 兼容导入。
- 本地 CAS、NoSQLite、Planner、Executor 已闭环。
- `cxx`、`node`、`oci`、`legacy.shell` 可用。
- `query`、`aquery`、`why`、`replay` 可运行。
- `uya` 主仓的 build/test/check/release 主链路已能通过 `uya` 命令运行。
- 顶层 `Makefile` 只保留 bootstrap 和兼容转发职责。

## 17. 建议里程碑顺序

推荐按以下顺序推进：

1. `Phase 0 + Phase 1`
2. `Phase 2`
3. `Phase 3`
4. `Phase 4`
5. `Phase 7`
6. `Phase 5`
7. `Phase 6`
8. `Phase 8`

原因：

- 没有 grammar、IR、Planner 和 Executor，就没有真正的构建系统。
- 没有 `uya` 主仓 dogfood，设计很难快速收敛。
- `query/why` 很重要，但必须建立在稳定动作记录之上。
- 远程缓存和大仓试点应该建立在本地语义成熟之后。
