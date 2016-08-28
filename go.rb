require 'io/console'

WIDTH = `tput cols`.to_i
HEIGHT = `tput lines`.to_i
GAMEID = (ARGV[0] || rand(2**16)).to_i

class Card
  def initialize(num)
    @num = num
    @revealed = false
  end
  def color
    (@num / 13).to_i
  end
  def value
    @num % 13 + 2
  end
  def red?
    color < 2
  end
  def to_s
    "♥♦♣♠"[color] + (value!=10 ? ' ' : '') + ((0..10).to_a + %w(J Q K A))[value].to_s
  end
  def revealed?
    @revealed
  end
  def reveal
    @revealed = true
  end
  def selected?
    @selected
  end
  def select
    @selected = true
  end
  def unselect
    @selected = false
  end
  def accept(child)
    return false unless red? ^ child.red?
    child.value == value - 1
  end
end

class Game
  def initialize
    @mode = 'select'
    @cards = (0...52).map {|n| Card.new(n) }
    @all = @cards.dup
    @grave = []
    @cards.shuffle!(random: Random.new(GAMEID))
    @stacks = [[],[],[],[],[],[],[]]
    (1..7).each do |n|
      n.times do
        @stacks[n - 1] << @cards.shift
      end
      @stacks[n - 1].reverse!
    end
    @stacks.each do |s| s.last.reveal end
    @select = []
    @cards.each(&:reveal)
    3.times do
      @select << @cards.shift
    end
    @target = [[],[],[],[]]
  end
  def render
    goto(1,1)
    color2(90,42)
    (WIDTH * (HEIGHT-2)).times do
      print ' '
    end
    @stacks.each_with_index do |stack, index|
      stack.each_with_index do |card, cindex|
        printcard(index * 11 + 4, 10 + cindex, card)
      end
      printkey(index * 11 + 4, 10 + 15 + 5, index+1)
    end
    @target.each_with_index do |target, index|
      x = index * 11 + 37
      printcard(x, 2, target.last)
      printkey(x, 1, %w(a b c d)[index]) if @mode == 'move'
    end
    printcard(4, 2, '') if (@cards.count+@grave.count) > 0
    @select.each_with_index do |select, index|
      printcard(15 + index * 4, 2, select)
    end
    printkey(4, 1, 'q') if @mode == 'select' and (@cards.count+@grave.count) > 0
    printkey(12 + 4 * @select.count, 1, 'w') if @mode == 'select' and @select.count > 0
    color2(30,107)
    goto(1,HEIGHT-1)
    print " "*WIDTH*2
    goto(1,HEIGHT-1)
    if selected_card
      print " [ m ] " + ((@mode == 'select') ? 'move' : 'cancel')
    end
    print " [ p ] quit"
  end
  def printkey(x,y,k)
    goto(x+2,y)
    color2(30,107)
    print "[ #{k} ]"
  end
  def goto(x,y)
    print "\033[#{y};#{x}H"
  end
  def color2(fg,bg)
    print "\033[#{fg};#{bg}m"
  end
  def gtc(x, y, fg, bg)
    print "\033[#{y};#{x}H\033[#{fg};#{bg}m"
  end
  def printcard(x,y,type)
    ss = '━━━'
    if type.is_a? Card
      if type.revealed?
        sel = type.selected?
        red = type.red?
        ss = type        
      else
        type = ''
      end
    end
    bg = type ? 107 : 42
    bg = 106 if type == ''
    bg = 105 if sel 
    cc = red ? 91 : 30
    cc = 97 if red and sel 

    gtc(x, y, cc, bg)
    print "┏#{ss}━━━━┓"
    (1..5).each do |q|
      goto(x, y + q)
      print "┃       ┃"
    end
    goto(x,y+6)
    print "┗━━━━━━━┛"
  end
  def unselect
    @selected_stack = nil
    @all.each(&:unselect)
  end
  def selected_card
    @all.detect(&:selected?)
  end
  def move_to(target_stack)
    from_stack = @selected_stack
    return if from_stack == target_stack
    target_stack = @stacks[target_stack]
    from_stack = @stacks[from_stack] if from_stack
    if from_stack
      index = from_stack.index(selected_card)
      seq = from_stack[index..-1]
    else
      seq = [selected_card]
    end
    last_target = target_stack.last
    if last_target == nil
      return unless selected_card.value == 13
    else
      return if !last_target.accept(seq.first)
    end
    seq.each do |card|
      target_stack << card
      if from_stack
        from_stack.delete(card)
      else
        @select.delete(card)
      end
    end
  end
  def reveal(stack)
    if @stacks[stack].count > 0
      @stacks[stack].last.reveal
    end
  end
  def move_to_target(target)
    ts = @target[target]
    exp = 14
    if ts.count > 0
      if ts.last.value == 14
        exp = 2
      else
        exp = ts.last.value + 1
      end
      return unless selected_card.color == ts.last.color
    end
    return unless selected_card.value == exp
    if @selected_stack
      @stacks[@selected_stack].delete(selected_card)
    else
      @select.delete(selected_card)
    end
    ts << selected_card
  end
  def process(key)
    if @mode == 'select' and key >= '1' and key <= '7'
      prev = @selected_stack
      prevc = selected_card
      unselect
      @selected_stack = key.ord - '1'.ord
      ss = @stacks[@selected_stack]
      revealed = ss.select(&:revealed?)
      return if revealed.count == 0
      if prevc and prev == @selected_stack
        previ = revealed.index(prevc)
        revealed[(previ+1) % revealed.count].select
      else
        revealed.last.select
      end
    elsif @mode == 'select' and key == 'm'
      if selected_card
        @mode = 'move'
      end
    elsif @mode == 'move' and key == 'm'
      @mode = 'select'
    elsif @mode == 'move' and key >= '1' and key <= '7'
      move_to(key.ord - '1'.ord)
      unselect
      @mode = 'select'
    elsif @mode == 'move' and key >= 'a' and key <= 'd'
      move_to_target(key.ord - 'a'.ord)
      unselect
      @mode = 'select'
    elsif @mode == 'select' and key == 'w'
      unselect
      if @select.count > 0
        @select.last.select
      end
    elsif @mode == 'select' and key == 'q'
      unselect
      @select.each do |card| @grave << card end
      @select = []
      3.times do
        c = @cards.shift
        @select << c if c
      end
      if @select.size == 0 and @cards.size == 0
        @cards = @grave
        @grave = []
      end
      @mode = 'select'
    elsif key == 'p'
      print ' '
      exit(1)
    end
    @stacks.each do |stack| stack.last&.reveal end
  end
  def won?
    @target.flatten.count == 52
  end
end

print "\e[?25l"
game = Game.new
while true
  game.render
  key = STDIN.getch
  game.process(key)
  if game.won?
    puts "\033[0m\n You won!"
    exit(0)
  end
end
