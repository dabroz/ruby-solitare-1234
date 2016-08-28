WIDTH = `tput cols`
HEIGHT = `tput lines`
CARDS = "♠♥♦♣"
GAMEID = ARGV[0] || rand(2**16)

class Card
  def initialize(num)
    @num = num
  end
  def color
    (num / 13).to_i
  end
  def value
    num % 13 + 1
  end
end

class Game
  def initialize
    @cards = (0...52).map {|n| Card.new(n) }
    puts @cards
  end
end
