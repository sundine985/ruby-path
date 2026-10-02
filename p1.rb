#!/usr/bin/env ruby
require "set"
require "json"
require "time"
require "tempfile"
require "securerandom"
require "forwardable"

module Study
  LESSONS = []

  def self.lesson(name, &block)
    LESSONS << { name: name, body: block }
  end

  def self.run_one(index)
    entry = LESSONS[index]
    puts
    puts "=" * 64
    puts format("LESSON %02d: %s", index + 1, entry[:name])
    puts "=" * 64
    entry[:body].call
  end

  def self.run_all
    LESSONS.each_index { |i| run_one(i) }
  end

  def self.menu
    LESSONS.each_with_index do |entry, i|
      puts format("%02d  %s", i + 1, entry[:name])
    end
  end
end

def show(label, value)
  puts "#{label.to_s.ljust(30)} => #{value.inspect}"
end

def say(text = "")
  puts "-- #{text}" unless text.empty?
end

Study.lesson "Output: puts, print, p, pp" do
  puts "puts adds a newline"
  print "print does not"
  print "\n"
  p "p shows the inspected form"
  p 42, :sym, nil, [1, 2]
  pp({ name: "Ruby", year: 1995, tags: %w[fast fun] })
  puts [1, [2, [3]]]
  puts nil
  puts [nil]
  p nil
  puts "tab\tseparated", 'single quotes keep \t literal'
  puts "a" "b" "c"
  $stdout.puts "explicit stdout"
  $stdout.write("write returns bytes: ", "hi\n")
  show "puts return value", (puts "x")
  show "p return value", (p 5)
  puts "%.2f and %05d and %s" % [3.14159, 42, "text"]
  puts format("%-8s|%8s|", "left", "right")
  puts "Name".ljust(10, ".") + "Value".rjust(10, ".")
  puts "centered".center(30, "*")
end

Study.lesson "Variables, constants, and objects" do
  age = 30
  name = "Ada"
  $global_counter = 0
  show "local", age
  show "string", name
  show "global", $global_counter
  PI_APPROX = 3.14
  show "constant", PI_APPROX
  a = "hello"
  b = a
  b << " world"
  show "a after mutating b", a
  c = a.dup
  c << "!!!"
  show "a after mutating dup", a
  show "same object?", a.equal?(b)
  show "equal values?", a == c
  show "object_id stable", a.object_id == b.object_id
  x, y = 1, 2
  x, y = y, x
  show "swapped", [x, y]
  first, *rest = [10, 20, 30]
  show "first", first
  show "rest", rest
  *init, last = [10, 20, 30]
  show "init", init
  show "last", last
  head, (inner_a, inner_b), tail = 1, [2, 3], 4
  show "nested destructuring", [head, inner_a, inner_b, tail]
  total = 0
  total += 5
  total *= 3
  total -= 1
  total **= 2
  total /= 7
  total %= 10
  show "compound assignment", total
  value = nil
  value ||= "default"
  show "||= sets when nil", value
  value &&= value.upcase
  show "&&= transforms when truthy", value
  frozen = "can't change".freeze
  show "frozen?", frozen.frozen?
  begin
    frozen << "x"
  rescue FrozenError => e
    show "error class", e.class
  end
  show "symbols are frozen", :abc.frozen?
  show "integers are frozen", 42.frozen?
  show "defined? local", defined?(age)
  show "defined? missing", defined?(not_here)
  show "defined? puts", defined?(puts)
  show "defined? constant", defined?(PI_APPROX)
end

