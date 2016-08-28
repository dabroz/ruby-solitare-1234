require 'io/console'

WIDTH = `tput cols`.to_i
HEIGHT = `tput lines`.to_i
CARDS = "♥♦♣♠"
GAMEID = (ARGV[0] || rand(2**16)).to_i

#CRED = "\033[1;31m"
#CBLACK = "\033[1;30m"
#CNORMAL = "\033[0m\n"

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
end

class Game
  def initialize
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
        printcard(index * 11 + 4, 10 + cindex, card)
      end
      printkey(index * 11 + 4, 10 + 15, index+1)
    end
    @target.each_with_index do |target, index|
      printcard(11+index * 11 + 37-11, 2, target[0])
    end
    printcard(4, 2, '')
    @select.each_with_index do |select, index|
      printcard(11 + 4 + index * 3, 2, select)
    end
   # p#rint CNORMAL
    color2(30,107)#false,true)
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
  def printcard(x,y,type)
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
    print "┏━━━━"
    if special
      color2(30,103)
    end
    print "━━"
    color2(30,bg)
    print "━┓"
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
        print "░░░░░░░"
      else
        print " " * n1
        color2(red ? 91 : 30, bg)
        print t
        color2(30,bg)
        print " " * n2
      end
      print "┃"
    end
    goto(x,y+6)
    print "┗━━━━━━━┛"
  end
  def unselect
    @all.each(&:unselect)
  end
  def process(key)
    if key >= '1' and key <= '7'
      unselect
      @stacks[key.ord - '1'].last.select
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
end

