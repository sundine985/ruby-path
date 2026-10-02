require "set"
require "json"
require "time"
require "tempfile"
require "securerandom"
require "forwardable"
require "stringio"
require "tmpdir"
require "fileutils"
require "date"

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
Study.lesson "Conditionals" do
  score = 85
  if score >= 90
    grade = "A"
  elsif score >= 80
    grade = "B"
  elsif score >= 70
    grade = "C"
  else
    grade = "F"
  end
  show "if/elsif/else", grade
  show "if as expression", (if score > 50 then "pass" else "fail" end)
  show "unless", (unless score < 50 then "ok" else "low" end)
  show "ternary", score > 80 ? "high" : "low"
  show "modifier if", ("passed" if score > 60)
  show "modifier unless", ("fine" unless score < 60)
  letter = case score
           when 90..100 then "A"
           when 80...90 then "B"
           when 70...80 then "C"
           else "F"
           end
  show "case ranges", letter
  def kind_of_thing(x)
    case x
    when Integer, Float then "number"
    when String then "string"
    when Symbol then "symbol"
    when Array then "array of #{x.size}"
    when Hash then "hash"
    when nil then "nothing"
    when ->(v) { v.respond_to?(:each) } then "enumerable"
    else "unknown"
    end
  end
  [1, 2.5, "s", :s, [1, 2], { a: 1 }, nil, 1..3, Object.new].each do |v|
    show "kind of #{v.inspect[0, 20]}", kind_of_thing(v)
  end
  show "case regex", (case "hello123" when /\d+/ then "has digits" else "no digits" end)
  show "case no subject", (case when score > 80 then "big" else "small" end)
  show "case with splat", (case 3 when *[1, 2, 3] then "in list" end)
  show "nested ternary", score > 90 ? "A" : score > 80 ? "B" : "C"
  show "and/or flow", (score > 50 and score < 100)
  show "comparison chain", (50 < score && score < 100)
  show "if with assignment", (if (m = "abc123".match(/\d+/)) then m[0] end)
  show "empty check", [[], "", {}, nil].map { |v| v.nil? || v.empty? }
  show "between", score.between?(80, 90)
  show "spaceship case", (case score <=> 85 when 0 then "equal" when 1 then "more" else "less" end)
  temperature = 22
  message = if temperature < 10 then "cold"
            elsif temperature < 25 then "pleasant"
            else "hot"
            end
  show "multi-line if value", message
end

Study.lesson "Loops and iteration" do
  i = 0
  while i < 3
    print i, " "
    i += 1
  end
  puts
  until i == 0
    print i, " "
    i -= 1
  end
  puts
  3.times { |n| print n, " " }
  puts
  1.upto(4) { |n| print n, " " }
  puts
  4.downto(1) { |n| print n, " " }
  puts
  0.step(20, 5) { |n| print n, " " }
  puts
  1.0.step(2.0, 0.5) { |n| print n, " " }
  puts
  (1..10).step(3) { |n| print n, " " }
  puts
  for k in 1..3 do print k, " " end
  puts
  loop_count = 0
  loop do
    loop_count += 1
    next if loop_count == 2
    break if loop_count > 4
    print loop_count, " "
  end
  puts
  result = [1, 2, 3, 4].each do |n|
    break n * 100 if n == 3
  end
  show "break with value", result
  begin
    i += 1
  end while i < 3
  show "do-while style", i
  outer = (1..3).each do |a|
    (1..3).each do |b|
      next if b == 2
      print "(#{a},#{b})"
    end
  end
  puts
  show "each returns receiver", outer
  %w[a b c].each_with_index { |v, idx| print "#{idx}:#{v} " }
  puts
  %w[a b c].each.with_index(1) { |v, idx| print "#{idx}:#{v} " }
  puts
  [1, 2, 3].each_with_object([]) { |v, acc| acc << v * 2 }.then { |r| show "each_with_object", r }
  (1..6).each_slice(2) { |pair| print pair.inspect, " " }
  puts
  (1..4).each_cons(2) { |pair| print pair.inspect, " " }
  puts
  [1, 2, 3].cycle.first(7).then { |r| show "cycle", r }
  show "redo-free countdown", 5.downto(1).to_a
  show "until modifier", (n = 0; n += 1 until n >= 5; n)
  show "while modifier", (n = 10; n -= 3 while n > 0; n)
  show "times map", 5.times.map { |x| x * x }
  show "each_char loop", "abc".each_char.map(&:ord)
  show "loop with StopIteration", (e = [1, 2].each; loop { e.next }; "done")
  fib = Enumerator.new do |y|
    a, b = 0, 1
    loop { y << a; a, b = b, a + b }
  end
  show "infinite enumerator take", fib.take(12)
  show "lazy select", fib.lazy.select(&:even?).first(5)
  show "enumerator next", [fib.next, fib.next, fib.next]
  show "with_object", %w[x y].each_with_index.to_h
  show "zip loop", [1, 2, 3].zip(%w[a b c], [true, false, true])
  show "numbered params", [1, 2, 3].map { _1 * 10 }
  show "it param", [1, 2, 3].map { it + 1 } rescue show("it param", "needs Ruby 3.4")
end

Study.lesson "Ranges" do
  show "inclusive", (1..5).to_a
  show "exclusive", (1...5).to_a
  show "chars", ("a".."e").to_a
  show "step", (0..20).step(5).to_a
  show "include?", (1..10).include?(5)
  show "cover?", ("a".."z").cover?("mm")
  show "member? ===", (1..10) === 5.5
  show "sum", (1..100).sum
  show "size", (1...10).size
  show "min/max", [(3..9).min, (3..9).max]
  show "endless", (1..).first(3)
  show "beginless", (..5).include?(3)
  show "reverse", (1..5).reverse_each.to_a
  show "float range", (1.0..2.0).include?(1.5)
  show "to_a on float fails", (begin (1.0..2.0).to_a; rescue TypeError => e; e.class; end)
  show "slice with range", [10, 20, 30, 40, 50][1..3]
  show "slice endless", [10, 20, 30, 40, 50][2..]
  show "slice negative", [10, 20, 30, 40, 50][-3..-2]
  show "string slice", "abcdef"[1..-2]
  show "each_slice range", (1..7).each_slice(3).to_a
  show "range equality", (1..3) == (1..3)
  show "range hash key", { (1..5) => "low", (6..10) => "high" }.find { |r, _| r === 7 }&.last
  show "clamp range", 15.clamp(..10)
  show "date-like range", (Time.at(0).utc.to_i..Time.at(86400).utc.to_i).size
  show "step with float", 0.step(1, 0.25).to_a
  show "% operator", ((1..10) % 3).to_a
  show "minmax", (1..5).minmax
  show "partition", (1..10).partition(&:even?)
  show "group_by", (1..10).group_by { |n| n % 3 }
  show "tally", "mississippi".chars.tally
end

Study.lesson "Arrays" do
  arr = [5, 3, 8, 1, 9, 2]
  show "first/last", [arr.first, arr.last]
  show "first(n)/last(n)", [arr.first(2), arr.last(2)]
  show "index access", [arr[0], arr[-1], arr[10]]
  show "fetch default", arr.fetch(10, :none)
  show "fetch block", arr.fetch(10) { |i| "no #{i}" }
  show "slice", arr[1, 3]
  show "values_at", arr.values_at(0, 2, 4)
  show "take/drop", [arr.take(2), arr.drop(4)]
  show "take_while", arr.take_while { |n| n > 2 }
  show "drop_while", arr.drop_while { |n| n > 2 }
  show "sorted", arr.sort
  show "sorted desc", arr.sort.reverse
  show "sort_by", %w[pear fig banana].sort_by(&:length)
  show "sort_by multi", %w[pear fig apple kiwi].sort_by { |w| [w.length, w] }
  show "min/max", [arr.min, arr.max]
  show "min(n)", arr.min(2)
  show "minmax", arr.minmax
  show "sum", arr.sum
  show "average", arr.sum.fdiv(arr.size).round(2)
  show "reverse", arr.reverse
  show "rotate", arr.rotate(2)
  show "include?", arr.include?(8)
  show "index/find_index", [arr.index(8), arr.find_index { |n| n > 5 }]
  show "count", [arr.count, arr.count(&:even?), arr.count(3)]
  show "uniq", [1, 1, 2, 3, 3].uniq
  show "compact", [1, nil, 2, nil].compact
  show "flatten", [1, [2, [3, [4]]]].flatten
  show "flatten(1)", [1, [2, [3, [4]]]].flatten(1)
  show "zip", [1, 2, 3].zip(%w[a b c])
  show "transpose", [[1, 2], [3, 4], [5, 6]].transpose
  show "product", [1, 2].product(%w[a b])
  show "combination", [1, 2, 3].combination(2).to_a
  show "permutation", [1, 2, 3].permutation(2).count
  show "each_slice", (1..6).each_slice(2).to_a
  show "union", [1, 2, 3] | [3, 4]
  show "intersection", [1, 2, 3] & [2, 3, 4]
  show "difference", [1, 2, 3] - [2]
  show "concat plus", [1, 2] + [3]
  show "repeat", [0] * 3
  show "join", [1, 2, 3].join("-")
  show "sample in", arr.include?(arr.sample)
  show "shuffle size", arr.shuffle.size
  show "shuffle seeded", arr.shuffle(random: Random.new(1)).size
  show "assoc", [[:a, 1], [:b, 2]].assoc(:b)
  show "dig", [[1, [2, 3]]].dig(0, 1, 0)
  show "bsearch", [1, 3, 5, 7, 9].bsearch { |x| x >= 4 }
  show "sum of floats", [0.1, 0.2, 0.3].sum
  show "inject sum", arr.inject(:+)
  show "inject block", arr.inject { |memo, x| memo > x ? memo : x }
  show "reduce with init", arr.reduce(100) { |memo, x| memo - x }
  show "each_cons", [1, 2, 3, 4].each_cons(2).map { |a, b| b - a }
  show "chunk_while", [1, 2, 4, 5, 7].chunk_while { |a, b| b == a + 1 }.to_a
  show "slice_when", [1, 2, 4, 5, 7].slice_when { |a, b| b != a + 1 }.to_a
  show "partition", arr.partition(&:even?)
  show "group_by", arr.group_by { |n| n.odd? ? :odd : :even }
  show "each_with_index", %w[a b].each_with_index.to_a
  show "find", arr.find { |n| n > 5 }
  show "find_all", arr.find_all(&:odd?)
  show "reject", arr.reject(&:odd?)
  show "all/any/none/one", [arr.all?(Integer), arr.any?(&:zero?), arr.none?(&:negative?), arr.one? { |n| n == 9 }]
  show "flat_map", [[1, 2], [3]].flat_map { |x| x.map { |y| y * 2 } }
  show "filter_map", arr.filter_map { |n| n * 2 if n.odd? }
  show "sum with block", arr.sum { |n| n * n }
  show "tally", %w[a b a c a].tally
  show "tally_by", (1..10).tally_by(&:even?)
  show "zip to_h", %w[a b c].zip([1, 2, 3]).to_h
  show "each_entry", [1, 2].each_entry.to_a
  mutable = [1, 2, 3]
  mutable << 4
  mutable.push(5, 6)
  mutable.unshift(0)
  mutable.insert(3, :x)
  show "after adds", mutable
  show "pop", mutable.pop
  show "shift", mutable.shift
  show "delete", mutable.delete(:x)
  show "delete_at", mutable.delete_at(0)
  show "delete_if", mutable.delete_if(&:even?)
  show "clear", mutable.clear
  matrix = Array.new(3) { |r| Array.new(3) { |c| r * 3 + c } }
  show "matrix", matrix
  show "matrix diagonal", (0..2).map { |i| matrix[i][i] }
  show "matrix column sums", matrix.transpose.map(&:sum)
  shared = Array.new(2, [])
  shared[0] << 1
  show "shared reference pitfall", shared
  show "Array.new block", Array.new(4) { |i| i * i }
  show "fill", Array.new(3).fill(7)
  show "splat build", [*1..3, *%w[a b]]
  show "pack/unpack", [65, 66].pack("c*")
  show "sum strings", %w[a b c].sum("")
  show "cycle take", [1, 2].cycle.take(5)
  show "step slicing", (0..10).to_a.each_slice(5).map(&:first)
