WIDTH = `tput cols`
HEIGHT = `tput lines`
CARDS = "♥♦♣♠"
GAMEID = ARGV[0] || rand(2**16)

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
    puts @cards
  end
end

Game.new
