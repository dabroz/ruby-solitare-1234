require 'io/console'

WIDTH = `tput cols`.to_i
HEIGHT = `tput lines`.to_i
GAMEID = (ARGV[0] || rand(2**16)).to_i

QCNORMAL = "\033[0m\n"

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
  def suit
    "♥♦♣♠"[color]
  end
  def red?
    color < 2
  end
  def pvalue
    return 'J' if value == 11
    return 'Q' if value == 12
    return 'K' if value == 13
    return 'A' if value == 14
    value
  end
  def to_s
    "#{suit}#{pvalue}"
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
    end
    @stacks.each do |s| s.last.reveal end
    @select = []
    @cards.each(&:reveal)
    3.times do
      @select << @cards.shift
    end
    @target = [[],[],[],[]]
  end
  def renderbg
    goto(1,1)
    color2(90,42)
    (WIDTH * (HEIGHT-2)).times do
      print ' '
    end
  end
  def render
    renderbg
    @stacks.each_with_index do |stack, index|
      stack.each_with_index do |card, cindex|
        printcard(index * 11 + 4, 10 + cindex, card, cindex == stack.count-1)
      end
      printkey(index * 11 + 4, 10 + 15 + 5, index+1)
    end
    @target.each_with_index do |target, index|
      printcard(11+index * 11 + 37-11, 2, target.last)
      printkey(11+index * 11 + 37-11, 1, ('a'.ord + index).chr) if @mode == 'move' 
    end
    printcard(4, 2, '')
    @select.each_with_index do |select, index|
      printcard(11 + 4 + index * 3, 2, select, true, index == @select.count - 1)
    end
    printkey(4, 1, 'q') if @mode == 'select' and (@cards.count+@grave.count) > 0
    printkey(4+11 + 3 * @select.count - 3, 1, 'w') if @mode == 'select' and @select.count > 0
    color2(30,107)
    goto(1,HEIGHT-1)
    print " "*WIDTH*2
    goto(1,HEIGHT-1)
    #color2(30,107)
    print "Mode: #{@mode}"
    if @mode == 'select'
      print " | press key to select card"
      print " | [ r ] to switch to revealing cards"
      print " | [ m ] to move to another stack" if selected_card
   #   print "cards #{@cards.map(&:to_s)} grave #{@grave.map(&:to_s)}"
    elsif @mode == 'move'
      print " | press key to move card"
      print " | [ m ] to cancel"
    elsif @mode == 'reveal'
      print " | press key to reveal hidden card"
      print " | [ r ] to cancel"
    end
    print " | [ p ] to quit"
    #print QCNORMAL
    #goto(WIDTH1,HEIGHT)
  end
  def printkey(x,y,k)
    goto(x+2,y)
    color2(40,107)
    print "[ #{k} ]"
  end
  def goto(x,y)
    print "\033[#{y};#{x}H"
  end
  def color2(fg,bg)
    print "\033[#{fg};#{bg}m"
  end
  def printcard(x,y,type,visible=true,visible2=true)
    if type.is_a? Card and !type.revealed?
      type = ''
    end
    red = false
    red = type.red? if type.is_a? Card
    special = type == ''
    goto(x,y)
    bg = type ? 107 : 42
    bg = 106 if special

    bg = 105 if type.is_a? Card and type.selected?

    color2(30,bg)
    print "┏━━"
    if !visible
      t = type.to_s
      cc = red ? 91 : 30
      cc = 97 if red and type.selected?
      color2(cc,bg)
      print t
      color2(30,bg)
      print "━" * (3-t.length)
    else
      print "━━━"
    end
    print "━━┓"
    (1..5).each do |q|
      goto(x,y+q)
      bg = 104 if special and q == 3
      bg = 103 if special and q == 4
      color2(30,bg)
      t = type.to_s
      t ='' unless q == 3
      n = 7-t.length
      n1 = (n/2).to_i
      n2 = n-n1
      print "┃"
      if type == '' || type == nil
        if special
          color2(30,q < 3 ? 102 : 43)
        end
        print "░░"
        color2(30,bg)
        print "░░"
        if special and q==1
          color2(30,103)
        end
        print "░░"
        color2(30,bg)
        print "░"
      else
        if !visible2
          n2 += n1
          n1 = 0
        end
        print " " * n1

        cc = red ? 91 : 30
        cc = 97 if red and type.selected?
        color2(cc, bg)
        print t
        color2(30,bg)
        print " " * n2
        color2(30,bg)
      end
      print "┃"
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
    @stacks[stack].last.reveal
  end
  def move_to_target(target)
    ts = @target[target]
    exp = 14
    expc = nil
    if ts.count > 0
      if ts.last.value == 14
        exp = 2
      else
        exp = ts.last.value + 1
      end
      expc = ts.last.color
    end
    if expc
      return unless selected_card.color == expc
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
    elsif @mode == 'select' and key == 'r'
      unselect
      @mode = 'reveal'
    elsif @mode == 'select' and key == 'w'
      unselect
      @select.last.select
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
    elsif @mode == 'reveal' and key == 'r'
      @mode = 'select'
    elsif @mode == 'reveal' and key >= '1' and key <= '7'
      reveal(key.ord - '1'.ord)
      unselect
      @mode = 'select'
    elsif key == 'p'
      print ' '
      exit(1)
    end
  end
  def won?
    @stacks.flatten.count == 0 and @cards.count == 0 and @grave.count == 0
  end
end

print "\e[?25l"
at_exit do print "\e[?25h";print QCNORMAL end
game = Game.new
while true
  game.render
  key = STDIN.getch
  game.process(key)
  if game.won?
    print QCNORMAL
    puts " You won!"
    exit(0)
  end
end