end

Study.lesson "Hashes" do
  h = { "name" => "Ada", "age" => 36 }
  sym = { name: "Ada", age: 36, langs: %w[ruby c] }
  show "string keys", h["name"]
  show "symbol keys", sym[:name]
  show "missing key", sym[:nope]
  show "fetch", sym.fetch(:age)
  show "fetch default", sym.fetch(:nope, 0)
  show "fetch block", sym.fetch(:nope) { |k| "no #{k}" }
  show "dig", { a: { b: [10, 20] } }.dig(:a, :b, 1)
  show "key?", sym.key?(:name)
  show "value?", sym.value?(36)
  show "keys", sym.keys
  show "values", sym.values
  show "size", sym.size
  show "to_a", sym.to_a.first
  show "map to hash", sym.to_h { |k, v| [k.to_s, v] }
  show "transform_values", { a: 1, b: 2 }.transform_values { |v| v * 10 }
  show "transform_keys", { a: 1, b: 2 }.transform_keys(&:to_s)
  show "select", sym.select { |_, v| v.is_a?(Integer) }
  show "reject", sym.reject { |k, _| k == :langs }
  show "filter_map", sym.filter_map { |k, v| k if v.is_a?(String) }
  show "min_by", { a: 3, b: 1, c: 2 }.min_by { |_, v| v }
  show "max_by", { a: 3, b: 1, c: 2 }.max_by { |_, v| v }
  show "sort_by value", { a: 3, b: 1, c: 2 }.sort_by { |_, v| v }.to_h
  show "sum values", { a: 3, b: 1, c: 2 }.values.sum
  show "sum block", { a: 3, b: 1 }.sum { |_, v| v }
  show "merge", { a: 1, b: 2 }.merge({ b: 3, c: 4 })
  show "merge block", { a: 1, b: 2 }.merge({ b: 3 }) { |_, old, new| old + new }
  show "slice", sym.slice(:name, :age)
  show "except", sym.except(:langs)
  show "invert", { a: 1, b: 2 }.invert
  show "group_by", %w[apple avocado banana blueberry].group_by { |w| w[0] }
  show "partition", { a: 1, b: 2, c: 3 }.partition { |_, v| v.odd? }.map(&:to_h)
  show "count", { a: 1, b: 2, c: 3 }.count { |_, v| v > 1 }
  show "find", { a: 1, b: 2 }.find { |_, v| v == 2 }
  show "any?/all?", [{ a: 1 }.any? { |_, v| v > 0 }, { a: 1 }.all? { |_, v| v > 5 }]
  show "each_pair", sym.each_pair.map { |k, v| "#{k}=#{v}" }
  show "default value", Hash.new(0).tap { |c| "hello".each_char { |ch| c[ch] += 1 } }
  show "default block", Hash.new { |hash, k| hash[k] = [] }.tap { |g| g[:x] << 1; g[:x] << 2 }
  show "nested default", Hash.new { |hash, k| hash[k] = Hash.new(0) }.tap { |g| g[:a][:b] += 1 }
  show "compare_by_identity", {}.compare_by_identity.tap { |c| c["a"] = 1; c["a".dup] = 2 }.size
  show "zip to hash", %i[a b c].zip([1, 2, 3]).to_h
  show "each_with_object", %w[a bb ccc].each_with_object({}) { |w, acc| acc[w] = w.size }
  show "sort_by multiple", { b: 1, a: 1, c: 0 }.sort_by { |k, v| [v, k] }
  show "delete", sym.dup.tap { |c| c.delete(:langs) }
  show "delete_if", { a: 1, b: 2 }.delete_if { |_, v| v > 1 }
  show "compact", { a: nil, b: 1 }.compact
  show "to_a flatten", { a: 1, b: 2 }.to_a.flatten
  show "store/update", { a: 1 }.tap { |c| c.store(:b, 2); c.update(c: 3) }
  show "keyword shorthand", (x = 1; y = 2; { x:, y: })
  show "key lookup by value", { a: 1, b: 2 }.key(2)
  show "find all keys", { a: 1, b: 1, c: 2 }.select { |_, v| v == 1 }.keys
  show "reduce", { a: 1, b: 2, c: 3 }.reduce(0) { |sum, (_, v)| sum + v }
  show "flat_map", { a: [1, 2], b: [3] }.flat_map { |_, v| v }
  show "to_json", JSON.generate(sym)
  show "from_json", JSON.parse('{"a":[1,2],"b":{"c":null}}', symbolize_names: true)
  show "pretty json", JSON.pretty_generate({ a: 1 }).lines.size
  show "frozen literal", { a: 1 }.freeze.frozen?
  show "insertion order", { z: 1, a: 2, m: 3 }.keys
  show "default proc present", Hash.new { 1 }.default_proc.nil?
end

Study.lesson "Sets" do
  a = Set.new([1, 2, 3, 3, 2])
  b = Set[3, 4, 5]
  show "set", a
  show "add", a.dup.add(10)
  show "add? duplicate", a.dup.add?(1)
  show "include?", a.include?(2)
  show "union", a | b
  show "intersection", a & b
  show "difference", a - b
  show "symmetric", a ^ b
  show "subset?", Set[1, 2].subset?(a)
  show "superset?", a.superset?(Set[1])
  show "disjoint?", a.disjoint?(Set[9])
  show "to_a sorted", (a | b).to_a.sort
  show "map returns array", a.map { |x| x * 2 }
  show "group", a.group_by(&:odd?)
  show "dedupe words", "the cat and the hat and the bat".split.to_set.size
  show "each_with_object", %w[a b a].each_with_object(Set.new) { |x, s| s << x }.size
end
Study.lesson "Methods" do
  def greet(name = "world", punctuation: "!", **extras)
    base = "Hello, #{name}#{punctuation}"
    extras.empty? ? base : "#{base} #{extras}"
  end
  show "default", greet
  show "positional", greet("Ada")
  show "keyword", greet("Ada", punctuation: "?")
  show "extra keywords", greet("Ada", mood: :happy)
  def sum_all(*numbers) = numbers.sum
  show "splat", sum_all(1, 2, 3, 4)
  show "splat array", sum_all(*[5, 6, 7])
  def stats(values)
    [values.min, values.max, values.sum.fdiv(values.size)]
  end
  low, high, mean = stats([2, 4, 9])
  show "multiple returns", [low, high, mean]
  def implicit_return(x)
    x * 2
  end
  show "implicit return", implicit_return(21)
  def early_return(x)
    return "negative" if x < 0
    return "zero" if x.zero?
    "positive"
  end
  show "early return", [-1, 0, 1].map { |n| early_return(n) }
  def required_kw(a:, b: 2) = a + b
  show "required keyword", required_kw(a: 1)
  begin
    required_kw
  rescue ArgumentError => e
    show "missing keyword error", e.message
  end
  def mixed(a, b = 2, *rest, c, d: 4, **opts, &blk)
    [a, b, rest, c, d, opts, blk&.call]
  end
  show "mixed args", mixed(1, 9, 3, 4, 5, d: 0, z: 1) { :block }
  def question?(x) = x > 10
  def bang!(arr) = arr.map!(&:to_s)
  show "predicate", question?(11)
  data = [1, 2]
  bang!(data)
  show "bang mutates", data
  def counter
    @count ||= 0
    @count += 1
  end
  show "instance state on main", [counter, counter, counter]
  def fact(n) = n <= 1 ? 1 : n * fact(n - 1)
  show "recursion", fact(10)
  def fib_memo(n, memo = {})
    return n if n < 2
    memo[n] ||= fib_memo(n - 1, memo) + fib_memo(n - 2, memo)
  end
  show "memoized fib", fib_memo(60)
  def hanoi(n, from, to, via, moves = [])
    return moves if n.zero?
    hanoi(n - 1, from, via, to, moves)
    moves << [from, to]
    hanoi(n - 1, via, to, from, moves)
  end
  show "hanoi moves", hanoi(3, :a, :c, :b).size
  def flatten_deep(list) = list.flat_map { |x| x.is_a?(Array) ? flatten_deep(x) : [x] }
  show "recursive flatten", flatten_deep([1, [2, [3, [4]]]])
  def power_set(s) = s.empty? ? [[]] : power_set(s[1..]).flat_map { |x| [x, [s[0]] + x] }
  show "power set", power_set([1, 2, 3]).sort
  show "method object", method(:fact).call(5)
  show "arity", [method(:fact).arity, method(:greet).arity, method(:sum_all).arity]
  show "parameters", method(:required_kw).parameters
  show "method owner", method(:fact).owner
  show "respond_to private", respond_to?(:fact, true)
  def with_ensure
    yield
  ensure
    puts "ensure always runs"
  end
  with_ensure { puts "inside" }
  def gcd_euclid(a, b) = b.zero? ? a : gcd_euclid(b, a % b)
  show "euclid", gcd_euclid(48, 18)
  def prime?(n) = n > 1 && (2..Integer.sqrt(n)).none? { |d| (n % d).zero? }
  show "primes under 30", (1..30).select { |n| prime?(n) }
  def collatz(n, steps = 0) = n == 1 ? steps : collatz(n.even? ? n / 2 : 3 * n + 1, steps + 1)
  show "collatz 27", collatz(27)
  def binary_search(list, target)
    low, high = 0, list.size - 1
    while low <= high
      mid = (low + high) / 2
      case list[mid] <=> target
      when 0 then return mid
      when -1 then low = mid + 1
      else high = mid - 1
      end
    end
    nil
  end
  show "binary search", binary_search([1, 3, 5, 7, 9, 11], 7)
