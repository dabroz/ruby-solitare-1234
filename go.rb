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
    pcolor + "#{suit}#{value}" + CNORMAL
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
    print CNORMAL
  end
  def goto(x,y)
    print "\033[#{x};#{y}H"
  end
  def color(fg,bg,bold)
    print "\033[" + (bold ? "1;" : "") + "3#{fg};4#{bg}m"
  end
  def printcard(x,y,type)
    goto(x,y)
    print "╔════╗"
    goto(x,y+6)
    print "╚════╝"
  end
end

# ╔═╗ ╚╝ ░ ▒ ▓ ║

Game.new.render
STDIN.getch
#print CNORMAL
