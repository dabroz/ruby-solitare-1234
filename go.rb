WIDTH = `tput rows`
HEIGHT = `tput cols`
CARDS = "♠♥♦♣"
GAMEID = ARGV[1] || rand(2**16)

class Card
end

class Game
end

puts "game #{GAMEID}"
