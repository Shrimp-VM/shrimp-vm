# 命名规范

1. 方法名用下划线驼峰，其他符号用大/小驼峰。
2. 禁止使用下划线前缀，私有方法直接写方法名。

## 代码结构

**注意**：下面没说“空行”的结构之间禁止空行。

1. @tool/@abstract
    空行
2. extends
    空行
3. class_name
    空行
4. @export var
    空行
5. 变量，先写@onready var再写普通var，再写getter/setter var
    空行
6. 对Godot自带虚方法的实现，如_ready、_process
    空行
7. 自定义的虚方法
8. 对父类的自定义虚方法的实现
    空行
9. 其他方法
    空行
10. 静态方法
