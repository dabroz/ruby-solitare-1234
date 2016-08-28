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
    "#{'♥♦♣♠'[color]}#{value != 10 ? ' ' : '1'}#{'01234567890JQKA'[value]}"
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
    @mode = true
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
    gtcp 1, 1, 90, 42, ' ' * (WIDTH * (HEIGHT-2))
    @stacks.each_with_index do |stack, index|
      stack.each_with_index do |card, cindex|
        printcard(index * 11 + 4, 10 + cindex, card)
      end
      printkey(index * 11 + 4, 10 + 15 + 5, index+1)
    end
    @target.each_with_index do |target, index|
      x = index * 11 + 37
      printcard(x, 2, target.last)
      printkey(x, 1, %w(a b c d)[index])
    end
    printcard(4, 2, '')
    @select.each_with_index do |select, index|
      printcard(15 + index * 4, 2, select)
    end
    printkey(4, 1, 'q')
    printkey(12 + 4 * @select.count, 1, 'w')
    gtcp 1, HEIGHT - 1, 30, 107, " [ m ] #{@mode ? 'move' : 'cancel'}#{' '*40}"
  end
  def printkey(x,y,k)
    gtcp x + 2, y, 30, 107, "[ #{k} ]"
  end
  def gtcp x, y, fg, bg, t = ''
    print "\033[#{y};#{x}H\033[#{fg};#{bg}m#{t}"
  end
  def printcard(x,y,type)
    ss = '━━━'
    cc = 30
    bg = 42
    if type
      bg = 107
      if type.is_a? Card
        if type.revealed?
          sel = type.selected?
          ss = type
          if type.red?
            cc = sel ? 97 : 91
          end
          bg = 105 if sel
        else
          type = ''
        end
        bg = 106 if type == ''
      end
    end
    gtcp x, y + 0, cc, bg, "┏#{ss}━━━━┓"
    (1..5).each do |q|
      gtcp x, y + q, cc, bg, "┃       ┃"
    end
    gtcp x, y + 6, cc, bg, "┗━━━━━━━┛"
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
    if @mode and key >= '1' and key <= '7'
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
    elsif @mode and key == 'm'
      @mode = false if selected_card
    elsif !@mode and key == 'm'
      @mode = true
    elsif !@mode and key >= '1' and key <= '7'
      move_to(key.ord - '1'.ord)
      unselect
      @mode = true
    elsif !@mode and key >= 'a' and key <= 'd'
      move_to_target(key.ord - 'a'.ord)
      unselect
      @mode = true
    elsif @mode and key == 'w'
      unselect
      @select.last&.select
    elsif @mode and key == 'q'
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
    end
    @stacks.each do |stack| stack.last&.reveal end
  end
end

print "\e[?25l"
game = Game.new
while true
  game.render
  key = STDIN.getch
  game.process(key)
end
