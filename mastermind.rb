require_relative 'printer', 'AI'

AFFIRM = ["y", "yes", "yep", "sure", "ok", "okay"]
QUIT   = ["q", "quit", "exit"]

BASE_COLOUR = "\e[0;36m"

class Game
  include printer
  
  def start
    clear_screen
    special_printer(0, "Would you like to play a game of Mastermind?\n", BASE_COLOUR)
    special_printer(0, ">>", BASE_COLOUR, "\t")
    response = gets.chomp
    
    (AFFIRM.include? response.downcase.strip) ? nil : finish
    
    while true
      special_printer(0, "Would you like to be the codemaker or codebreaker?\n", BASE_COLOUR)
      special_printer(0, ">>", BASE_COLOUR, "\t")
      response = gets.chomp.downcase.gsub(" ", "")
      
      if ["codebreaker", "codemaker"].include? response
        response = {"codebreaker"=>0, "codemaker"=>1}[response]
        break
      elsif QUIT.include? response
        finish
      else
        special_printer(0, "That is not a valid response: #{response}\n", BASE_COLOUR)
    end
    
    goto_board(response)
  end

  def goto_board(mode)
    board = Board.new(self, mode)
    result = board.play
    
    put_result(result)
    
    start
  end
  
  def put_result
    nil
  end
  
  def finish
    special_print(0, "Goodbye\n", BASE_COLOUR)
    exit
  end
end

class Board
  include printer, AI
  "\e[0;36m"
  COLOUR_SET = {R: "\e[0;41m", # RED
                G: "\e[0;42m", # GREEN
                O: "\e[0;43m", # ORANGE
                B: "\e[0;44m", # BLUE
                P: "\e[0;45m", # PURPLE
                T: "\e[0;46m"} # TURQUOISE
  
  def initialize(game, type)
    @game    = game
    @type    = type #0 - Codebreaker : 1 - Codemaker
    @guesses = Array.new(12).map! { |x| x=Array.new(4) }
    @code    = nil
  end
  
  def build
    board_colour  = "\e[0;47m"
    border_colour = "\e[30m"
    # print the helper
    special_print(0, "#{border_colour}#{COLOUR_SET[:R]} R-red :#{COLOUR_SET[:G]} G-green :", nil)
    special_print(0, "#{border_colour}#{COLOUR_SET[:O]} O-orange :#{COLOUR_SET[:B]} B-blue :", nil)
    special_print(0, "#{border_colour}#{COLOUR_SET[:P]} P-purple :#{COLOUR_SET[:T]} T-turquoise", nil)
    print "\n\n"
    # Now we print the board grid
    special_print(0, " __ __ __ __ _ _\n", border_colour, "\t")
    
    @guesses.each do |guess| # Go through each guess
      special_print(0 ,"|", border_colour, "\t")
      
      guess.each do |block|  # Go through each colour in the guess
        # Print the appropriate colour based on the block
      end
      # Print the hint blocks
    end
      
    
    
  end
  
  def display
  end
  
  def play
    codemaker unless @type == 1
    view = build
    display(view)
    
    turn
  end
  
  def codemaker
    code   = ""
    values = COLOUR_SET.keys
    
    4.times do
      point   = values.sample
      code   << point.to_s
      values -= [point]
    end
      
    @code = code
  end
  
  def codebreaker
  end
end


