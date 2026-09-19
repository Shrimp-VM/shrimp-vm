# Garlic Syntax

1. 标识符，简称IDENT，与大多数高级语言类似，只能用字母、数字、下划线且数字不能开头

## 节点

并不是传统意义上的AST树，只能说类似IDENT(...)这种结构视作一个“节点”。
括号内为key=value,...的键值对，value的部分支持3种内容：**语法字面量**、**子节点**、**节点体**。

### 字面量

注意区分：**语义层面**的字面量和**语法层面**的字面量。

1. 用户在代码里写的"string"、123、true这种代码，实际上并不是传统AST意义上的“LiteralNode”，这种字面量只负责配置节点，是仅存在于**语法层面**的字面量。
2. 语法层面的字面量并不参与用户代码的运行时逻辑，相对，LiteralNode会参与用户代码的运行时逻辑，称为**语义层面**的字面量。

对于“LiteralNode”，也就是语义字面量，在运行时上也是一种“节点”，也必须通过上文的节点语法来书写。

```plain
print(content=string_literal(content="Hello World!!!"))
```

比如这段代码的本质是声明一个print节点，他的content字段指向一个子节点，这个子节点的类型为string_literal（一个普通节点，视为语义字面量），而他的content字段的值是字面量“Hello World!!!”（语法字面量）。

对于语法字面量，支持3种基本类型：数字、字符串、布尔。注意我们不区分整数还是浮点数。

```plain
114.514
123456
"Hello"
'World!'
true
false
```

然后就是一种特殊的语法字面量，数组类型，用`[]`包裹，`,`分隔每一项，其下的每一项都可以是一个基本类型的**语法字面量**。

```plain
[114,514,1919.810]
["Hello",'World!']
[false,true]
["AKer is a", true, 'idiot', 'aged', 114.514]
```

### 子节点

顾名思义，节点的大部分字段都可以指向另一个节点，这里的另一个节点就视作该节点的子节点。

## 节点体

通过`{node(...);node();...}`的语法来声明，解析后为一个装有其内部的节点的数组，每个节点结束后都必须带上分号。

## 示例代码

```plain
function_definition(name="add",params=["a","b"],body={
    return(
        data=add(
            A=read_symbol(name="a"),
            B=read_symbol(name="b")
        )
    );
})
print(content=function_call(name="add",params={
    number_literal(content=123);
    number_literal(content=123);
}))
```