Study.lesson "Numbers" do
  show "integer division", 7 / 2
  show "float division", 7 / 2.0
  show "fdiv", 7.fdiv(2)
  show "modulo", 7 % 3
  show "negative modulo", -7 % 3
  show "remainder", -7.remainder(3)
  show "divmod", 17.divmod(5)
  show "power", 2**10
  show "negative power", 2**-1
  show "big integer", 2**100
  show "sqrt", Math.sqrt(144)
  show "integer sqrt", Integer.sqrt(150)
  show "cbrt", Math.cbrt(27)
  show "abs", -42.abs
  show "round", 3.14159.round(2)
  show "round half", 2.5.round
  show "round half even", 2.5.round(half: :even)
  show "ceil", 3.2.ceil
  show "floor", 3.8.floor
  show "truncate", -3.8.truncate
  show "round to tens", 1234.round(-2)
  show "float precision", 0.1 + 0.2
  show "float compare", (0.1 + 0.2 - 0.3).abs < Float::EPSILON
  show "rational", Rational(3, 4) + Rational(1, 4)
  show "rational from literal", 3r / 4
  show "complex", Complex(1, 2) * Complex(3, 4)
  show "to_i", "42abc".to_i
  show "to_f", "3.5xyz".to_f
  show "Integer()", Integer("0x1A", 16) rescue show("Integer() error", "invalid")
  show "Integer base 2", Integer("1010", 2)
  show "to_s base 2", 10.to_s(2)
  show "to_s base 16", 255.to_s(16)
  show "digits", 12345.digits
  show "even?", 4.even?
  show "odd?", 4.odd?
  show "zero?", 0.zero?
  show "positive?", 5.positive?
  show "between?", 5.between?(1, 10)
  show "clamp", 15.clamp(1, 10)
  show "gcd", 12.gcd(18)
  show "lcm", 4.lcm(6)
  show "pred/succ", [5.pred, 5.succ]
  show "bit and", 12 & 10
  show "bit or", 12 | 10
  show "bit xor", 12 ^ 10
  show "shift left", 1 << 4
  show "shift right", 256 >> 2
  show "underscores", 1_000_000
  show "hex literal", 0xff
  show "binary literal", 0b1010
  show "octal literal", 0o17
  show "scientific", 1.5e3
  show "infinity", 1.0 / 0
  show "nan?", (0.0 / 0.0).nan?
  show "min/max float", [Float::MAX > 1e300, Float::MIN > 0]
  show "integer?", [1.integer?, 1.0.integer?]
  show "class of numbers", [1.class, 1.0.class, (2**70).class, 1r.class]
  show "coerce", 1.coerce(2.5)
  show "rand in range", rand(1..6).between?(1, 6)
  srand(42)
  first = rand(100)
  srand(42)
  show "seeded random repeatable", first == rand(100)
  show "number formatting", 1234567.89.round(2).to_s.reverse.scan(/\d{1,3}/).join(",").reverse
  show "thousands separator", 1234567.to_s.gsub(/(\d)(?=(\d{3})+$)/, '\1,')
end

