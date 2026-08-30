# ShrimpVM

A visual block-based scripting virtual machine for **Godot 4**. ShrimpVM lets your *players* create and run little programs inside your game through a friendly, in-game block editor — perfect for programmable computers, modding sandboxes, puzzle games, or any game where the player writes the logic.

- **Runtime, in-game editor** — a ready-made `CanvasLayer` scene with a block palette, tree view, parameter inspector, and file management.
- **Compile & run player scripts** — JSON block graphs are compiled into executable IR trees and interpreted with full `async/await` support.
- **Extensible node system** — define your own instruction set by writing small GDScript node classes; the editor picks them up automatically.
- **Persistence built-in** — player scripts are managed as virtual files and archived to `user://virtuals.json`.
- **Editor-side import** — `.sst` script files import into your project as regular `ShrimpIR` resources via a custom importer.

## How It Works

```plain
.sst (JSON) ──► ShrimpCompiler ──► ShrimpIR tree ──► ShrimpVM.execute()
     ▲                                                   │
     │                                                   ▼
 ShrimpIREditor (in-game block editor)          Your game's behaviour
```

1. **Blocks are data.** Every instruction is a `ShrimpIR` resource subclass that describes itself with a *wrapper schema* (a JSON schema dictionary). The editor renders the palette and tree purely from these schemas — no scene setup needed for new node types.
2. **Compilation.** `ShrimpCompiler` converts wrapper dictionaries into IR node trees. `ShrimpOptimizer` strips deleted nodes and warns about broken references.
3. **Execution.** `ShrimpVM.execute()` awaits each node's `execute()` method, so nodes can `await` freely (timers, animations, physics waits) without blocking the game.
4. **Scoping.** Each execution runs inside an `ExecutionContext` with a chain of `ExecutionEnvironment` symbol tables (lexical parent scoping), which nodes use to read and write variables.

## Installation

1. Copy the `addons/shrimpvm` folder into your project (or install via the Asset Library).
2. Enable the **ShrimpVM** plugin in *Project Settings → Plugins*. This registers the `.sst` importer.

## Quick Start

1. Add the in-game editor scene to your UI (e.g. as a hidden layer you toggle with a key):

```gdscript
var editor := preload("res://addons/shrimpvm/scenes/ir_editor.tscn").instantiate()
add_child(editor)
```

The editor boots a `ShrimpVM` and `ShrimpFileManager` of its own. Players can:

- Create new scripts and open/delete/rename existing ones (archived in `user://virtuals.json`).
- Drag blocks from the palette (grouped by category) into the tree, select nodes to edit parameters in the inspector.
- Save/load scripts as `.sst` (JSON) files.
- Hit **Run** to compile and execute the script inside the editor.

1. Run a script from your own code:

```gdscript
@onready var vm: ShrimpVM = $ShrimpVM

func run_script() -> void:
    var ir: ShrimpIR = ShrimpCompiler.import_file("res://scripts/player_prog.sst")
    if ir:
        await vm.execute(ir, ExecutionContext.new())
```

`ShrimpVM` can also run a root node automatically when the game starts — just assign `root_node` in the inspector.

## Writing Custom Nodes

Any script extending `ShrimpIR` inside `res://addons/shrimpvm/nodes/` (or in the directory set by the importer's *IR-Scripts directory* option) is discovered automatically and appears in the editor palette.

```gdscript
# nodes/my_print_node.gd
@tool
extends ShrimpIR
class_name ShrimpPrintNode

@export var message: String

func execute(_vm: ShrimpVM, context: ExecutionContext) -> Variant:
    print(context.env.read_symbol(&"some_var"))
    print(message)
    return

func decompile() -> Dictionary:
    return { "message": message }

static func get_node_type() -> String:
    return "my_print"

static func create_from(wrapper: Dictionary) -> ShrimpPrintNode:
    var result := new()
    result.message = wrapper.message
    return result

static func get_wrapper_schema() -> Dictionary[String, Variant]:
    return super.get_wrapper_schema().merged({
        "name": "Print",
        "attributes": {
            "message": { "type": TYPE_STRING, "label": "message" }
        }
    }, true)
```

### Wrapper Schema Reference

| Field                  | Type                    | Description                                                                                    |
|------------------------|-------------------------|------------------------------------------------------------------------------------------------|
| `name`                 | `String`                | Display name shown on the block.                                                               |
| `attributes`           | `Dictionary`            | Attribute key → attribute schema.                                                              |
| `attributes.*.type`    | `int` / `Array[String]` | A Godot `TYPE_*` constant, `ShrimpIR.TYPE_ENUM` for a nested IR node, or an enum option array. |
| `attributes.*.label`   | `String`                | Label shown in the inspector.                                                                  |
| `attributes.*.array`   | `bool`                  | If `true`, the attribute holds a list of values / nested nodes.                                |
| `attributes.*.default` | `Variant`               | Optional initial value.                                                                        |

Attribute types map to editor widgets automatically: `TYPE_STRING` → text box, `TYPE_FLOAT` → number input, `TYPE_BOOL` → toggle, enum array → dropdown, `TYPE_ENUM` → "click a palette block to attach a child node here".

### Compile/Decompile Contract

- `create_from(wrapper)` is the **compile** direction: wrapper `Dictionary` → typed node. Nested nodes arrive as dictionaries (pass them through `ShrimpCompiler.compile_body()` if needed).
- `decompile()` is the reverse: node → wrapper `Dictionary`. `ShrimpCompiler.decompile()` adds the `"type"` field for you.
- The serialized tree must start with a node whose type is `ShrimpRootNode.get_node_type()` (`"root"`).

### Execution Context

Nodes receive an `ExecutionContext` whose `env` is a scoped symbol table. Child scopes are created automatically by nesting (e.g. `ShrimpRootNode.execute()` wraps its body in a child context), and reads fall through to parent scopes. Use `read_symbol` / `write_symbol` / `delete_symbol` to share data between nodes.

## Built-in Nodes

| Node              | Type string        | Description                                                         |
|-------------------|--------------------|---------------------------------------------------------------------|
| Root              | `root`             | Script entry point; holds the `body` block list.                    |
| Rename the script | `file_change_name` | Renames the currently opened virtual file via the `filemgr` symbol. |

More nodes ship in the demo project — check the `nodes/` directory.

## API Overview

| Class                                       | Purpose                                                          |
|---------------------------------------------|------------------------------------------------------------------|
| `ShrimpVM`                                  | Node that executes IR trees (`execute`, `execute_all`).          |
| `ShrimpIR`                                  | Abstract base class for all instruction nodes.                   |
| `ShrimpCompiler`                            | Static compile/decompile/import entry points.                    |
| `ShrimpOptimizer`                           | Cleans up deleted/null nodes; emits warnings.                    |
| `ExecutionContext` / `ExecutionEnvironment` | Scoped symbol tables during execution.                           |
| `ShrimpIREditor`                            | The in-game visual editor scene (open/save/run/file management). |
| `ShrimpFileManager` / `VirtualFile`         | Virtual script files with JSON archiving.                        |
| `SSTImporter`                               | Editor import plugin for `.sst` files.                           |
| `ShrimpVMUtil`                              | Node discovery and category listing helpers.                     |

## Requirements

- Godot **4.6+** (uses `@abstract` and `@export_tool_button`).

## License

MIT — see `LICENSE`. Contributions are welcome!
