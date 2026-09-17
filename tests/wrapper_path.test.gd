extends RefCounted
class_name WrapperPathTest
## WrapperPath 单元测试。
## 运行方式：在任意脚本中调用 WrapperPathTest.test()，结果输出到输出/错误面板。

var _case_failures: PackedStringArray = []


static func test() -> void:
	var tester := WrapperPathTest.new()
	tester._run_all()


# ---------------------------------------------------------------- 断言辅助

func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_case_failures.append("%s: 期望 %s, 实际 %s" % [label, str(expected), str(actual)])


func _assert_true(cond: bool, label: String) -> void:
	if not cond:
		_case_failures.append(label)


func _assert_null(value, label: String) -> void:
	if value != null:
		_case_failures.append("%s: 期望 null, 实际 %s" % [label, str(value)])


# ---------------------------------------------------------------- 运行器

func _run_all() -> void:
	var cases: Array[String] = [
		"_test_link_renext_reparent",
		"_test_from_attribute_chain",
		"_test_from_index_part",
		"_test_from_parent_and_self",
		"_test_from_root",
		"_test_normalize_removes_self",
		"_test_normalize_middle_self",
		"_test_normalize_parent",
		"_test_normalize_deep_parent",
		"_test_normalize_idempotent",
		"_test_seek_root",
		"_test_seek_parent",
		"_test_duplicate_deep",
		"_test_duplicate_shallow",
		"_test_concat_append",
		"_test_concat_root",
	]
	var passed := 0
	for case in cases:
		_case_failures = PackedStringArray()
		call(case)
		if _case_failures.is_empty():
			passed += 1
			print("[PASS] %s" % case)
		else:
			for failure in _case_failures:
				printerr("[FAIL] %s -> %s" % [case, failure])
	print("WrapperPathTest: %d/%d 用例通过" % [passed, cases.size()])


# ---------------------------------------------------------------- 用例

## renext / reparent 应建立双向链接
func _test_link_renext_reparent() -> void:
	var a := WrapperPath.new(WrapperPath.PartType.ATTRIBUTE, "a")
	var b := WrapperPath.new(WrapperPath.PartType.ATTRIBUTE, "b")
	a.renext(b)
	_assert_true(a.next == b && b.parent == a, "renext 应同时设置 next 与对端的 parent")

	var head := WrapperPath.new(WrapperPath.PartType.SELF)
	head.reparent(a)
	_assert_true(head.parent == a && a.next == head, "reparent 应同时设置 parent 与对端的 next")


## from() 解析属性链，隐式以 SELF 开头
func _test_from_attribute_chain() -> void:
	var p := WrapperPath.from("a.b")
	_assert_eq(p.type, WrapperPath.PartType.SELF, "链头应为隐式 SELF")
	_assert_eq(p.next.type, WrapperPath.PartType.ATTRIBUTE, "第二段应为 ATTRIBUTE")
	_assert_eq(p.next.path, "a", "第二段路径")
	_assert_eq(p.next.next.type, WrapperPath.PartType.ATTRIBUTE, "第三段应为 ATTRIBUTE")
	_assert_eq(p.next.next.path, "b", "第三段路径")
	_assert_null(p.next.next.next, "链应在此结束")
	_assert_eq(p._to_string(), "#a.b", "字符串表示")


## from() 解析索引段
func _test_from_index_part() -> void:
	var p := WrapperPath.from("a.[2]")
	var idx: WrapperPath = p.next.next
	_assert_eq(idx.type, WrapperPath.PartType.INDEX, "应为 INDEX")
	_assert_eq(idx.path, 2, "索引应解析为整数 2")
	_assert_eq(p._to_string(), "#a.[2]", "字符串表示")


## from() 解析父级与自身标记
func _test_from_parent_and_self() -> void:
	var p := WrapperPath.from("a.<.#")
	_assert_eq(p.next.next.type, WrapperPath.PartType.PARENT, "\"<\" 应解析为 PARENT")
	_assert_eq(p.next.next.next.type, WrapperPath.PartType.SELF, "\"#\" 应解析为 SELF")
	_assert_eq(p._to_string(), "#a.<.#", "字符串表示")


