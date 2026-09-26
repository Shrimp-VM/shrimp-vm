# ShrimpVM

## **This document was written by AI!!!**

A visual block-based scripting virtual machine for Godot 4.6 (UGC framework): lets players drag and drop block nodes in a GUI to write and run game behavior scripts.

## Features

- **Blocks as code**: every block node is a `ShrimpIR` (Resource) script; once it declares its own schema, it can be consumed simultaneously by the visual editor, the importer, and the LSP
- **Async all the way**: the entire execution pipeline is based on `await`, naturally supporting suspension, timing, and waiting for input, with a built-in `yield` / generator mechanism
- **Complete language facilities**: function definition and invocation, if / while / for / repeat control flow, OOP (classes / instances / member access / this), and a symbol scope chain
- **Dual script formats**: the visual block format (.sst) and the text DSL [Garlic](garlic) (.srk) compile into the same IR tree, making both editing styles interoperable
- **In-game editor**: provides a block canvas that can be embedded into any game (drag and drop, wiring, box selection, parameter editors dynamically generated from the schema)
- **Language server**: the Garlic LSP runs persistently inside the editor process alongside the plugin, providing completion / hover / real-time diagnostics for .srk over TCP

## Getting Started

1. Place this plugin in `addons/shrimpvm` and enable it in the project settings
2. Add a `ShrimpVM` node to your scene and assign a ShrimpIR resource to `autoRun` to execute it automatically
3. Or execute manually in code:

```gdscript
var result = await vm.execute(some_ir, ExecutionContext.new())
```

### Event Model

The node schema's `trigger` determines how it participates:

| trigger         | Behavior                                                                                         |
|-----------------|--------------------------------------------------------------------------------------------------|
| `EXECUTION`     | Sequential execution                                                                             |
| `EVENT_POLL`    | Poll-tested every frame; triggers `event_emit` once it returns a bool                            |
| `EVENT_TRIGGER` | Triggered by name via `vm.trigger_event()`; external parameters are written to `EVENT_*` symbols |
| `TERMINAL`      | Terminal node; cannot be connected to subsequent sibling nodes                                   |

### Custom Nodes

Inherit from `ShrimpIR` and implement the following interface:

```gdscript
func execute(vm: ShrimpVM, context: ExecutionContext) -> Variant
func decompile() -> Dictionary
static func create_from(wrapper: Dictionary) -> ShrimpIR
static func get_wrapper_schema() -> Dictionary
```

## Directory Structure

```plain
shrimp_vm.gd          ShrimpVM executor (execute / poll_event / trigger_event)
shrimp_ir.gd          ShrimpIR abstract base class and schema Model
shrimp_compiler.gd    Dictionary / JSON / file → ShrimpIR compilation
shrimp_optimizer.gd   IR optimizer
execution_context.gd  Execution context (scope chain, lifecycle, event loop)
execution_env.gd      Symbol environment
implements/           Runtime objects (Class, Instance, Function, Generator, AsyncTask)
nodes/                Built-in block node library (literals / maths / symbols / streams / macros / oop)
garlic/               Garlic text DSL toolchain and LSP (git submodule)
scenes/               In-game visual editor (canvas, node blocks, selection, virtual file system)
plugin/               Parameter type editors (float / string / bool / StringName)
```
