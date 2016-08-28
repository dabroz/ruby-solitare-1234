require 'io/console'

class C
def initialize(num)
@num = num
@x2 = false
end
def color
(@num / 13).to_i
end
def value
@num % 13 + 2
end
def red
color < 2
end
def to_s
"#{'♥♦♣♠'[color]}#{value != 10 ? ' ' : '1'}#{'01234567890JQKA'[value]}"
end
def x2?
@x2
end
def reveal
@x2 = true
end
def selected?
@oed
end
def select
@oed = true
end
def unselect
@oed = false
end
def accept(child)
return false unless red ^ child.red
child.value == value - 1
end
end

def gtcp x, y, t = ''
print "\033[#{y};#{x}H#{t}"
end
def q2(x,y,type,key)
ss = '---'
n = "|       |"
if type.is_a? C and type.x2?
ss = type
n = "|xxxxxxx|" if type.selected?
end
gtcp x, y + 0, "+#{ss}----+"
(1..5).each do |q|
gtcp x, y + q, n
end
gtcp x, y + 6, "|_[ #{key} ]_|"
end
def unselect
@r = nil
@u.each(&:unselect)
end
def q1
@u.detect(&:selected?)
end
def f1(target)
b8 = @r
return if b8 == target
if b8
seq = b8[b8.index(q1)..-1]
else
seq = [q1]
end
b7 = target.last
if b7 == nil
return unless q1.value == 13
else
return if !b7.accept(seq.first)
end
seq.each do |card|
target << card
if b8
b8.delete(card)
else
@o.delete(card)
end
end
end
def q4(target)
ts = @target[target]
exp = 14
if ts.count > 0
if ts.last.value == 14
exp = 2
else
exp = ts.last.value + 1
end
return unless q1.color == ts.last.color
end
return unless q1.value == exp
if @r
@r.delete(q1)
else
@o.delete(q1)
end
ts << q1
end
def q7
gtcp 1, 1, "\033[2J\033[1;1H"
@t.each_with_index do |stack, index|
stack.each_with_index do |card, cindex|
q2(index * 11 + 4, 10 + cindex, card, index+1)
end
end
@target.each_with_index do |target, index|
x = index * 11 + 37
q2(x, 2, target.last,%w(a b c d)[index])
end
q2(4, 2, '', 'q')
@o.each_with_index do |select, index|
q2(15 + index * 4, 2, select,'w')
end
gtcp 1, 39, " [ m ] #{@i ? 'move' : 'cancel'}#{' '*40}"
key = STDIN.getch
if @i and key >= '1' and key <= '7'
prev = @r
prevc = q1
unselect
@r = @t[key.ord - '1'.ord]
x2 = @r.select(&:x2?)
return if x2.count == 0
if prevc and prev == @r
previ = x2.index(prevc)
x2[(previ+1) % x2.count].select
else
x2.last.select
end
elsif @i and key == 'm'
@i = false if q1
elsif !@i and key == 'm'
@i = true
elsif !@i and key >= '1' and key <= '7'
f1(@t[key.ord - '1'.ord])
unselect
@i = true
elsif !@i and key >= 'a' and key <= 'd'
q4(key.ord - 'a'.ord)
unselect
@i = true
elsif @i and key == 'w'
unselect
@o.last&.select
elsif @i and key == 'q'
unselect
@o.each do |card| @y << card end
@o = []
3.times do
c = @p.shift
@o << c if c
end
if @o.size == 0 and @p.size == 0
@p = @y
@y = []
end
end
@t.each do |stack| stack.last&.reveal end
end
@i = true
@p = (0...52).map {|n| C.new(n) }
@u = @p.dup
@y = []
@p.shuffle!
@t = []
(1..7).each do |n|
@t << []
n.times do
@t[n - 1] << @p.shift
end
end
@t.each do |s| s.last.reveal end
@o = []
@p.each(&:reveal)
3.times do
@o << @p.shift
end

@target = [[],[],[],[]]
q7 while true