end

Study.lesson "Blocks, procs, lambdas, closures" do
  def twice
    yield 1
    yield 2
  end
  twice { |n| print "got #{n} " }
  puts
  def maybe_block
    return "no block" unless block_given?
    yield
  end
  show "block_given?", [maybe_block, maybe_block { "yes" }]
  def explicit(&blk) = blk
  captured = explicit { |x| x * 3 }
  show "captured block", captured.call(4)
  show "block class", captured.class
  square = proc { |x| (x || 0)**2 }
  cube = lambda { |x| x**3 }
  stabby = ->(x, y = 1) { x + y }
  show "proc", square.call(4)
  show "proc extra args ok", square.call(4, 5)
  show "proc nil arg", square.call
  show "lambda", cube.(3)
  show "lambda brackets", cube[2]
  show "stabby default", stabby.call(1)
  show "lambda?", [square.lambda?, cube.lambda?]
  begin
    cube.call(1, 2)
  rescue ArgumentError => e
    show "lambda strict arity", e.message
  end
  def run_proc
    p = proc { return :from_proc }
    p.call
    :after
  end
  def run_lambda
    l = -> { return :from_lambda }
    l.call
    :after
  end
  show "return in proc", run_proc
  show "return in lambda", run_lambda
  counter = 0
  increment = -> { counter += 1 }
  3.times { increment.call }
  show "closure sees variable", counter
  def make_counter
    count = 0
    { inc: -> { count += 1 }, dec: -> { count -= 1 }, get: -> { count } }
  end
  c = make_counter
  c[:inc].call
  c[:inc].call
  c[:dec].call
  show "closure counter", c[:get].call
  adder = ->(a) { ->(b) { a + b } }
  show "currying by hand", adder.(2).(3)
  show "curry", ->(a, b, c) { a + b + c }.curry[1][2][3]
  double = ->(x) { x * 2 }
  inc = ->(x) { x + 1 }
  show "compose >>", (double >> inc).call(5)
  show "compose <<", (double << inc).call(5)
  show "method to proc", %w[1 2 3].map(&method(:Integer))
  show "symbol to proc", [[1, 2], [3]].map(&:size)
  show "yield multiple", (def pair; yield :a, :b; end; pair { |x, y| [y, x] })
  show "block local var", (x = 10; [1].each { |i; x| x = i }; x)
  def each_pair_custom
    return to_enum(:each_pair_custom) unless block_given?
    yield :k1, 1
    yield :k2, 2
  end
  show "to_enum", each_pair_custom.to_a
  def timed
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    value = yield
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    [value, elapsed >= 0]
  end
  show "timing wrapper", timed { (1..1000).sum }
  def retry_times(limit)
    attempts = 0
    begin
      attempts += 1
      yield attempts
    rescue RuntimeError
      retry if attempts < limit
      :gave_up
    end
  end
  show "retry", retry_times(3) { |n| n < 3 ? raise("fail") : "ok on #{n}" }
  memo = Hash.new { |h, n| h[n] = n < 2 ? n : h[n - 1] + h[n - 2] }
  show "hash memo fib", memo[80]
  pipeline = [->(s) { s.strip }, ->(s) { s.downcase }, ->(s) { s.tr(" ", "-") }]
  show "pipeline", pipeline.reduce("  Hello Big World ") { |acc, fn| fn.call(acc) }
  show "then", 5.then { |x| x + 1 }.then { |x| x * 2 }
  show "tap", [1, 2, 3].tap { |a| puts "tapped #{a.size}" }.sum
  show "instance_exec", "abc".instance_exec(2) { |n| self * n }
  show "Proc.new arity", [proc { |a, b| }.arity, lambda { |a, b| }.arity, proc { |*a| }.arity]
  show "ObjectSpace-free", binding.local_variable_defined?(:counter)
end

Study.lesson "Enumerable toolbox" do
  words = %w[banana apple cherry date elderberry fig grape]
  show "map", words.map(&:length)
  show "select", words.select { |w| w.length > 5 }
  show "sort_by length desc", words.sort_by { |w| -w.length }
  show "max_by", words.max_by(&:length)
  show "min_by", words.min_by(&:length)
  show "group_by first", words.group_by { |w| w[0] }.select { |_, v| v.size > 1 }
  show "partition", words.partition { |w| w.include?("e") }
  show "each_slice", words.each_slice(3).map(&:first)
  show "zip index", words.each_with_index.map { |w, i| "#{i}:#{w}" }.first(3)
  show "inject longest", words.inject { |a, b| a.length >= b.length ? a : b }
  show "sum lengths", words.sum(&:length)
  show "chunk_while", words.chunk_while { |a, b| a.length <= b.length }.to_a
  show "tally by length", words.map(&:length).tally.sort.to_h
  show "min/max pair", words.minmax_by(&:length)
  show "take_while", words.take_while { |w| w != "date" }
  show "find_index", words.find_index("fig")
  show "each_cons", words.each_cons(2).count { |a, b| a < b }
  show "uniq by", words.uniq { |w| w.length }
  show "flat chars", words.first(2).flat_map(&:chars).tally.max_by { |_, v| v }
  show "zip sums", [1, 2, 3].zip([4, 5, 6]).map(&:sum)
  show "lazy pipeline", (1..Float::INFINITY).lazy.map { |n| n * n }.select(&:even?).first(4)
  show "lazy eager", (1..20).lazy.select(&:even?).map { |n| n * 3 }.reject { |n| n % 4 == 0 }.to_a
  show "sum range squares", (1..10).sum { |n| n**2 }
  show "reduce product", (1..6).reduce(:*)
  show "step sums", (1..10).each_slice(3).map(&:sum)
  show "frequency top 2", "the rain in spain stays mainly in the plain".split.tally.sort_by { |w, c| [-c, w] }.first(2)
  show "anagrams", %w[listen silent enlist google gogole].group_by { |w| w.chars.sort.join }.values.select { |g| g.size > 1 }
  show "run length encode", "aaabccdddd".chars.chunk_while { |a, b| a == b }.map { |g| "#{g[0]}#{g.size}" }.join
  show "matrix multiply", [[1, 2], [3, 4]].then { |m| m.map { |row| m.transpose.map { |col| row.zip(col).sum { |a, b| a * b } } } }
  show "pascal row", (0..5).reduce([1]) { |row, _| [0, *row].zip([*row, 0]).map(&:sum) }
  show "fizzbuzz", (1..15).map { |n| n % 15 == 0 ? "FizzBuzz" : n % 5 == 0 ? "Buzz" : n % 3 == 0 ? "Fizz" : n }
  show "sieve", (2..30).each_with_object((2..30).to_a) { |n, acc| acc.reject! { |m| m > n && (m % n).zero? } }
  show "word lengths hash", words.to_h { |w| [w, w.length] }.select { |_, l| l == 5 }
  show "each_entry zip", words.each_slice(2).to_h { |a, b| [a, b] }
  show "sort stable-ish", words.sort_by.with_index { |w, i| [w.length, i] }
end

Study.lesson "Classes and objects" do
  class Person
    attr_reader :name, :age
    attr_accessor :email
    @@population = 0
    SPECIES = "human"

    def initialize(name, age, email: nil)
      @name = name
      @age = age
      @email = email
      @@population += 1
    end

    def self.population = @@population

    def self.from_string(text)
      name, age = text.split(",")
      new(name.strip, age.to_i)
    end

    def adult? = age >= 18

    def birthday!
      @age += 1
      self
    end

    def to_s = "#{name} (#{age})"

    def inspect = "#<Person #{name}>"

    def ==(other) = other.is_a?(Person) && name == other.name && age == other.age

    alias_method :eql?, :==

    def hash = [name, age].hash

    def <=>(other) = age <=> other.age

    include Comparable

    def introduce
      "Hi, I'm #{name} and I'm #{age}. #{secret_note}"
    end

    protected

    def private_age = @age

    private

    def secret_note = "I like Ruby."
  end

  ada = Person.new("Ada", 36, email: "ada@example.com")
  bob = Person.from_string("Bob, 17")
  show "to_s", ada.to_s
  show "string interpolation", "#{bob}"
  show "inspect", ada
  show "adult?", [ada.adult?, bob.adult?]
  show "birthday chain", bob.birthday!.birthday!.age
  show "population", Person.population
  show "constant", Person::SPECIES
  show "accessor", (ada.email = "new@example.com"; ada.email)
  show "comparable", [ada > bob, ada.between?(bob, ada), [ada, bob].min.name]
  show "clamp", bob.clamp(bob, ada).name
  show "equality", Person.new("Ada", 36) == ada
  show "hash key", { ada => 1 }[Person.new("Ada", 36)]
  show "uniq with eql", [ada, Person.new("Ada", 36)].uniq.size
  show "introduce uses private", ada.introduce
  begin
    ada.secret_note
  rescue NoMethodError => e
    show "private error", e.message[0, 40]
  end
  show "send bypasses private", ada.send(:secret_note)
  show "instance_variables", ada.instance_variables
  show "instance_variable_get", ada.instance_variable_get(:@name)
  show "methods defined", (Person.instance_methods(false) - Object.instance_methods).sort.first(6)
  show "is_a?", [ada.is_a?(Person), ada.is_a?(Comparable), ada.kind_of?(Object), ada.instance_of?(Object)]
  show "class", ada.class
  show "ancestors", Person.ancestors.first(3)
  show "respond_to?", ada.respond_to?(:birthday!)
  show "frozen dup", ada.dup.equal?(ada)
  show "singleton method", (def ada.shout = name.upcase; ada.shout)
  show "singleton_methods", ada.singleton_methods
  show "define class dynamically", Class.new { def hi = "hi" }.new.hi
  class Person
    def greet_again = "again, #{name}"
  end
  show "reopen class", ada.greet_again
  class Integer
    def double = self * 2
  end
  show "monkey patch", 21.double
  class Temperature
    include Comparable
    attr_reader :degrees
    def initialize(degrees) = @degrees = degrees
    def <=>(other) = degrees <=> other.degrees
    def succ = Temperature.new(degrees + 1)
    def to_s = "#{degrees}°"
    def coerce(num) = [Temperature.new(num), self]
    def +(other) = Temperature.new(degrees + (other.respond_to?(:degrees) ? other.degrees : other))
    def -@
      Temperature.new(-degrees)
    end
    def [](i)
      degrees.digits[i]
    end
    def call(x) = degrees * x
    def to_proc = ->(x) { x + degrees }
    def each
      return enum_for(:each) unless block_given?
      yield degrees
      yield degrees + 1
    end
  end
  t = Temperature.new(20)
  show "operator +", (t + 5).to_s
  show "unary minus", (-t).to_s
  show "index operator", t[0]
  show "call sugar", t.(3)
  show "to_proc", [1, 2].map(&t)
  show "range of custom", (Temperature.new(1)..Temperature.new(4)).map(&:to_s)
