# Garlic Syntax

这是一个Godot4.6 UGC框架，该语言名为“Garlic”，用于将用户代码表示为DSL。

1. 标识符，简称IDENT，与大多数高级语言类似，只能用字母、数字、下划线且数字不能开头
2. 空格、tab、换行可以被完全忽略。
3. 用<>包裹注释，不管是单行还是多行都行，注释支持嵌套，注释在词法层面等于空白。
4. 本语言不存在中缀表达式，所有结构都是节点调用，因此无需运算符优先级。
5. 文件的后缀名为`.srk`。

## 节点

并不是传统意义上的AST树，只能说类似IDENT(...)这种语法结构视作一个“节点”（不是AST Node！）。
括号内为key=value,...的键值对，key是一个IDENT，value的部分支持3种内容：**语法字面量**、**子节点**、**节点体**，见下文，括号内允许后缀逗号，(key1=v1,key2=v2,)是允许的。

节点在Parser解析后为一个字典，扁平列出：

```json
{
    "type":"xxx",
    "...attributes":"value"
}
```

### 字面量

注意区分：**语义层面**的字面量和**语法层面**的字面量。

1. 用户在代码里写的"string"、123、true这种代码，实际上并不是传统AST意义上的“LiteralNode”，这种字面量只负责配置节点，是仅存在于**语法层面**的字面量。
2. 语法层面的字面量并不参与用户代码的运行时逻辑，相对，LiteralNode会参与用户代码的运行时逻辑，称为**语义层面**的字面量。
3. Parser不区分语义字面量与普通节点；语义字面量只是运行时概念，在语法上仍按普通节点解析。

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

#### 注意

1. 数组不能嵌套，内部也不能放置节点。
2. 允许后缀逗号，[a,b,c,]是允许的。

#### 对于字符串语法字面量

1. 字符串内允许反斜杠转义，比如"Hello\nWorld"
2. 不同引号类型之间没有区别，`""`、`''`、`“”`、` `` `都可以用来包裹字符串（但是必须配对，比如"Hello'这种是非法的），不过`「」`包裹的字符串在Parser解析时要生成gdscript的StringName对象而非普通String对象。

#### 保留字，禁止用作IDENT

1. true/false

### 子节点

顾名思义，节点的大部分字段都可以指向另一个节点，这里的另一个节点就视作该节点的子节点。

## 节点体

通过`{node(...);node(...);...}`的语法来声明，解析后为一个装有其内部的节点的数组，节点体内的每个节点语句结束后都**必须**带上分号，注意如果一个节点只是作为子节点而不在节点体内，分号是可选的。节点体在Parser解析后为一个数组。

## 文件格式

每个文件的内容有且仅有一个根节点或任意节点体。

## 示例文件

1. 不一定需要root节点，只要是一个节点就可以的。

    ```plain
    <Add 2 Numbers.srk>
    root(body={
        function_definition(name="add",params=["a","b"],body={
            return(
                data=add(
                    A=read_symbol(name="a"),
                    B=read_symbol(name="b")
                )
            );
        });
        print(content=function_call(name="add",params={
            number_literal(content=123);
            number_literal(content=123);
        }));
    })
    ```

2. 用节点体的语法写也可以直接声明，不过这种节点体无法被直接运行。

    ```plain
    <Body of add-2-numbers.srk>
    {
        function_definition(name="add",params=["a","b"],body={
            return(
                data=add(
                    A=read_symbol(name="a"),
                    B=read_symbol(name="b")
                )
            );
        });
        print(content=function_call(name="add",params={
            number_literal(content=123);
            number_literal(content=123);
        }));
    }
    ```

3. 一些非法示例

    ```plain
    foo(a=) <a字段缺少值>
    foo(a=[number_literal(content=1)]) <数组内不能有节点>
    foo(a=1, a=2) <字段声明重复>
    foo(a={2}) <节点体内有非节点要素>
    foo(a={number_literal(content=1)}) <节点语句的末尾缺少分号>
    ```
