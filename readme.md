# Shrimp VM

一个 Godot 4 编辑器插件，提供一套**可视化积木式 IR（中间表示）脚本系统**：在编辑器内用积木块搭建逻辑树，编译为 IR 节点树后由虚拟机异步执行。

## 核心原理

### 数据流

```plain
积木编辑器 (treeData: Dictionary)
        │  JSON 序列化 (.sst 文件 / virtual_file)
        ▼
ShrimpCompiler.compile()   ← 按 type 匹配节点脚本，调用 create_from()
        ▼
ShrimpIR 节点树 (Resource)  ← ShrimpOptimizer 清除无效/空节点
        ▼
ShrimpVM.execute()          ← await 递归执行，返回 Variant
```

### 核心类

| 类                                                                                  | 职责                                                                                                                                              |
|-------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------|
| [shrimp_vm.gd](shrimp_vm.gd)                                                        | 虚拟机入口（Node）。`execute(node, context)` 递归 `await node.execute()`，天然支持异步（如 SleepNode）。游戏运行时若设置了 `root_node` 会自动执行 |
| [shrimp_ir.gd](shrimp_ir.gd)                                                        | IR 节点抽象基类（Resource）。定义 `execute` / `decompile` / `create_from` / `get_wrapper_schema` / `get_node_type` / `get_category_tag` 接口      |
| [shrimp_compiler.gd](shrimp_compiler.gd)                                            | 编译器（纯静态类）。JSON wrapper 字典 ↔ IR 节点树 的双向转换（compile / decompile）                                                               |
| [shrimp_optimizer.gd](shrimp_optimizer.gd)                                          | 优化器。递归遍历属性，过滤 `null` 节点和被标记 `invalid` 的节点（编辑器中删除积木即打此标记，即"红色棍母"），并发出警告                           |
| [execution_context.gd](execution_context.gd) / [execution_env.gd](execution_env.gd) | 执行上下文 + 词法作用域符号表。子节点创建子 Context，`read_symbol` 沿 parent 链向上查找（如 `filemgr` 由编辑器注入）                              |
| [sst_importer.gd](sst_importer.gd)                                                  | 编辑器导入插件。将 `.sst`（JSON 文本）导入为 `ShrimpIR` 资源（`.tres`），导入选项 `ir_script_dir` 指定自定义节点目录                              |
| [file_manager.gd](file_manager.gd)                                                  | 虚拟文件管理器。管理多份 IR 脚本（VirtualFile），持久化到 `user://virtuals.json`                                                                  |

### Wrapper 格式与 Schema

每个节点在编辑器/文件中是一个"wrapper"字典：`{"type": "compare", "left": {...}, "right": {...}, "method": 0}`。节点类通过 `get_wrapper_schema()` 声明自身结构，伪类型定义：

```ts
{
  name: string,                          // 编辑器显示名
  attributes: Record<string, {
    type: int | string[],                // 类型枚举；字符串数组 = 下拉枚举；TYPE_ENUM(-1) = 可嵌套子 IR 节点
    label: string,
    array?: boolean,                     // 值是否为数组，适用于任意 type（TYPE_ENUM/TYPE_STRING/TYPE_FLOAT/字符串枚举）
    default?: any
  }>
}
```

`type: TYPE_ENUM` 的属性可以在编辑器里继续挂子积木，从而构成表达式树（如 CompareNode 的 left/right 是任意返回值的节点）。`array: true` 时编辑器会将属性渲染为元素列表（TYPE_ENUM 数组会自动过滤无效子节点），初始值为空数组。

## 编辑器（scenes/ir_editor.tscn）

`ShrimpIREditor`（CanvasLayer）是完整的可视化脚本工作台：

- **左侧积木桌**：按 `get_category_tag()` 分类展示所有可用节点（[node_block.gd](scenes/node_block.gd)），点击积木将其追加到当前选中的参数位（数组属性追加、单值属性替换）
- **中央节点树**：从根节点开始逐层展示，点击节点在**检查器**（[parameter_inspector.gd](scenes/parameter_inspector.gd)）中编辑属性
- **虚拟文件系统**：上方文件标签页（[virtual_file.gd](scenes/virtual_file.gd)），可新建/打开/重命名脚本，内容即 wrapper JSON，自动存档
- **运行**：点击运行按钮 → 保存当前文件 → `ShrimpCompiler.compile(treeData, true)`（带优化）→ 在注入了 `filemgr` 符号的调试上下文中执行

## 使用方式

1. 在项目设置中启用 `ShrimpVM` 插件。
2. 实例化 `scenes/ir_editor.tscn`，用积木搭建脚本（详见上方编辑器说明）。
3. 运行方式二选一：
   - **编辑器内**：直接点编辑器的运行按钮；
   - **游戏中**：将 `.sst` 导入后的 `ShrimpIR` 资源赋给场景中 `ShrimpVM` 节点的 `root_node`，运行时自动执行。
4. 需要 VM 与游戏对象交互时，构造 `ExecutionContext` 并向 `env` 写入符号（如 `filemgr`），节点内用 `context.env.read_symbol()` 取用。

## 扩展节点

项目内置节点位于 `nodes/`（root、file_change_name）；游戏逻辑节点（If、While、Compare、Print 等 15 个）在项目侧的 `scripts/Content/IR-Nodes/`。自定义新节点只需：

1. 新建脚本 `extends ShrimpIR`，设置 `class_name`；
2. 实现 `execute(vm, context)`（可 `await`，返回值可被父节点当表达式用）；
3. 实现 `get_node_type()`（唯一类型字符串）、`create_from(wrapper)`（反序列化）、`get_wrapper_schema()`（编辑器 schema）、可选 `get_category_tag()`（分类标签）；
4. 将脚本放入某个目录，并在 `.sst` 导入预设的 `ir_script_dir` 选项中填入该目录——编辑器积木桌和编译器会自动发现它。
