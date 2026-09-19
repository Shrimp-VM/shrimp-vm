@tool
extends RefCounted
class_name GarlicParser

const IMPORTER_ID = "shrimpvm.garlic"

var tokens: Array[GarlicLexer.Token] = []
var position: int = 0
var errors: Array[String] = []

func add_error(token: GarlicLexer.Token, message: String) -> void:
	errors.append("line %d col %d: %s" % [token.line, token.column, message])
func peek_token() -> GarlicLexer.Token:
	return tokens[position]
func next_token() -> GarlicLexer.Token:
	var token = tokens[position]
	position += 1
	return token
func token_at_punct(expected: String) -> bool:
	var token = peek_token()
	return token.type == GarlicLexer.TokenType.PUNCT and token.value == expected
func expect_punct(expected: String) -> bool:
	if token_at_punct(expected):
		position += 1
		return true
	add_error(peek_token(), "expected '%s', got %s." % [expected, peek_token().describe()])
	return false
func parse_file() -> Variant:
	if peek_token().type == GarlicLexer.TokenType.EOF:
		add_error(peek_token(), "empty file, expected a node or a node body.")
		return null
	var result: Variant
	if token_at_punct("{"):
		result = parse_node_body()
	else:
		result = parse_node()
	if errors.is_empty() and peek_token().type != GarlicLexer.TokenType.EOF:
		add_error(peek_token(), "unexpected %s after the end of file content." % peek_token().describe())
		return null
	return result
func parse_node() -> Variant:
	var nameIdentifier = peek_token()
	if nameIdentifier.type != GarlicLexer.TokenType.IDENT:
		add_error(nameIdentifier, "expected a node name, got %s." % nameIdentifier.describe())
		return null
	next_token()
	var node = {"type": nameIdentifier.value}
	if not expect_punct("("):
		return node
	if token_at_punct(")"):
		next_token()
		return node
	while true:
		var key_token = peek_token()
		if key_token.type != GarlicLexer.TokenType.IDENT:
			add_error(key_token, "expected an attribute name, got %s." % key_token.describe())
			return node
		next_token()
		if not expect_punct("="):
			return node
		var value: Variant = parse_attribute_value()
		if not errors.is_empty():
			return node
		var key: String = key_token.value
		if node.has(key):
			add_error(key_token, "duplicate attribute '%s'." % key)
			return node
		node[key] = value
		if token_at_punct(","):
			next_token()
			if token_at_punct(")"):
				next_token()
				return node
			continue
		if token_at_punct(")"):
			next_token()
			return node
		add_error(peek_token(), "expected ',' or ')', got %s." % peek_token().describe())
		return node
	return null
func parse_attribute_value() -> Variant:
	var token = peek_token()
	match token.type:
		GarlicLexer.TokenType.NUMBER, GarlicLexer.TokenType.STRING, GarlicLexer.TokenType.STRING_NAME, GarlicLexer.TokenType.BOOL:
			next_token()
			return token.value
		GarlicLexer.TokenType.PUNCT:
			if token.value == "[":
				return parse_literal_array()
			if token.value == "{":
				return parse_node_body()
			add_error(token, "unexpected '%s', expected a literal, a node or a node body." % token.value)
			return null
		GarlicLexer.TokenType.IDENT:
			return parse_node()
		_:
			add_error(token, "expected a literal, a node or a node body, got %s." % token.describe())
			return null
func parse_literal_array() -> Array:
	next_token()
	var items: Array = []
	while true:
		if peek_token().type == GarlicLexer.TokenType.EOF:
			add_error(peek_token(), "unterminated items, expected ']'.")
			return items
		if token_at_punct("]"):
			next_token()
			return items
		var token = peek_token()
		match token.type:
			GarlicLexer.TokenType.NUMBER, GarlicLexer.TokenType.STRING, GarlicLexer.TokenType.STRING_NAME, GarlicLexer.TokenType.BOOL:
				next_token()
				items.append(token.value)
			_:
				add_error(token, "array items must be basic literals (number, string or bool), got %s." % token.describe())
				return items
		if token_at_punct(","):
			next_token() # 后缀逗号
			if token_at_punct("]"):
				next_token()
				return items
			continue
		if token_at_punct("]"):
			next_token()
			return items
		add_error(peek_token(), "expected ',' or ']', got %s." % peek_token().describe())
		return items
	return []
func parse_node_body() -> Array:
	next_token()
	var body: Array = []
	while true:
		var token = peek_token()
		if token.type == GarlicLexer.TokenType.EOF:
			add_error(token, "unterminated node body, expected '}'.")
			return body
		if token_at_punct("}"):
			next_token()
			return body
		var node: Variant = parse_node()
		if node == null:
			return body
		body.append(node)
		if not expect_punct(";"):
			return body
	return []

static func parse(source: String) -> Variant:
	var lexer = GarlicLexer.new()
	var tokenList = lexer.tokenize(source)
	if not lexer.errors.is_empty():
		for message in lexer.errors:
			push_error("GarlicLexer: %s" % message)
		return null
	var parser = GarlicParser.new()
	parser.tokens = tokenList
	var result = parser.parse_file()
	if not parser.errors.is_empty():
		for message in parser.errors:
			push_error("GarlicParser: %s" % message)
		return null
	return result
static func parse_from_file(fp: String):
	var f = FileAccess.open(fp, FileAccess.ModeFlags.READ)
	if !f:
		return null
	return parse(f.get_as_text())