end

Study.lesson "Inheritance, modules, and mixins" do
  class Animal
    attr_reader :name
    def initialize(name) = @name = name
    def speak = "..."
    def describe = "#{self.class.name.downcase} #{name} says #{speak}"
    def <=>(other) = name <=> other.name
    include Comparable
  end

  class Dog < Animal
    def initialize(name, tricks = [])
      super(name)
      @tricks = tricks
    end
    def speak = "Woof"
    def tricks = @tricks.dup
  end

  class Cat < Animal
    def speak = "Meow"
    def describe = super + " (and ignores you)"
  end

  class Puppy < Dog
    def speak = super.downcase + "!"
  end

  animals = [Dog.new("Rex", %w[sit roll]), Cat.new("Tom"), Puppy.new("Bit")]
  animals.each { |a| puts a.describe }
  show "superclass chain", Puppy.ancestors.take(4)
  show "superclass", Puppy.superclass
  show "sorted", animals.sort.map(&:name)
  show "instance_of vs kind_of", [animals[2].instance_of?(Dog), animals[2].is_a?(Dog)]
  show "subclasses", Animal.subclasses.map(&:name).sort
  show "method resolution", Puppy.instance_method(:speak).owner

  module Swimmer
    def swim = "#{name} swims"
  end

  module Walker
    def walk = "#{name} walks"
    def self.included(base) = base.extend(ClassMethods)
    module ClassMethods
      def walkers = @walkers ||= []
    end
  end

  module Loud
    def speak = super.upcase + "!!"
  end

  class Dog
    include Swimmer
    include Walker
  end

  rex = animals.first
  show "mixin methods", [rex.swim, rex.walk]
  show "class methods via included", Dog.walkers
  show "ancestors with modules", Dog.ancestors.take(4)
  show "include?", Dog.include?(Swimmer)
  loud_cat = Cat.new("Leo").extend(Loud)
  show "extend on instance", loud_cat.speak
  class Cat
    prepend(Module.new { def speak = "[#{super}]" })
  end
  show "prepend", Cat.new("Zed").speak

  module Greeter
    def self.hello(name) = "Hello, #{name}"
    PREFIX = "Mr."
    def self.formal(name) = "#{PREFIX} #{name}"
  end
  show "module function", [Greeter.hello("Ada"), Greeter.formal("Babbage")]

  module Util
    module_function
    def clamp01(x) = x.clamp(0.0, 1.0)
    def percent(part, whole) = (part * 100.0 / whole).round(1)
  end
  show "module_function", [Util.clamp01(1.5), Util.percent(1, 3)]

  class Shape
    def area = raise(NotImplementedError, "#{self.class} must implement area")
    def to_s = format("%s with area %.2f", self.class.name, area)
  end
  class Circle < Shape
    def initialize(r) = @r = r
    def area = Math::PI * @r**2
  end
  class Rect < Shape
    def initialize(w, h) = (@w, @h = w, h)
    def area = @w * @h
  end
  [Circle.new(1.5), Rect.new(2, 3)].each { |s| puts s }
  show "abstract error", (begin Shape.new.area; rescue NotImplementedError => e; e.message; end)
  show "duck typing", [Circle.new(1), Rect.new(1, 1), "str"].map { |o| o.respond_to?(:area) ? o.area.round(2) : :no_area }

  class Stack
    include Enumerable
    extend Forwardable
    def_delegators :@items, :size, :empty?, :last
    def initialize(*items) = @items = items
    def push(x) = tap { @items.push(x) }
    def pop = @items.pop
    def each(&) = @items.reverse.each(&)
  end
  stack = Stack.new(1, 2, 3).push(4)
  show "Enumerable via each", stack.map { |x| x * 2 }
  show "enumerable select", stack.select(&:even?)
  show "enumerable sort", stack.sort
  show "enumerable min", stack.min
  show "enumerable include", stack.include?(3)
  show "enumerable first", stack.first(2)
  show "enumerable lazy", stack.lazy.map { |x| x + 1 }.first(2)
  show "delegation", [stack.size, stack.empty?, stack.last]
  show "each_slice from enumerable", stack.each_slice(2).to_a
  show "reduce from enumerable", stack.reduce(:+)
  show "zip from enumerable", stack.zip(stack.map { |x| x * 10 }).first(2)
end

Study.lesson "Structs, Data, and OpenStruct-like objects" do
  Point = Struct.new(:x, :y) do
    def distance_to(other) = Math.hypot(x - other.x, y - other.y)
    def to_s = "(#{x}, #{y})"
  end
  a = Point.new(0, 0)
  b = Point.new(3, 4)
  show "struct", a
  show "distance", a.distance_to(b)
  show "to_a", b.to_a
  show "to_h", b.to_h
  show "members", Point.members
  show "equality", Point.new(1, 2) == Point.new(1, 2)
  show "mutable", (a.x = 10; a.x)
  show "destructure", (x, y = *b; [x, y])
  show "each", b.each.to_a
  show "dig", Struct.new(:inner).new({ k: 1 }).dig(:inner, :k)
  Config = Struct.new(:host, :port, keyword_init: true)
  show "keyword_init", Config.new(host: "localhost", port: 80)
  if defined?(Data)
    Coord = Data.define(:lat, :lng) do
      def to_s = format("%.2f,%.2f", lat, lng)
    end
    c = Coord.new(lat: 1.5, lng: 2.5)
    show "Data", c
    show "Data with", c.with(lat: 9)
    show "Data to_h", c.to_h
    show "Data frozen", c.frozen?
    show "Data positional", Coord.new(1, 2)
    show "Data to_s", c.to_s
    show "Data error", (begin Coord.new(1); rescue ArgumentError => e; e.class; end)
  end
  show "struct as hash key", { Point.new(1, 1) => :a }[Point.new(1, 1)]
  show "sort structs", [Point.new(3, 1), Point.new(1, 2)].sort_by(&:x).map(&:to_s)
  show "struct in array", [Point.new(1, 2), Point.new(3, 4)].sum(&:x)
  show "struct inspect", Point.new(5, 6).inspect
  show "struct values_at", Point.new(5, 6).values_at(0, 1)
  show "struct deconstruct", (case Point.new(1, 2); in [x, y] then x + y; end)
  show "struct deconstruct_keys", (case Point.new(1, 2); in { x:, y: } then x * y; end)
end
Study.lesson "Exceptions" do
  begin
    Integer("abc")
  rescue ArgumentError => e
    show "rescued", e.message
  end
  begin
    1 / 0
  rescue ZeroDivisionError => e
    show "zero division", e.message
  end
  begin
    nil.upcase
  rescue NoMethodError => e
    show "nil error", e.message[0, 30]
  end
  begin
    [1].fetch(5)
  rescue IndexError => e
    show "index error", e.message
  end
  begin
    { a: 1 }.fetch(:b)
  rescue KeyError => e
    show "key error", [e.message, e.key]
  end
  begin
    raise "plain runtime error"
  rescue => e
    show "default rescue class", e.class
  end
  class AppError < StandardError
    def initialize(msg = "application failed") = super
  end
  class ValidationError < AppError
    attr_reader :field
    def initialize(field, msg = nil)
      @field = field
      super(msg || "#{field} is invalid")
    end
  end
  begin
    raise ValidationError.new(:email)
  rescue AppError => e
    show "custom hierarchy", [e.class, e.field, e.message]
  end
  begin
    raise AppError
  rescue AppError => e
    show "default message", e.message
  end
  def risky(kind)
    case kind
    when :arg then raise ArgumentError, "bad arg"
    when :type then raise TypeError, "bad type"
    when :ok then "fine"
    else raise "unknown"
    end
  rescue ArgumentError, TypeError => e
    "handled #{e.class}"
  rescue => e
    "fallback #{e.message}"
  else
    "no error"
  ensure
    print "[ensure #{kind}] "
  end
  puts
  show "method-level rescue", %i[arg type ok other].map { |k| risky(k) }
  attempts = 0
  begin
    attempts += 1
    raise "flaky" if attempts < 3
    show "retry succeeded after", attempts
  rescue
    retry
  end
  begin
    begin
      raise "inner"
    rescue => e
      raise ArgumentError, "outer"
    end
  rescue => e
    show "cause", e.cause&.message
  end
  show "raise returns via rescue modifier", (Integer("x") rescue -1)
  show "backtrace present", (begin raise "x"; rescue => e; e.backtrace.is_a?(Array); end)
  show "full_message", (begin raise "boom"; rescue => e; e.full_message(highlight: false).include?("boom"); end)
  show "exception hierarchy", [ZeroDivisionError.ancestors.take(3), KeyError.superclass, NoMethodError.superclass]
  result = catch(:found) do
    (1..3).each { |i| (1..3).each { |j| throw :found, [i, j] if i * j == 6 } }
    nil
  end
  show "catch/throw", result
  show "ensure ordering", (
    log = []
    begin
      log << :start
      raise "x"
    rescue
      log << :rescue
    else
      log << :else
    ensure
      log << :ensure
    end
    log
  )
  show "raise with class and message", (begin raise TypeError, "wrong"; rescue => e; [e.class, e.message]; end)
  show "exception equality", (StandardError.new("a").message == "a")
  show "Timeout-free guard", (Float("1.5e3") rescue :bad)
  show "exit-safe at_exit registered", (at_exit {}; true)
  show "warn goes to stderr", (warn("this goes to stderr"); true)
  show "raise frozen", (begin "x".freeze << "y"; rescue FrozenError => e; e.class; end)
  show "stop iteration", (begin [].each.next; rescue StopIteration => e; e.class; end)
  show "uncaught in thread", (t = Thread.new { Thread.current.report_on_exception = false; raise "thread boom" }; begin t.join; rescue => e; e.message; end)
  def validate_age(age)
    raise TypeError, "age must be an Integer" unless age.is_a?(Integer)
    raise ArgumentError, "age must be positive" unless age.positive?
    age
  end
  [25, -1, "x"].each do |input|
    begin
      show "validate #{input.inspect}", validate_age(input)
    rescue TypeError, ArgumentError => e
      show "validate #{input.inspect}", "#{e.class}: #{e.message}"
    end
  end
