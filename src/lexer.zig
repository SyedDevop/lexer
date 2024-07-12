const std = @import("std");
const Token = union(enum) {
    ident: []const u8,
    int: []const u8,

    let,
    illegal,
    eof,
    assign,
    plus,
    comma,
    semicolon,
    lparen,
    rparen,
    lsquirly,
    rsquirly,
    function,

    bang,
    dash,
    forward_slash,
    asterisk,
    less_than,
    greater_than,

    equal,
    not_equal,

    if_token,
    else_token,
    return_token,
    false_token,
    true_token,

    fn keyword(key: []const u8) ?Token {
        const map = std.StaticStringMap(Token).initComptime(.{
            .{ "let", .let },
            .{ "fn", .function },
            .{ "if", .if_token },
            .{ "true", .true_token },
            .{ "false", .false_token },
            .{ "return", .return_token },
            .{ "else", .else_token },
        });
        return map.get(key);
    }
};
fn isLetter(ch: u8) bool {
    return std.ascii.isAlphabetic(ch) or ch == '_';
}
fn isNum(ch: u8) bool {
    return std.ascii.isDigit(ch);
}
pub const Lexer = struct {
    const Self = @This();
    read_position: usize = 0,
    position: usize = 0,
    ch: u8 = 0,
    input: []const u8,

    pub fn init(input: []const u8) Self {
        var lex = Self{
            .input = input,
        };
        lex.readChar();
        return lex;
    }
    pub fn nextToke(self: *Self) Token {
        self.skipWhitespace();
        const tok: Token = switch (self.ch) {
            '{' => .lsquirly,
            '}' => .rsquirly,
            '(' => .lparen,
            ')' => .rparen,
            ',' => .comma,
            ';' => .semicolon,
            '+' => .plus,
            '-' => .dash,
            '<' => .less_than,
            '>' => .greater_than,
            '/' => .forward_slash,
            '*' => .asterisk,
            '!' => blk: {
                if (self.peek('=')) {
                    self.readChar();
                    break :blk .not_equal;
                } else {
                    break :blk .bang;
                }
            },
            '=' => blk: {
                if (self.peek('=')) {
                    self.readChar();
                    break :blk .equal;
                } else {
                    break :blk .assign;
                }
            },
            0 => .eof,
            'a'...'z', 'A'...'Z', '_' => {
                const ident = self.readIdentifier();
                if (Token.keyword(ident)) |token| {
                    return token;
                }
                return .{ .ident = ident };
            },
            '0'...'9' => {
                const num = self.readNum();
                return .{ .int = num };
            },

            else => .illegal,
        };

        self.readChar();
        return tok;
    }
    fn readIdentifier(self: *Self) []const u8 {
        const position = self.position;
        while (isLetter(self.ch)) {
            self.readChar();
        }
        return self.input[position..self.position];
    }
    fn readNum(self: *Self) []const u8 {
        const startPos = self.position;
        while (isNum(self.ch)) {
            self.readChar();
        }
        return self.input[startPos..self.position];
    }

    fn peek(self: *Self, ch: u8) bool {
        return (self.input[self.read_position] == ch) and !(self.read_position >= self.input.len);
    }
    fn readChar(self: *Self) void {
        if (self.read_position >= self.input.len) {
            self.ch = 0;
        } else {
            self.ch = self.input[self.read_position];
        }

        self.position = self.read_position;
        self.read_position += 1;
    }
    fn skipWhitespace(self: *Self) void {
        while (std.ascii.isWhitespace(self.ch)) {
            self.readChar();
        }
    }
    pub fn hasTokes(self: *Self) bool {
        return self.ch != 0;
    }
};

const ex = std.testing.expectEqualDeep;
test "Lexer" {
    const input = "+(){},;";
    var lex = Lexer.init(input);

    const token = [_]Token{ .plus, .lparen, .rparen, .lsquirly, .rsquirly, .comma, .semicolon, .eof };

    while (lex.hasTokes()) {
        try ex(token[lex.position], lex.nextToke());
    }
}

test "Lexer Code" {
    const input =
        \\let five = 5;
        \\let ten = 10;
        \\let add = fn(x, y) {
        \\    x + y;
        \\};
        \\let result = add(five, ten);
        \\!-/*5;
        \\5 < 10 > 5;
        \\if (5 < 10) {
        \\    return true;
        \\} else {
        \\    return false;
        \\}
        \\10 == 10;
        \\10 != 9;
    ;

    var lex = Lexer.init(input);
    const tokens = [_]Token{
        .let,
        .{ .ident = "five" },
        .assign,
        .{ .int = "5" },
        .semicolon,
        .let,
        .{ .ident = "ten" },
        .assign,
        .{ .int = "10" },
        .semicolon,
        .let,
        .{ .ident = "add" },
        .assign,
        .function,
        .lparen,
        .{ .ident = "x" },
        .comma,
        .{ .ident = "y" },
        .rparen,
        .lsquirly,
        .{ .ident = "x" },
        .plus,
        .{ .ident = "y" },
        .semicolon,
        .rsquirly,
        .semicolon,
        .let,
        .{ .ident = "result" },
        .assign,
        .{ .ident = "add" },
        .lparen,
        .{ .ident = "five" },
        .comma,
        .{ .ident = "ten" },
        .rparen,
        .semicolon,
        .bang,
        .dash,
        .forward_slash,
        .asterisk,
        .{ .int = "5" },
        .semicolon,
        .{ .int = "5" },
        .less_than,
        .{ .int = "10" },
        .greater_than,
        .{ .int = "5" },
        .semicolon,
        .if_token,
        .lparen,
        .{ .int = "5" },
        .less_than,
        .{ .int = "10" },
        .rparen,
        .lsquirly,
        .return_token,
        .true_token,
        .semicolon,
        .rsquirly,
        .else_token,
        .lsquirly,
        .return_token,
        .false_token,
        .semicolon,
        .rsquirly,
        .{ .int = "10" },
        .equal,
        .{ .int = "10" },
        .semicolon,
        .{ .int = "10" },
        .not_equal,
        .{ .int = "9" },
        .semicolon,
        .eof,
    };
    for (tokens) |token| {
        const tok = lex.nextToke();
        try ex(token, tok);
    }
}
