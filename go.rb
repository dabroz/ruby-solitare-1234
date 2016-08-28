require 'io/console'

WIDTH = `tput cols`.to_i
HEIGHT = `tput lines`.to_i
CARDS = "♥♦♣♠"
GAMEID = (ARGV[0] || rand(2**16)).to_i

#CRED = "\033[1;31m"
#CBLACK = "\033[1;30m"
#CNORMAL = "\033[0m\n"

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
    CARDS[color]
  end
  def red?
    color < 2
  end
  #def pcolor
  #  red? ? CRED : CBLACK
  #end
  def pvalue
    #return '⑽' if value == 10
    return 'J' if value == 11
    return 'Q' if value == 12
    return 'K' if value == 13
    return 'A' if value == 14
    value
  end
  def to_s
    "#{suit}#{pvalue}"
    #pcolor + "#{suit}#{value}" + CNORMAL
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
    #puts "cards"
    #puts @cards
    #puts "stacks:"
    #@stacks.each do |s| puts "s:"; puts s end
  end
  def renderbg
    goto(1,1)
    color2(90,42)
    (HEIGHT-1).times do
      WIDTH.times do
        print ' '
      end
    end
  end
  def render
    renderbg
    @stacks.each_with_index do |stack, index|
      stack.each_with_index do |card, cindex|
        printcard(index * 11 + 4, 10 + cindex, card, cindex == stack.count-1)
      end
      printkey(index * 11 + 4, 10 + 15, index+1)
    end
    @target.each_with_index do |target, index|
      printcard(11+index * 11 + 37-11, 2, target[0])
      printkey(11+index * 11 + 37-11, 1, ('a'.ord + index).chr)
    end
    printcard(4, 2, '')
    @select.each_with_index do |select, index|
      printcard(11 + 4 + index * 3, 2, select)
    end
    # p#rint CNORMAL
    goto(1,HEIGHT)
    print " "*WIDTH
    goto(1,HEIGHT)
    color2(30,107)#false,true)
    print "Mode: #{@mode}"
    if @mode == 'select'
      print " | press key to select card"
      print " | [ r ] to switch to revealing cards"
      print " | [ m ] to move to another stack" if selected_card
    elsif @mode == 'move'
      print " | press key to move card"
      print " | [ m ] to cancel"
    end
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
  def printcard(x,y,type,visible=true)
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
    from_stack = @stacks[from_stack]
    index = from_stack.index(selected_card)
    seq = from_stack[index..-1]
    last_target = target_stack.last
    if last_target == nil
      print "TODO"; abort
    else
      if !last_target.accept(seq.first)
        #print QCNORMAL
        #puts "last = #{last_target}"
        ##puts "next = #{seq.first}"
        #a#bort
        #  @mode = 'select'
        #  unselect
        return
      end
    end
    seq.each do |card|
      target_stack << card
      from_stack.delete(card)
    end
  end
  def reveal(stack)
    @stacks[stack].last.reveal
  end
  def process(key)
    if @mode == 'select' and key >= '1' and key <= '7'
      prev = @selected_stack
      prevc = selected_card
      unselect
      @selected_stack = key.ord - '1'.ord
      ss = @stacks[@selected_stack]
      revealed = ss.select(&:revealed?)
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
    elsif @mode == 'select' and key == 'r'
      unselect
      @mode = 'reveal'
    elsif @mode == 'reveal' and key >= '1' and key <= '7'
      reveal(key.ord - '1'.ord)
      unselect
      @mode = 'select'
    else
      abort
    end
  end
end

# ╔═╗ ╚╝ ░ ▒ ▓ ║
#CNORMAL = "\033[0m\n"
print "\e[?25l"
game = Game.new
while true
  game.render
  key = STDIN.getch
  game.process(key)
  game.render
end