end

Study.lesson "Files, IO, and JSON" do
  file = Tempfile.new(["study", ".txt"])
  path = file.path
  file.close
  File.write(path, "line one\nline two\nline three\n")
  show "exists", File.exist?(path)
  show "size", File.size(path)
  show "read", File.read(path)
  show "readlines", File.readlines(path, chomp: true)
  show "foreach", File.foreach(path).map(&:chomp).map(&:upcase)
  show "each_line with index", File.foreach(path).with_index(1).map { |l, i| "#{i}: #{l.chomp}" }
  File.open(path, "a") { |f| f.puts "line four"; f.print "five"; f.write("\n") }
  show "after append", File.readlines(path, chomp: true).size
  File.open(path) do |f|
    show "gets", f.gets.chomp
    show "read rest size", f.read.size
    show "eof?", f.eof?
    f.rewind
    show "rewind then readline", f.readline.chomp
  end
  show "basename", File.basename("/a/b/file.rb")
  show "basename no ext", File.basename("/a/b/file.rb", ".rb")
  show "extname", File.extname("archive.tar.gz")
  show "dirname", File.dirname("/a/b/file.rb")
  show "join", File.join("a", "b", "c.txt")
  show "expand_path abs", File.expand_path("x", "/tmp")
  show "file?/directory?", [File.file?(path), File.directory?(File.dirname(path))]
  show "mtime class", File.mtime(path).class
  show "word count", File.read(path).split.size
  show "line lengths", File.readlines(path, chomp: true).map(&:length)
  show "grep lines", File.readlines(path, chomp: true).grep(/t/)
  show "grep_v", File.readlines(path, chomp: true).grep_v(/t/)
  show "grep with block", File.readlines(path).grep(/line (\w+)/) { $1 }
  show "string IO", (require "stringio"; io = StringIO.new; io.puts "hi"; io.print 1, 2; io.string)
  show "string IO read", StringIO.new("a\nb\n").each_line.map(&:chomp)
  show "capture stdout", (
    old = $stdout
    $stdout = StringIO.new
    puts "captured"
    out = $stdout.string
    $stdout = old
    out
  )
  dir = Dir.mktmpdir("study")
  File.write(File.join(dir, "a.rb"), "puts 1")
  File.write(File.join(dir, "b.txt"), "text")
  Dir.mkdir(File.join(dir, "sub"))
  File.write(File.join(dir, "sub", "c.rb"), "puts 3")
  show "Dir.children", Dir.children(dir).sort
  show "Dir.glob", Dir.glob("**/*.rb", base: dir).sort
  show "Dir.entries size", Dir.entries(dir).size
  show "Dir.exist?", Dir.exist?(dir)
  FileUtils.cp(File.join(dir, "a.rb"), File.join(dir, "copy.rb"))
  FileUtils.mv(File.join(dir, "copy.rb"), File.join(dir, "moved.rb"))
  show "after cp/mv", Dir.children(dir).sort
  FileUtils.rm_rf(dir)
  show "removed", Dir.exist?(dir)
  record = { id: 1, name: "Ada", tags: %w[math code], address: { city: "London" }, active: true, score: nil }
  json = JSON.generate(record)
  show "json", json
  show "round trip", JSON.parse(json, symbolize_names: true) == record
  show "pretty", JSON.pretty_generate(record).lines.first(3)
  show "to_json", [1, "two", nil, true].to_json
  show "parse array", JSON.parse("[1, 2, {\"a\": 3}]")
  show "parse error", (begin JSON.parse("{bad"); rescue JSON::ParserError => e; e.class; end)
  File.write(path, JSON.pretty_generate([record, record.merge(id: 2)]))
  loaded = JSON.parse(File.read(path), symbolize_names: true)
  show "file json ids", loaded.map { |r| r[:id] }
  csv_text = "name,age\nAda,36\nBob,17\nCy,45\n"
  rows = csv_text.lines.map(&:chomp).map { |l| l.split(",") }
  header, *body = rows
  records = body.map { |r| header.zip(r).to_h }
  show "mini csv", records
  show "csv average", records.sum { |r| r["age"].to_i }.fdiv(records.size).round(1)
  show "csv oldest", records.max_by { |r| r["age"].to_i }["name"]
  File.delete(path)
  show "deleted", File.exist?(path)
  show "__FILE__ basename", File.basename(__FILE__)
  show "ARGV class", ARGV.class
  show "ENV has PATH", ENV.key?("PATH")
  show "ENV fetch default", ENV.fetch("NOT_DEFINED_VAR_XYZ", "fallback")
  show "$0 class", $0.class
  show "Dir.pwd class", Dir.pwd.class
  show "gets-free stdin tty", $stdin.respond_to?(:gets)
  show "Marshal deep copy", (orig = { a: [1, 2] }; copy = Marshal.load(Marshal.dump(orig)); copy[:a] << 3; orig)
  show "YAML-free to_s", { a: 1 }.to_s
end

