require 'io/console'

WIDTH = `tput cols`.to_i
HEIGHT = `tput lines`.to_i
CARDS = "♥♦♣♠"
GAMEID = (ARGV[0] || rand(2**16)).to_i

CRED = "\033[1;31m"
CBLACK = "\033[1;30m"
CNORMAL = "\033[0m\n"

class Card
  def initialize(num)
    @num = num
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
  def pcolor
    red? ? CRED : CBLACK
  end
  def to_s
    "#{suit}#{value}"
    #pcolor + "#{suit}#{value}" + CNORMAL
  end
end

class Game
  def initialize
    @cards = (0...52).map {|n| Card.new(n) }
    @cards.shuffle!(random: Random.new(GAMEID))
    @stacks = [[],[],[],[],[],[],[]]
    (1..7).each do |n|
      n.times do
        @stacks[n - 1] << @cards.shift
      end
    end
    @select = []
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
    color(0,2,0)
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
        printcard(index * 11 + 4, 9 + cindex, card)
      end
    end
    @target.each_with_index do |target, index|
      printcard(index * 11 + 36, 2, target[0])
    end
    print CNORMAL
  end
  def goto(x,y)
    print "\033[#{y};#{x}H"
  end
  def color(fg,bg,bold,bgbold=false)
    print "\033[#{bold ? 9 : 3}#{fg};#{bgbold ? 10 : 4}#{bg}m"
  end
  def printcard(x,y,type)
    red = false
    red = type.red? if type.is_a? Card
    goto(x,y)
     color(0,7,false,true)
    print "┏"
   # color(7,0,true,false)
    print "━━━━━━━"
    # color(0,7,false,true)
    print "┓"
    (1..5).each do |q|
      goto(x,y+q)
      t = type.to_s
      t ='' unless q == 3
      n = 7-t.length
      n1 = (n/2).to_i
      n2 = n-n1
     # print "t [#{t}] t #{t.length} n #{n} n1 #{n1} n2 #{n2}"
      print "┃"
      if type == nil
        print "░░░░░░░"
      else
      print " " * n1
      color(red ? 1 : 0, 7, red, true)
#      print type.pcolor
      print t
     color(0,7,false,true)
      #print CNORMAL
      print " " * n2
    end
      print "┃"
    end
    goto(x,y+6)
    print "┗━━━━━━━┛"
  end
end

# ╔═╗ ╚╝ ░ ▒ ▓ ║

Game.new.render
STDIN.getch
#print CNORMAL
