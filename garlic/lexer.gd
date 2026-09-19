@tool
extends RefCounted
class_name GarlicLexer

class Token:
	var type: TokenType = TokenType.EOF
	var value: Variant = null
	var line: int = 1
	var column: int = 1

	func _init(
		typx: TokenType = TokenType.EOF,
		valux: Variant = null,
		linx: int = 1,
		columx: int = 1
	) -> void:
		type = typx
		value = valux
		line = linx
		column = columx

	func describe() -> String:
		match type:
			TokenType.EOF:
				return "end of file"
			_:
				return "'%s'" % value

enum TokenType {
	IDENT,
	NUMBER,
	STRING,
	STRING_NAME,
	BOOL,
	PUNCT,
	EOF,
}

const PUNCTUATION = "(){}[]=,;"
const QUOTE_PAIRS = {"\"": "\"", "'": "'", "“": "”", "`": "`", "「": "」"}

var errors: Array[String] = []
var stringEndIndex = 0
var stringEndLine = 1
var stringEndColumn = 1

func add_error(line: int, col: int, message: String) -> void:
	errors.append("line %d col %d: %s" % [line, col, message])
func tokenize(source: String) -> Array[Token]:
	var tokens: Array[Token] = []
	var line = 1
	var column = 1
	var i = 0
	var length = source.length()
	while i < length:
		var currentChar = source[i]
		if currentChar == "\n":
			line += 1
			column = 1
			i += 1
			continue
		if currentChar == " " or currentChar == "\t" or currentChar == "\r":
			column += 1
			i += 1
			continue
		if currentChar == "<":
			var commentLine = line
			var commentColumn = column
			var depth = 0
			while i < length:
				var c = source[i]
				if c == "\n":
					line += 1
					column = 1
				elif c == "<":
					depth += 1
					column += 1
				elif c == ">":
					depth -= 1
					column += 1
				else:
					column += 1
				i += 1
				if depth == 0:
					break
			if depth != 0:
				add_error(commentLine, commentColumn, "unterminated comment.")
			continue
		if is_digit(currentChar) or (currentChar == "-" and i + 1 < length and is_digit(source[i + 1])):
			var numLine = line
			var numColumn = column
			var start = i
			i += 1
			column += 1
			while i < length and is_digit(source[i]):
				i += 1
				column += 1
			if i < length and source[i] == "." and i + 1 < length and is_digit(source[i + 1]):
				i += 1
				column += 1
				while i < length and is_digit(source[i]):
					i += 1
					column += 1
			var text = source.substr(start, i - start)
			tokens.append(Token.new(TokenType.NUMBER, text.to_float(), numLine, numColumn))
			continue
		if is_identifier_head(currentChar):
			var identifierLine = line
			var identifierColumn = column
			var startIndex = i
			while i < length and is_identifier_chars(source[i]):
				i += 1
				column += 1
			var text = source.substr(startIndex, i - startIndex)
			if text == "true" or text == "false":
				tokens.append(Token.new(TokenType.BOOL, text == "true", identifierLine, identifierColumn))
			else:
				tokens.append(Token.new(TokenType.IDENT, text, identifierLine, identifierColumn))
			continue
		if QUOTE_PAIRS.has(currentChar):
			var token = parse_string(source, currentChar, i, line, column)
			if token == null:
				break
			tokens.append(token)
			line = stringEndLine
			column = stringEndColumn
			i = stringEndIndex
			continue
		if PUNCTUATION.contains(currentChar):
			tokens.append(Token.new(TokenType.PUNCT, currentChar, line, column))
			column += 1
			i += 1
			continue
		add_error(line, column, "unexpected character '%s'." % currentChar)
		column += 1
		i += 1
	tokens.append(Token.new(TokenType.EOF, null, line, column))
	return tokens
func parse_string(source: String, open: String, startIndex: int, startLine: int, startColumn: int) -> Token:
	var closeChar: String = QUOTE_PAIRS[open]
	var isStringName = open == "「"
	var value = ""
	var i = startIndex + 1
	var length = source.length()
	var line = startLine
	var column = startColumn + 1
	while i < length:
		var currentChar = source[i]
		if currentChar == "\\":
			if i + 1 >= length:
				add_error(line, column, "unterminated string.")
				return null
			var escaped = source[i + 1]
			match escaped:
				"n":
					value += "\n"
				"t":
					value += "\t"
				"r":
					value += "\r"
				_:
					value += escaped
			i += 2
			column += 2
			continue
		if currentChar == "\n":
			line += 1
			column = 1
			i += 1
			continue
		if currentChar == closeChar:
			var result
			if isStringName:
				result = StringName(value)
			else:
				result = value
			stringEndIndex = i + 1
			stringEndLine = line
			stringEndColumn = column + 1
			return Token.new(TokenType.STRING_NAME if isStringName else TokenType.STRING, result, startLine, startColumn)
		value += currentChar
		column += 1
		i += 1
	add_error(startLine, startColumn, "unterminated string, expected '%s'." % closeChar)
	return null

static func is_digit(currentChar: String) -> bool:
	return currentChar >= "0" and currentChar <= "9"
static func is_identifier_head(currentChar: String) -> bool:
	return (currentChar >= "a" and currentChar <= "z") or (currentChar >= "A" and currentChar <= "Z") or currentChar == "_"
static func is_identifier_chars(currentChar: String) -> bool:
	return is_identifier_head(currentChar) or is_digit(currentChar)