Study.lesson "Regular expressions" do
  text = "Contact: ada@example.com, bob.smith@mail.org; phone 555-123-4567 or (555) 987-6543."
  show "match?", text.match?(/\d{3}-\d{4}/)
  show "=~ position", (text =~ /phone/)
  show "emails", text.scan(/[\w.]+@[\w.]+\.\w+/)
  show "phones", text.scan(/\(?\d{3}\)?[ -]\d{3}-\d{4}/)
  m = text.match(/(?<user>[\w.]+)@(?<domain>[\w.]+)/)
  show "named captures", [m[:user], m[:domain]]
  show "pre/post match", [m.pre_match, m.post_match[0, 8]]
  show "captures", m.captures
  show "named_captures", m.named_captures
  show "begin/end", [m.begin(0), m.end(0)]
  if /(?<year>\d{4})-(?<month>\d\d)-(?<day>\d\d)/ =~ "Date: 2026-10-02"
    show "named local vars", [year, month, day]
  end
  show "gsub backrefs", "John Smith".gsub(/(\w+) (\w+)/, '\2, \1')
  show "gsub named", "2026-10-02".gsub(/(?<y>\d+)-(?<m>\d+)-(?<d>\d+)/, '\k<d>/\k<m>/\k<y>')
  show "gsub block with $~", "a1b2".gsub(/\d/) { ($~[0].to_i * 2).to_s }
  show "sub first only", "aaa".sub(/a/, "b")
  show "split regex", "one, two;three  four".split(/[,;\s]+/)
  show "split keep delimiters", "a1b2c".split(/(\d)/)
  show "anchors", ["start", "restart"].map { |w| w.match?(/\Astart/) }
  show "line anchors", "a\nb".scan(/^\w$/)
  show "case insensitive", "RUBY".match?(/ruby/i)
  show "multiline dot", "a\nb".match?(/a.b/m)
  show "extended", "2026-10".match?(/
    \d{4}
    -
    \d{2}
  /x)
  show "greedy", "<b>x</b><b>y</b>"[/<b>.*<\/b>/]
  show "lazy", "<b>x</b><b>y</b>"[/<b>.*?<\/b>/]
  show "lookahead", "price: $100 and $200".scan(/\$(\d+)(?= and)/)
  show "lookbehind", "price: $100".scan(/(?<=\$)\d+/)
  show "alternation", "cat dog bird".scan(/cat|bird/)
  show "char classes", "a1 b2_c3".scan(/[[:alpha:]]\d/)
  show "unicode property", "héllo wörld".scan(/\p{L}+/)
  show "quantifiers", ["a", "aa", "aaaa"].map { |s| s.match?(/\Aa{2,3}\z/) }
  show "escape", Regexp.escape("1+1=2?")
  show "union", "cat or dog".scan(Regexp.union("cat", "dog"))
  show "interpolated", (word = "or"; "cat or dog".scan(/#{word}/))
  show "tr ranges", "hello".tr("a-y", "b-z")
  show "squeeze regexp-free", "a  b   c".split.join(" ")
  show "validate hex color", %w[#fff #A1B2C3 #ggg #12345].map { |c| c.match?(/\A#(\h{3}|\h{6})\z/) }
  show "validate ipv4", %w[192.168.1.1 256.1.1.1 1.2.3].map { |ip| ip.match?(/\A(\d{1,3}\.){3}\d{1,3}\z/) && ip.split(".").all? { |o| o.to_i <= 255 } }
  show "extract hashtags", "love #ruby and #coding!".scan(/#(\w+)/).flatten
  show "word frequency", "the cat the hat".scan(/\w+/).tally
  show "strip tags", "<p>Hello <b>World</b></p>".gsub(/<[^>]+>/, "")
  show "camel split", "parseHTTPResponseCode".scan(/[A-Z]+(?=[A-Z][a-z])|[A-Z]?[a-z]+|[A-Z]+|\d+/)
  show "password rules", %w[abc Passw0rd! short1A].map { |pw| pw.length >= 8 && pw.match?(/[a-z]/) && pw.match?(/[A-Z]/) && pw.match?(/\d/) }
  show "last match global", ("xyz" =~ /y/; [$~[0], $`, $'])
  show "match with position", "foo bar".match(/\w+/, 3)[0]
  show "scan with block", "a1b2".scan(/[a-z]\d/).map(&:upcase)
  show "start_with regexp", "Hello".start_with?(/h/i)
  show "slice!", "hello world".dup.tap { |s| s.slice!(/\s\w+/) }
end

Study.lesson "Pattern matching" do
  def describe(value)
    case value
    in Integer => n if n.negative? then "negative int #{n}"
    in Integer | Float => n then "number #{n}"
    in "" then "empty string"
    in String => s then "string of #{s.size}"
    in [] then "empty array"
    in [x] then "one element #{x}"
    in [Integer => a, Integer => b] then "two ints #{a + b}"
    in [first, *rest] then "array starting #{first} with #{rest.size} more"
    in { type: :circle, radius: } then "circle area #{(3.14159 * radius**2).round(1)}"
    in { type: :rect, w:, h: } then "rect area #{w * h}"
    in { name: String => name, **rest } then "named #{name} plus #{rest.keys}"
    in nil then "nil"
    else "something else"
    end
  end
  [-5, 7, 2.5, "", "abc", [], [9], [1, 2], [:a, :b, :c], { type: :circle, radius: 2 },
   { type: :rect, w: 2, h: 3 }, { name: "Ada", age: 36 }, nil, :sym].each do |v|
    show v.inspect[0, 28], describe(v)
  end
  config = { server: { host: "localhost", ports: [80, 443] }, debug: true }
  case config
  in { server: { host:, ports: [first_port, *] }, debug: }
    show "nested", [host, first_port, debug]
  end
  result = { status: "ok", data: { items: [1, 2, 3] } }
  if result in { status: "ok", data: { items: [_, *] } }
    show "in predicate", true
  end
  result => { data: { items: } }
  show "rightward assign", items
  value = 5
  case 5
  in ^value then show "pin", :matched
  end
  case 7
  in ^(value + 2) then show "pin expression", :matched
  end
  case [1, [2, 3]]
  in [a, [b, c]]
    show "deep array", a + b + c
  end
  case { a: 1 }
  in { a: 1 | 2 => got } then show "alternatives bind", got
  end
  case [1, 2, 3, 4, 5]
  in [*, 3, *post] then show "find pattern", post
  end
  case { k: nil }
  in { k: nil } then show "nil value", :ok
  end
  case 15
  in 0..9 then show "range", :small
  in (10..) then show "endless range", :large
  end
  begin
    case 99
    in String then 1
    end
  rescue NoMatchingPatternError => e
    show "no match error", e.class
  end
  class Vec
    attr_reader :x, :y
    def initialize(x, y) = (@x, @y = x, y)
    def deconstruct = [x, y]
    def deconstruct_keys(_) = { x: x, y: y }
  end
  case Vec.new(3, 4)
  in { x:, y: } then show "custom keys", Math.hypot(x, y)
  end
  case Vec.new(3, 4)
  in [a, b] then show "custom array", a * b
  end
  show "in with guard unless", (case 4; in Integer => n unless n.odd? then :even; end)
  events = [{ type: :click, x: 1, y: 2 }, { type: :key, key: "a" }, { type: :scroll, dy: -3 }]
  show "event dispatch", events.map { |e|
    case e
    in { type: :click, x:, y: } then "click at #{x},#{y}"
    in { type: :key, key: } then "key #{key}"
    in { type: } then "other #{type}"
    end
  }
  show "json-like walk", (
    walk = ->(node) do
      case node
      in Hash then node.sum { |_, v| walk.(v) }
      in Array then node.sum { |v| walk.(v) }
      in Integer | Float then node
      else 0
      end
    end
    walk.({ a: [1, 2, { b: 3 }], c: "x", d: 4.5 })
  )
end

Study.lesson "Metaprogramming" do
  class Dynamic
    %w[alpha beta gamma].each_with_index do |name, i|
      define_method("#{name}?") { i.even? }
      define_method("#{name}_value") { |mult = 1| i * mult }
    end
    def method_missing(name, *args, &blk)
      if name.to_s.start_with?("get_")
        "dynamic #{name.to_s.delete_prefix("get_")}"
      else
        super
      end
    end
    def respond_to_missing?(name, include_private = false) = name.to_s.start_with?("get_") || super
  end
  d = Dynamic.new
  show "define_method", [d.alpha?, d.beta?, d.gamma_value(10)]
  show "method_missing", d.get_color
  show "respond_to_missing", [d.respond_to?(:get_x), d.respond_to?(:other)]
  show "method object from missing", d.method(:get_thing).call
  show "missing falls through", (begin d.unknown; rescue NoMethodError => e; e.class; end)
  show "send", "hello".send(:upcase)
  show "public_send blocks private", (begin Object.new.public_send(:puts, "x"); rescue NoMethodError => e; e.class; end)
  obj = Object.new
  obj.instance_variable_set(:@secret, 42)
  show "instance_variable_set/get", obj.instance_variable_get(:@secret)
  obj.define_singleton_method(:hello) { "singleton hi" }
  show "define_singleton_method", obj.hello
  klass = Class.new do
    attr_accessor :v
    def initialize(v) = @v = v
  end
  Object.const_set(:Generated, klass)
  show "const_set", Generated.new(5).v
  show "const_get", Object.const_get(:Generated).name
  show "instance_methods(false)", Generated.instance_methods(false).sort
  show "class_eval", (Generated.class_eval { def double = v * 2 }; Generated.new(4).double)
  show "instance_eval", Generated.new(9).instance_eval { @v + 1 }
  show "send setter", (g = Generated.new(1); g.send(:v=, 77); g.v)
  module Trackable
    def self.included(base)
      base.extend(ClassMethods)
      base.instance_variable_set(:@tracked, [])
    end
    module ClassMethods
      def track(*names)
        names.each do |n|
          @tracked << n
          attr_reader n
          define_method("#{n}=") do |val|
            (@history ||= []) << [n, val]
            instance_variable_set("@#{n}", val)
          end
        end
      end
      def tracked = @tracked
    end
    def history = @history || []
  end
  class Product
    include Trackable
    track :price, :stock
  end
  pr = Product.new
  pr.price = 10
  pr.price = 12
  pr.stock = 5
  show "tracked attrs", Product.tracked
  show "history", pr.history
  show "current price", pr.price
  module Validations
    def validates(attr, &rule)
      (@rules ||= {})[attr] = rule
    end
    def rules = @rules || {}
  end
  class Form
    extend Validations
    validates(:age) { |v| v.is_a?(Integer) && v >= 18 }
    validates(:name) { |v| !v.to_s.strip.empty? }
    def initialize(**attrs) = @attrs = attrs
    def valid? = self.class.rules.all? { |a, rule| rule.call(@attrs[a]) }
    def errors = self.class.rules.reject { |a, rule| rule.call(@attrs[a]) }.keys
  end
  show "dsl valid", Form.new(age: 20, name: "Ada").valid?
  show "dsl errors", Form.new(age: 10, name: " ").errors
  class HTMLBuilder
    def initialize = (@out = []; @depth = 0)
    def method_missing(tag, content = nil, **attrs, &blk)
      attr_text = attrs.map { |k, v| %( #{k}="#{v}") }.join
      if blk
        @out << "#{"  " * @depth}<#{tag}#{attr_text}>"
        @depth += 1
        instance_eval(&blk)
        @depth -= 1
        @out << "#{"  " * @depth}</#{tag}>"
      else
        @out << "#{"  " * @depth}<#{tag}#{attr_text}>#{content}</#{tag}>"
      end
      self
    end
    def respond_to_missing?(*) = true
    def result = @out.join("\n")
  end
  html = HTMLBuilder.new
  html.ul(class: "list") do
    li "first"
    li "second", id: "two"
  end
  puts html.result
  show "ObjectSpace-free count", Dynamic.instance_methods(false).size
  show "methods grep", Dynamic.instance_methods(false).grep(/value/).sort
  show "Module#===", Comparable === 3
  show "singleton_class", "str".singleton_class.inspect.start_with?("#<Class:")
  show "instance_variable_defined?", obj.instance_variable_defined?(:@secret)
  show "remove_method", (Dynamic.send(:remove_method, :alpha?); Dynamic.method_defined?(:alpha?))
  show "alias_method", (Dynamic.send(:alias_method, :b?, :beta?); Dynamic.new.b?)
  show "Method#unbind", 5.method(:+).unbind.class
  show "__method__", (def whoami = __method__; whoami)
  show "caller is array", caller.is_a?(Array)
  show "binding eval", (x = 6; binding.local_variable_get(:x) * 7)
  show "eval string", eval("1 + 2 * 3")
  show "ObjectSpace.each_object class", ObjectSpace.each_object(Class).first.class
  show "hooks inherited", (
    registry = []
    base = Class.new do
      define_singleton_method(:inherited) { |sub| registry << sub }
    end
    Class.new(base)
    Class.new(base)
    registry.size
  )
end
module Shout
  refine String do
    def shout = upcase + "!"
  end
end

using Shout

Study.lesson "Refinements and freezing" do
  show "refinement", "hey".shout
  show "refinement scoped to file", "x".respond_to?(:shout)
  CONFIG = { env: "dev", ports: [1, 2] }.freeze
  show "shallow freeze", [CONFIG.frozen?, CONFIG[:ports].frozen?]
  CONFIG[:ports] << 3
  show "inner still mutable", CONFIG[:ports]
  deep = ->(o) do
    case o
    when Hash then o.each_value { |v| deep.(v) }
    when Array then o.each { |v| deep.(v) }
    end
    o.freeze
  end
  safe = deep.({ a: [1, { b: "x" }] })
  show "deep frozen", [safe.frozen?, safe[:a].frozen?, safe[:a][1][:b].frozen?]
  show "dup unfreezes", safe.dup.frozen?
  show "clone keeps freeze", safe.clone.frozen?
  show "clone freeze false", safe.clone(freeze: false).frozen?
end

Study.lesson "Time and dates" do
  t = Time.utc(2026, 10, 2, 14, 30, 45)
  show "components", [t.year, t.month, t.day, t.hour, t.min, t.sec]
  show "weekday", [t.wday, t.yday, t.friday?]
  show "strftime", t.strftime("%Y-%m-%d %H:%M:%S")
  show "strftime friendly", t.strftime("%A, %B %-d, %Y at %-I:%M %p")
  show "iso8601", t.iso8601
  show "to_i", t.to_i
  show "plus seconds", (t + 3600).hour
  show "minus time", ((t + 90) - t)
  show "days later", (t + 86_400 * 30).strftime("%b %d")
  show "parse", Time.parse("2026-12-25 08:00:00 UTC").month
  show "iso parse", Time.iso8601("2026-01-02T03:04:05Z").day
  show "at epoch", Time.at(0).utc.year
  show "comparison", t < Time.utc(2027, 1, 1)
  show "sort times", [Time.utc(2026, 5), Time.utc(2025, 5)].min.year
  show "elapsed formatting", [3661, 59, 86_400].map { |s| format("%02d:%02d:%02d", s / 3600, s % 3600 / 60, s % 60) }
  show "leap year", [1900, 2000, 2024, 2026].map { |y| (y % 4 == 0 && y % 100 != 0) || y % 400 == 0 }
  show "days in month", (1..12).map { |m| Date.new(2026, m, -1).day }
  show "monotonic", Process.clock_gettime(Process::CLOCK_MONOTONIC).class
  show "age from birthdate", (
    born = Time.utc(1990, 6, 15)
    ref = Time.utc(2026, 10, 2)
    ref.year - born.year - ((ref.month > born.month || (ref.month == born.month && ref.day >= born.day)) ? 0 : 1)
  )
  show "business days in week", (1..7).count { |d| !(Time.utc(2026, 10, d).saturday? || Time.utc(2026, 10, d).sunday?) }
  show "beginning of month", Time.utc(t.year, t.month, 1).strftime("%a")
end

Study.lesson "Threads, mutexes, and queues" do
  results = []
  lock = Mutex.new
  threads = 4.times.map do |i|
    Thread.new(i) do |n|
      lock.synchronize { results << n * n }
    end
  end
  threads.each(&:join)
  show "thread results", results.sort
  show "thread value", Thread.new { 6 * 7 }.value
  counter = 0
  workers = 5.times.map { Thread.new { 200.times { lock.synchronize { counter += 1 } } } }
  workers.each(&:join)
  show "safe counter", counter
  queue = Queue.new
  producer = Thread.new { 5.times { |i| queue << i }; queue << :done }
  consumed = []
  consumer = Thread.new do
    loop do
      item = queue.pop
      break if item == :done
      consumed << item * 10
    end
  end
  [producer, consumer].each(&:join)
  show "queue consumed", consumed
  show "thread local", Thread.new { Thread.current[:x] = 1; Thread.current[:x] }.value
  show "alive?", Thread.new { sleep 0.01 }.tap(&:join).alive?
  show "parallel map", [1, 2, 3].map { |n| Thread.new { n + 100 } }.map(&:value)
  fiber = Fiber.new do
    Fiber.yield 1
    Fiber.yield 2
    3
  end
  show "fiber", [fiber.resume, fiber.resume, fiber.resume]
  gen = Enumerator.new { |y| 3.times { |i| y.yield i, i * i } }
  show "enumerator pairs", gen.to_a
  show "SecureRandom hex length", SecureRandom.hex(4).length
  show "SecureRandom uuid shape", SecureRandom.uuid.match?(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
end

Study.lesson "Project: bank accounts" do
  class InsufficientFunds < StandardError
    attr_reader :needed
    def initialize(needed)
      @needed = needed
      super("need #{format("%.2f", needed)} more")
    end
  end

  class Account
    attr_reader :owner, :balance, :history

    def initialize(owner, balance = 0)
      @owner = owner
      @balance = balance
      @history = []
    end

    def deposit(amount)
      raise ArgumentError, "amount must be positive" unless amount.positive?
      @balance += amount
      @history << [:deposit, amount]
      self
    end

    def withdraw(amount)
      raise InsufficientFunds.new(amount - @balance) if amount > @balance
      @balance -= amount
      @history << [:withdraw, amount]
      self
    end

    def transfer(to, amount)
      withdraw(amount)
      to.deposit(amount)
      @history << [:transfer, amount, to.owner]
      self
    end

    def to_s = format("%s: $%.2f", owner, balance)
  end

  class Savings < Account
    RATE = 0.02
    def add_interest = deposit((balance * RATE).round(2))
  end

  a = Account.new("Ada", 100)
  b = Savings.new("Bob", 500)
  a.deposit(50).withdraw(30)
  a.transfer(b, 70)
  b.add_interest
  puts a, b
  show "history", a.history
  begin
    a.withdraw(1000)
  rescue InsufficientFunds => e
    show "insufficient", [e.message, e.needed]
  end
  begin
    a.deposit(-5)
  rescue ArgumentError => e
    show "invalid deposit", e.message
  end
  show "total money", [a, b].sum(&:balance).round(2)
  show "richest", [a, b].max_by(&:balance).owner
end

Study.lesson "Project: todo list with JSON persistence" do
  class Todo
    Item = Struct.new(:id, :title, :done, :priority, keyword_init: true) do
      def to_s = format("[%s] %-3d %-18s p%d", done ? "x" : " ", id, title, priority)
    end

    def initialize = (@items = []; @next_id = 1)

    def add(title, priority: 2)
      item = Item.new(id: @next_id, title: title, done: false, priority: priority)
      @next_id += 1
      @items << item
      item
    end

    def complete(id)
      item = find(id) or raise KeyError, "no todo #{id}"
      item.done = true
      item
    end

    def find(id) = @items.find { |i| i.id == id }
    def pending = @items.reject(&:done)
    def by_priority = @items.sort_by { |i| [i.priority, i.id] }
    def remove(id) = @items.reject! { |i| i.id == id }
    def to_json(*) = JSON.generate(@items.map(&:to_h))

    def self.from_json(text)
      todo = new
      JSON.parse(text, symbolize_names: true).each do |h|
        todo.add(h[:title], priority: h[:priority]).tap { |i| i.done = h[:done] }
      end
      todo
    end

    def report = by_priority.map(&:to_s)
  end

  todo = Todo.new
  todo.add("write ruby notes", priority: 1)
  todo.add("practice blocks", priority: 2)
  todo.add("read a gem's source", priority: 3)
  todo.complete(1)
  puts todo.report
  show "pending", todo.pending.map(&:title)
  saved = todo.to_json
  restored = Todo.from_json(saved)
  show "round trip", restored.report == todo.report
  show "remove", (todo.remove(2) ? :removed : :missing)
  show "missing id", (begin todo.complete(99); rescue KeyError => e; e.message; end)
end

Study.lesson "Project: text analyzer" do
  text = <<~TXT
    Ruby is a dynamic, open source programming language with a focus on
    simplicity and productivity. It has an elegant syntax that is natural
    to read and easy to write. Ruby is designed to make programmers happy.
  TXT
  words = text.downcase.scan(/[a-z']+/)
  stop = %w[a an and is it on to the with that of]
  show "word count", words.size
  show "unique words", words.uniq.size
  show "sentence count", text.split(/(?<=[.!?])\s+/).size
  show "avg word length", (words.sum(&:length).fdiv(words.size)).round(2)
  show "longest words", words.uniq.max_by(3, &:length)
  freq = words.reject { |w| stop.include?(w) }.tally.sort_by { |w, c| [-c, w] }
  show "top words", freq.first(3)
  show "letters histogram", text.downcase.delete("^a-z").chars.tally.sort_by { |_, c| -c }.first(5).to_h
  show "vowel ratio", (text.downcase.count("aeiou").fdiv(text.downcase.count("a-z"))).round(3)
  show "lines", text.lines.size
  show "longest line", text.lines.max_by(&:length).strip[0, 20]
  show "capitalized words", text.scan(/\b[A-Z][a-z]+\b/).uniq
  show "reading time seconds", (words.size / 4.0).ceil
  histogram = freq.first(4).map { |w, c| "#{w.ljust(12)}#{"#" * c}" }
  puts histogram
  show "bigrams", words.each_cons(2).first(3).map { |p| p.join(" ") }
  show "palindromes", %w[level ruby noon civic].select { |w| w == w.reverse }
  show "caesar", "Hello, Ruby".gsub(/[a-z]/i) { |c| base = c =~ /[a-z]/ ? 97 : 65; ((c.ord - base + 3) % 26 + base).chr }
  show "vowel-less", "programming".delete("aeiou")
  show "acronym", "portable network graphics".split.map { |w| w[0].upcase }.join
end

Study.lesson "Project: LRU cache and stack calculator" do
  class LRUCache
    def initialize(capacity)
      @capacity = capacity
      @store = {}
    end

    def get(key)
      return nil unless @store.key?(key)
      value = @store.delete(key)
      @store[key] = value
    end

    def put(key, value)
      @store.delete(key)
      @store[key] = value
      @store.shift if @store.size > @capacity
      value
    end

    def keys = @store.keys
  end

  cache = LRUCache.new(2)
  cache.put(:a, 1)
  cache.put(:b, 2)
  cache.get(:a)
  cache.put(:c, 3)
  show "lru keys", cache.keys
  show "evicted", cache.get(:b)

  class Calculator
    PRECEDENCE = { "+" => 1, "-" => 1, "*" => 2, "/" => 2, "^" => 3 }.freeze

    def tokenize(expr) = expr.scan(/\d+\.?\d*|[-+*\/^()]/)

    def to_postfix(tokens)
      output = []
      ops = []
      tokens.each do |t|
        if t.match?(/\A\d/)
          output << t
        elsif t == "("
          ops << t
        elsif t == ")"
          output << ops.pop while ops.last != "("
          ops.pop
        else
          while ops.any? && ops.last != "(" && higher?(ops.last, t)
            output << ops.pop
          end
          ops << t
        end
      end
      output.concat(ops.reverse)
    end

    def higher?(top, current)
      PRECEDENCE[top] > PRECEDENCE[current] || (PRECEDENCE[top] == PRECEDENCE[current] && current != "^")
    end

    def evaluate(expr)
      stack = []
      to_postfix(tokenize(expr)).each do |t|
        if t.match?(/\A\d/)
          stack << t.to_f
        else
          b = stack.pop
          a = stack.pop
          stack << (t == "^" ? a**b : a.public_send(t, b))
        end
      end
      stack.first
    end
  end

  calc = Calculator.new
  ["1 + 2 * 3", "(1 + 2) * 3", "2 ^ 3 ^ 2", "10 / 4 - 1", "2 * (3 + 4) * 5"].each do |expr|
    show expr, calc.evaluate(expr)
  end
  show "postfix", calc.to_postfix(calc.tokenize("3 + 4 * 2"))
end

Study.lesson "Project: Conway's Game of Life" do
  class Life
    def initialize(rows)
      @grid = rows.map { |r| r.chars.map { |c| c == "#" } }
      @h = @grid.size
      @w = @grid.first.size
    end

    def neighbors(r, c)
      [-1, 0, 1].product([-1, 0, 1]).reject { |d| d == [0, 0] }.count do |dr, dc|
        rr = r + dr
        cc = c + dc
        rr.between?(0, @h - 1) && cc.between?(0, @w - 1) && @grid[rr][cc]
      end
    end

    def step
      @grid = Array.new(@h) do |r|
        Array.new(@w) do |c|
          n = neighbors(r, c)
          @grid[r][c] ? [2, 3].include?(n) : n == 3
        end
      end
      self
    end

    def to_s = @grid.map { |row| row.map { |v| v ? "#" : "." }.join }.join("\n")
    def alive = @grid.flatten.count(true)
  end

  life = Life.new([".....", "..#..", "..#..", "..#..", "....."])
  puts life
  puts
  puts life.step
  show "alive", life.alive
  show "oscillates", life.step.to_s == Life.new([".....", "..#..", "..#..", "..#..", "....."]).to_s
end

Study.lesson "Project: state machine and observer" do
  class Order
    TRANSITIONS = {
      pending: %i[paid cancelled],
      paid: %i[shipped refunded],
      shipped: %i[delivered],
      delivered: [],
      cancelled: [],
      refunded: []
    }.freeze

    attr_reader :state, :log

    def initialize
      @state = :pending
      @log = []
      @listeners = []
    end

    def on_change(&block) = @listeners << block

    def can?(target) = TRANSITIONS.fetch(@state).include?(target)

    def move_to(target)
      raise ArgumentError, "cannot go from #{@state} to #{target}" unless can?(target)
      old = @state
      @state = target
      @log << [old, target]
      @listeners.each { |l| l.call(old, target) }
      self
    end
  end

  order = Order.new
  events = []
  order.on_change { |from, to| events << "#{from}->#{to}" }
  order.move_to(:paid).move_to(:shipped).move_to(:delivered)
  show "events", events
  show "final", order.state
  show "invalid", (begin order.move_to(:pending); rescue ArgumentError => e; e.message; end)
  show "terminal states", Order::TRANSITIONS.select { |_, v| v.empty? }.keys

  class EventBus
    def initialize = @handlers = Hash.new { |h, k| h[k] = [] }
    def subscribe(event, &handler) = @handlers[event] << handler
    def publish(event, *payload) = @handlers[event].map { |h| h.call(*payload) }
  end

  bus = EventBus.new
  bus.subscribe(:greet) { |name| "hello #{name}" }
  bus.subscribe(:greet) { |name| "welcome #{name}" }
  show "bus", bus.publish(:greet, "Ada")
  show "no handlers", bus.publish(:nothing)
end

Study.lesson "Project: inventory report" do
  Item = Struct.new(:sku, :name, :category, :price, :qty)
  stock = [
    Item.new("A1", "Keyboard", :hardware, 49.99, 12),
    Item.new("A2", "Mouse", :hardware, 19.5, 40),
    Item.new("B1", "Ruby Book", :books, 35.0, 8),
    Item.new("B2", "Notebook", :books, 4.25, 100),
    Item.new("C1", "Sticker", :misc, 0.99, 0)
  ]
  show "total units", stock.sum(&:qty)
  show "inventory value", stock.sum { |i| i.price * i.qty }.round(2)
  by_cat = stock.group_by(&:category)
  by_cat.each do |cat, items|
    value = items.sum { |i| i.price * i.qty }
    puts format("%-10s items=%d value=%9.2f", cat, items.size, value)
  end
  show "out of stock", stock.select { |i| i.qty.zero? }.map(&:name)
  show "low stock", stock.select { |i| i.qty.between?(1, 10) }.map(&:name)
  show "cheapest", stock.min_by(&:price).name
  show "most valuable line", stock.max_by { |i| i.price * i.qty }.name
  show "category totals", by_cat.transform_values { |v| v.sum(&:qty) }
  show "price tiers", stock.group_by { |i| i.price < 5 ? :cheap : i.price < 30 ? :mid : :premium }.transform_values { |v| v.map(&:sku) }
  show "restock plan", stock.select { |i| i.qty < 10 }.to_h { |i| [i.sku, 20 - i.qty] }
  show "table", stock.map { |i| format("%-4s%-12s%8.2f%5d", i.sku, i.name, i.price, i.qty) }.first(2)
  show "apply discount", stock.map { |i| [i.sku, (i.price * 0.9).round(2)] }.first(2)
end

module TinyCheck
  @results = Hash.new(0)
  @failures = []

  def self.check(label, expected, actual)
    if expected == actual
      @results[:pass] += 1
    else
      @results[:fail] += 1
      @failures << "#{label}: expected #{expected.inspect}, got #{actual.inspect}"
    end
  end

  def self.raises?(klass)
    yield
    false
  rescue klass
    true
  end

  def self.report
    puts "passed=#{@results[:pass]} failed=#{@results[:fail]}"
    @failures.each { |f| puts "  FAIL #{f}" }
    @results[:fail].zero?
  end
end

Study.lesson "Self-test: check what you have learned" do
  check = TinyCheck.method(:check)
  check.call("arith", 7, 1 + 2 * 3)
  check.call("int division", 3, 7 / 2)
  check.call("string mult", "ababab", "ab" * 3)
  check.call("array map", [2, 4, 6], [1, 2, 3].map { |x| x * 2 })
  check.call("hash default", 0, Hash.new(0)[:missing])
  check.call("range sum", 55, (1..10).sum)
  check.call("symbol to_proc", %w[A B], %w[a b].map(&:upcase))
  check.call("safe nav", nil, nil&.length)
  check.call("string slice", "ell", "hello"[1..3])
  check.call("tally", { "a" => 2, "b" => 1 }, %w[a b a].tally)
  check.call("inject", 24, (1..4).inject(:*))
  check.call("flat_map", [1, 1, 2, 2], [1, 2].flat_map { |x| [x, x] })
  check.call("lambda arity", 2, ->(a, b) {}.arity)
  check.call("sort_by", %w[b aa ccc], %w[ccc b aa].sort_by(&:length))
  check.call("zip to_h", { a: 1 }, %i[a].zip([1]).to_h)
  check.call("divmod", [3, 2], 11.divmod(3))
  check.call("freeze", true, "x".freeze.frozen?)
  check.call("gsub", "h*ll*", "hello".gsub(/[aeiou]/, "*"))
  check.call("case in", :pair, (case [1, 2]; in [_, _] then :pair; end))
  check.call("raises", true, TinyCheck.raises?(ZeroDivisionError) { 1 / 0 })
  check.call("fetch error", true, TinyCheck.raises?(KeyError) { {}.fetch(:x) })
  check.call("struct", 3, Struct.new(:a, :b).new(1, 2).to_a.sum)
  check.call("comparable", true, 5.clamp(1, 3) == 3)
  check.call("each_slice", [[1, 2], [3]], [1, 2, 3].each_slice(2).to_a)
  check.call("partition", [[2], [1, 3]], [1, 2, 3].partition(&:even?))
  check.call("string format", "007", format("%03d", 7))
  check.call("deliberate failure demo", 1, 2)
  TinyCheck.report
end

Study.lesson "Practice exercises (edit these and run them)" do
  exercises = {
    "Sum of even numbers 1..100" => -> { (1..100).select(&:even?).sum },
    "Reverse words in a sentence" => -> { "learn ruby well".split.reverse.join(" ") },
    "Count vowels in 'enumerable'" => -> { "enumerable".count("aeiou") },
    "First 10 squares" => -> { (1..10).map { |n| n * n } },
    "Is 'racecar' a palindrome?" => -> { "racecar" == "racecar".reverse },
    "Factorial of 8" => -> { (1..8).reduce(:*) },
    "Largest of [4, 19, 7]" => -> { [4, 19, 7].max },
    "Group words by length" => -> { %w[a bb cc d eee].group_by(&:size) },
    "Flatten and sort" => -> { [[3, 1], [2, [5, 4]]].flatten.sort },
    "Words starting with 'r'" => -> { %w[ruby rails python rake].select { |w| w.start_with?("r") } },
    "Fibonacci(15)" => -> { (1..15).reduce([0, 1]) { |(a, b), _| [b, a + b] }.first },
    "Transpose a matrix" => -> { [[1, 2, 3], [4, 5, 6]].transpose },
    "Remove duplicates keep order" => -> { [3, 1, 3, 2, 1].uniq },
    "Hash from two arrays" => -> { %w[x y z].zip([1, 2, 3]).to_h },
    "Capitalize each word" => -> { "hello brave new world".split.map(&:capitalize).join(" ") }
  }
  exercises.each_with_index do |(title, solution), i|
    puts format("%2d. %-34s => %s", i + 1, title, solution.call.inspect)
  end
  puts
  puts "Ideas for next steps:"
  puts "  - rewrite each exercise using a different method chain"
  puts "  - add your own lesson with Study.lesson \"name\" do ... end"
  puts "  - build a command line tool with ARGV and OptionParser"
  puts "  - read about Comparable, Enumerable, and Module#prepend in the docs"
  puts "  - try writing tests with minitest or rspec"
end

def run_study(argv)
  case argv.first
  when nil, "menu", "list", "-l"
    puts "Ruby study guide: ruby #{File.basename($PROGRAM_NAME)} [all | number | keyword]"
    puts
    Study.menu
  when "all"
    Study.run_all
  when /\A\d+\z/
    index = argv.first.to_i - 1
    if index.between?(0, Study::LESSONS.size - 1)
      Study.run_one(index)
    else
      puts "lesson must be between 1 and #{Study::LESSONS.size}"
    end
  else
    keyword = argv.join(" ").downcase
    matches = Study::LESSONS.each_index.select { |i| Study::LESSONS[i][:name].downcase.include?(keyword) }
    if matches.empty?
      puts "no lesson matches #{keyword.inspect}"
      Study.menu
    else
      matches.each { |i| Study.run_one(i) }
    end
  end
end

run_study(ARGV) if $PROGRAM_NAME == __FILE__
