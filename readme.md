# ShrimpVM

## **这个文档是AI写的！！！**

Godot 4.6 的可视化积木脚本虚拟机（UGC 框架）：让玩家在 GUI 里拖拽积木节点编写并运行游戏行为脚本。

## 特性

- **积木即代码**：每个积木节点是一个 `ShrimpIR`（Resource）脚本，声明自己的 schema 后即可同时被可视化编辑器、导入器和 LSP 消费
- **全程异步**：执行链路全部基于 `await`，天然支持挂起、计时、等待输入，配套 `yield` / generator 机制
- **完整的语言设施**：函数定义与调用、if / while / for / repeat 流程控制、OOP（类 / 实例 / 成员访问 / this）、符号作用域链
- **双格式脚本**：可视化积木格式（.sst）与文本 DSL [Garlic](garlic)（.srk）编译为同一套 IR 树，两种编辑方式互通
- **游戏内编辑器**：提供可嵌入任意游戏的积木画布（拖拽、连线、框选、参数编辑器按 schema 动态生成）
- **语言服务器**：Garlic LSP 随插件常驻编辑器进程，通过 TCP 提供 .srk 的补全 / hover / 实时诊断

## 快速开始

1. 将本插件放入 `addons/shrimpvm` 并在项目设置中启用
2. 在场景中放置 `ShrimpVM` 节点，把一个 ShrimpIR 资源赋给 `autoRun` 即可自动执行
3. 代码中手动执行：

```gdscript
var result = await vm.execute(some_ir, ExecutionContext.new())
```

### 事件模型

节点 schema 的 `trigger` 决定参与方式：

| trigger         | 行为                                                          |
|-----------------|---------------------------------------------------------------|
| `EXECUTION`     | 顺序执行                                                      |
| `EVENT_POLL`    | 每帧轮询测试，返回 bool 后触发 `event_emit`                   |
| `EVENT_TRIGGER` | 由 `vm.trigger_event()` 按名触发，外部参数写入 `EVENT_*` 符号 |
| `TERMINAL`      | 终端节点，不可连接后续兄弟节点                                |

### 自定义节点

继承 `ShrimpIR` 并实现以下接口：

```gdscript
func execute(vm: ShrimpVM, context: ExecutionContext) -> Variant
func decompile() -> Dictionary
static func create_from(wrapper: Dictionary) -> ShrimpIR
static func get_wrapper_schema() -> Dictionary
```

## 目录结构

```plain
shrimp_vm.gd          ShrimpVM 执行器（execute / poll_event / trigger_event）
shrimp_ir.gd          ShrimpIR 抽象基类与 schema Model
shrimp_compiler.gd    字典 / JSON / 文件 → ShrimpIR 编译
shrimp_optimizer.gd   IR 优化器
execution_context.gd  执行上下文（作用域链、生命周期、事件循环）
execution_env.gd      符号环境
implements/           运行时对象（Class、Instance、Function、Generator、AsyncTask）
nodes/                内置积木节点库（literals / maths / symbols / streams / macros / oop）
garlic/               Garlic 文本 DSL 工具链与 LSP（git submodule）
scenes/               游戏内可视化编辑器（画布、节点块、选择、虚拟文件系统）
plugin/               参数类型编辑器（float / string / bool / StringName）
```