Study.lesson "Strings" do
  s = "Hello, Ruby World"
  show "length", s.length
  show "upcase", s.upcase
  show "downcase", s.downcase
  show "swapcase", s.swapcase
  show "capitalize", "hello world".capitalize
  show "reverse", s.reverse
  show "include?", s.include?("Ruby")
  show "start_with?", s.start_with?("Hell")
  show "end_with?", s.end_with?("World")
  show "index", s.index("Ruby")
  show "rindex", s.rindex("o")
  show "slice by index", s[0]
  show "slice range", s[0..4]
  show "slice start,len", s[7, 4]
  show "slice negative", s[-5..]
  show "slice regex", s[/R\w+/]
  show "sub", s.sub("World", "There")
  show "gsub", s.gsub("o", "0")
  show "gsub block", s.gsub(/[aeiou]/) { |v| v.upcase }
  show "gsub hash", "cat hat".gsub(/[ch]at/, "cat" => "dog", "hat" => "cap")
  show "split", s.split(", ")
  show "split chars", "abc".chars
  show "split limit", "a,b,c,d".split(",", 2)
  show "lines", "one\ntwo\nthree".lines.map(&:chomp)
  show "strip", "  padded  ".strip
  show "lstrip/rstrip", ["  x  ".lstrip, "  x  ".rstrip]
  show "chomp", "line\n".chomp
  show "chop", "hello".chop
  show "chomp suffix", "file.rb".chomp(".rb")
  show "squeeze", "aaabbbccc".squeeze
  show "count", "banana".count("a")
  show "delete", "banana".delete("a")
  show "tr", "hello".tr("el", "ip")
  show "center", "hi".center(10, "*")
  show "repeat", "ab" * 3
  show "concatenate", "a" + "b" + "c"
  show "append", "abc".dup << "def"
  show "prepend", "world".dup.prepend("hello ")
  show "insert", "helo".dup.insert(3, "l")
  show "each_char", "abc".each_char.to_a
  show "bytes", "AB".bytes
  show "ord/chr", ["A".ord, 66.chr]
  show "succ", "az".succ
  show "comparison", "apple" <=> "banana"
  show "eql vs equal", ["a".eql?("a"), "a".equal?("a")]
  show "casecmp?", "Ruby".casecmp?("rUBY")
  show "empty?", "".empty?
  show "unpack-ish scan", "a1b22c333".scan(/\d+/)
  show "scan groups", "k1=v1;k2=v2".scan(/(\w+)=(\w+)/)
  show "partition", "key=value=more".partition("=")
  show "rpartition", "key=value=more".rpartition("=")
  show "format", format("%08.3f", 3.14159)
  show "ljust/rjust", ["ab".ljust(5, "."), "ab".rjust(5, ".")]
  show "unicode length", "héllo".length
  show "unicode bytesize", "héllo".bytesize
  show "encoding", "abc".encoding.to_s
  show "to_sym", "hello world".to_sym
  show "each_slice chars", "abcdefg".chars.each_slice(3).map(&:join)
  show "wrap", "the quick brown fox jumps".scan(/\S.{0,9}(?=\s|$)|\S+/)
  show "palindrome?", "A man a plan a canal Panama".downcase.delete("^a-z").then { |t| t == t.reverse }
  show "title case", "the quick brown fox".split.map(&:capitalize).join(" ")
  show "snake to camel", "my_variable_name".split("_").each_with_index.map { |w, i| i.zero? ? w : w.capitalize }.join
  show "camel to snake", "myVariableName".gsub(/([A-Z])/) { "_#{$1.downcase}" }
  name = "Ruby"
  version = 3.3
  show "interpolation", "#{name} #{version} has #{name.length} letters"
  show "single quote no interp", 'no #{name} here'
  text = <<~TEXT
    Squiggly heredoc
      keeps relative indent
    and strips the common margin
  TEXT
  puts text
  raw = <<~'RAW'
    No #{interpolation} here
  RAW
  puts raw
  show "%w array", %w[one two three]
  show "%q and %Q", [%q(single 'quoted'), %Q(double "quoted" #{1 + 1})]
  show "string multiplication table", (1..3).map { |i| (1..3).map { |j| (i * j).to_s.rjust(2) }.join(" ") }
end

Study.lesson "Symbols" do
  show "symbol", :ruby
  show "to_s", :ruby.to_s
  show "to_proc", %w[a b c].map(&:upcase)
  show "symbols unique", :a.object_id == :a.object_id
  show "strings not unique", "a".object_id == "a".object_id
  show "quoted symbol", :"with space"
  show "symbol comparison", :a <=> :b
  show "symbol length", :hello.length
  show "symbol upcase", :hello.upcase
  show "symbol to proc compose", (:upcase.to_proc >> :reverse.to_proc).call("abc")
  show "%i array", %i[red green blue]
  show "respond_to?", "x".respond_to?(:upcase)
  show "send", 5.send(:+, 3)
  show "public_send", "abc".public_send(:upcase)
  show "method", 5.method(:+).call(10)
  show "all_symbols includes", Symbol.all_symbols.size > 100
end

Study.lesson "Truthiness, nil, and booleans" do
  [0, "", [], {}, nil, false, true, "false"].each do |v|
    show "#{v.inspect} truthy?", v ? true : false
  end
  show "nil.to_a", nil.to_a
  show "nil.to_s", nil.to_s
  show "nil.to_i", nil.to_i
  show "nil.inspect", nil.inspect
  show "nil?", [nil.nil?, 0.nil?]
  user = nil
  show "safe navigation", user&.name
  show "safe navigation chain", user&.name&.upcase
  show "or default", user || "guest"
  show "dig", { a: { b: { c: 1 } } }.dig(:a, :b, :c)
  show "dig missing", { a: {} }.dig(:a, :b, :c)
  show "and", true && false
  show "or", true || false
  show "not", !true
  show "xor", true ^ true
  show "and keyword", (true and false)
  show "combined", (1 > 0 && 2 > 1) || false
  show "spaceship", [1 <=> 2, 2 <=> 2, 3 <=> 2, 1 <=> "a"]
  show "equality types", [1 == 1.0, 1.eql?(1.0), 1.equal?(1)]
  show "case equality", [(1..5) === 3, Integer === 3, /ab/ === "cab", :a === :a]
  show "Array()", [Array(nil), Array([1]), Array(1..3), Array("a")]
  show "String()", String(42)
  show "Float()", Float("3.5")
  show "to_a vs Array", [nil.to_a, Array(nil)]
  show "present", ["", " ", nil].map { |v| v.to_s.strip.empty? ? "blank" : "present" }
end