## from() 解析根路径
func _test_from_root() -> void:
	var p := WrapperPath.from("/")
	_assert_eq(p.type, WrapperPath.PartType.ROOT, "应为 ROOT")
	_assert_null(p.next, "单独的根不应有后续段")
	_assert_eq(p._to_string(), "/", "字符串表示")

	var q := WrapperPath.from("/x")
	_assert_eq(q.type, WrapperPath.PartType.ROOT, "\"/x\" 链头应为 ROOT")
	_assert_eq(q.next.type, WrapperPath.PartType.ATTRIBUTE, "\"/x\" 第二段应为 ATTRIBUTE")


## normalize() 移除隐式的链头 SELF
func _test_normalize_removes_self() -> void:
	var p := WrapperPath.from("a.b").normalize()
	_assert_eq(p.type, WrapperPath.PartType.ATTRIBUTE, "归一化后链头应为 ATTRIBUTE")
	_assert_null(p.parent, "归一化后链头不应有 parent")
	_assert_eq(p._to_string(), "a.b", "归一化后字符串表示")


## normalize() 移除链中间的 SELF
func _test_normalize_middle_self() -> void:
	var p := WrapperPath.from("a.#.b").normalize()
	_assert_eq(p._to_string(), "a.b", "中间的 SELF 应被移除")


## normalize() 处理 PARENT：删除上一段
func _test_normalize_parent() -> void:
	var p := WrapperPath.from("a.b.<").normalize()
	_assert_eq(p.type, WrapperPath.PartType.ATTRIBUTE, "结果链头应为 ATTRIBUTE")
	_assert_eq(p._to_string(), "a", "\"a.b.<\" 应归一化为 \"a\"")

	var q := WrapperPath.from("a.[1].<").normalize()
	_assert_eq(q._to_string(), "a", "PARENT 也应能撤销 INDEX 段")


## normalize() 处理连续 PARENT：删除前两段
func _test_normalize_deep_parent() -> void:
	var p := WrapperPath.from("a.b.<.<").normalize()
	_assert_eq(p._to_string(), "a", "\"a.b.<.<\" 应归一化为 \"a\"")


## normalize() 幂等：已归一化的路径再次归一化不变
func _test_normalize_idempotent() -> void:
	var p := WrapperPath.from("a.b").normalize()
	_assert_eq(p.normalize()._to_string(), "a.b", "重复 normalize 应幂等")


## seek_root() 沿 parent 回溯到链头
func _test_seek_root() -> void:
	var p := WrapperPath.from("a.b")
	_assert_true(p.next.next.seek_root() == p, "seek_root 应返回链头自身")


## seek_parent() 按类型回溯最近的祖先
func _test_seek_parent() -> void:
	var p := WrapperPath.from("a.b")
	_assert_true(p.next.next.seek_parent([WrapperPath.PartType.ATTRIBUTE]) == p.next,
			"应回溯到最近的 ATTRIBUTE 祖先")
	_assert_null(p.next.next.seek_parent([]), "无匹配类型时应返回 null")


## duplicate(true) 深拷贝，与原链相互独立
func _test_duplicate_deep() -> void:
	var p := WrapperPath.from("a.b")
	var q := p.duplicate(true)
	_assert_true(q != p, "深拷贝应产生新节点")
	_assert_true(q.next != p.next, "深拷贝的后继也应是新节点")
	_assert_eq(q._to_string(), p._to_string(), "深拷贝结构应一致")
	q.next.path = "z"
	_assert_eq(p.next.path, "a", "修改副本不应影响原链")


## duplicate(false) 浅拷贝，共享后继链
func _test_duplicate_shallow() -> void:
	var p := WrapperPath.from("a.b")
	var q := p.duplicate(false)
	_assert_true(q != p, "浅拷贝自身应是新节点")
	_assert_true(q.next == p.next, "浅拷贝应共享 next")


## concat() 将子路径追加到链尾
func _test_concat_append() -> void:
	var p := WrapperPath.from("a.b")
	var c := WrapperPath.new(WrapperPath.PartType.ATTRIBUTE, "c")
	p.concat(c)
	_assert_eq(p._to_string(), "#a.b.c", "concat 应追加到链尾")


## concat() 遇到根路径时返回根的副本
func _test_concat_root() -> void:
	var p := WrapperPath.from("a.b")
	var r := p.concat(WrapperPath.new(WrapperPath.PartType.ROOT))
	_assert_eq(r.type, WrapperPath.PartType.ROOT, "concat 根路径应返回根副本")
	_assert_eq(p._to_string(), "#a.b", "原链不应被修改")
