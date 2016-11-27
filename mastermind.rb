require_relative 'printer'
require_relative 'AI'

AFFIRM = ["y", "yes", "yep", "sure", "ok", "okay"]
QUIT   = ["q", "quit", "exit"]

BASE_COLOUR = "\e[0;36m"

class Game
  include Printer

  def start
    clear_screen
    special_print(0, "Would you like to play a game of Mastermind?\n", BASE_COLOUR)
    special_print(0, ">>", BASE_COLOUR, "\t")
    response = gets.chomp

    (AFFIRM.include? response.downcase.strip) ? nil : finish

    while true
      special_print(0, "Would you like to be the codemaker or codebreaker?\n", BASE_COLOUR)
      special_print(0, ">>", BASE_COLOUR, "\t")
      response = gets.chomp.downcase.gsub(" ", "")

      if ["codebreaker", "codemaker"].include? response
        response = {"codebreaker"=>0, "codemaker"=>1}[response]
        break
      elsif QUIT.include? response
        finish
      else
        special_print(0, "That is not a valid response: #{response}\n", BASE_COLOUR)
      end
    end

    goto_board(response)
  end

  def goto_board(mode)
    board = Board.new(self, mode)
    result = board.play

    put_result(result)

    start
  end

  def put_result(result)
    case result[0]
    when 0
      special_print(0, "Woops! You ran out of guesses.\n", BASE_COLOUR)
    when 1
      special_print(0, "Congratulations! You win!\n", BASE_COLOUR)
    end
    special_print(0, "The correct code was: #{result[1].join("-")}\n\n", BASE_COLOUR)
    
    special_print(0, "Push enter to continue...", BASE_COLOUR)
    gets
  end

  def finish
    special_print(0, "Goodbye\n", BASE_COLOUR)
    exit
  end
end

class Board
  include Printer, AI

  COLOUR_SET = {:Bl=>"\e[40m\e[30m", # BLACK
                :R =>"\e[41m\e[30m", # RED
                :G =>"\e[42m\e[30m", # GREEN
                :O =>"\e[43m\e[30m", # ORANGE
                :B =>"\e[44m\e[30m", # BLUE
                :P =>"\e[45m\e[30m", # PURPLE
                :T =>"\e[46m\e[30m", # TURQUOISE
                :W =>"\e[47m\e[30m", # WHITE/GREY
                nil=>"\e[0m"}  # Default
  
  BORDER_COLOUR = "\e[37m"

  def initialize(game, type)
    @game       = game
    @type       = type #0 - Codebreaker : 1 - Codemaker
    @guesses    = Array.new(12).map! { |x| x=Array.new(4) }
    @code       = nil
    @black_pegs = Array.new # Win when 4 pegs
  end

  def create
    clear_screen
    print_pipe = lambda { special_print(0 ,"|", BORDER_COLOUR) }
    dynamic_chars = {:Bl=>:*, :W=>:-, nil=>" ", 0=>"  ", 1=>"__"}
    text_format   = {0=>"30m", 1=>"4;30m"}
    # print the title & helper
    title
    # Now we print the board
    special_print(0, " __ __ __ __ _ _\n", BORDER_COLOUR, "\t\t")

    @guesses.each do |guess| # Go through each guess
      key_pegs = key_peg_generator(guess)
      2.times do |i| #Because each row is two rows tall in the shell
        special_print(0, "", nil, "\t\t")
        # Go through each colour in the guess
        guess.each do |peg|
          # Print the appropriate colour based on the block
          print_pipe.call
          special_print(0, dynamic_chars[i], COLOUR_SET[peg].gsub("30m", text_format[i]))
        end
        
        print_pipe.call
        # Print the hint blocks
        special_print(0, dynamic_chars[key_pegs[0]], COLOUR_SET[key_pegs[0]].gsub("30m", text_format[i]))
        print_pipe.call
        special_print(0, dynamic_chars[key_pegs[1]], COLOUR_SET[key_pegs[1]].gsub("30m", text_format[i]))
        print_pipe.call

        key_pegs = key_pegs.drop(2)

        print("\n")
      end
    end
    puts "\e[0mCODE #{@code.to_s}"
    puts "\e[0mGuesses #{@guesses.to_s}"
    puts "\e[0mBlacks #{@black_pegs.to_s}"
    print("\n")
  end
  
  def title
    special_print(0, "___  ___ ___  _____ _____ ______________  ________ _   _______\n", BORDER_COLOUR)
    special_print(0, "|  \\/  |/ _ \\/  ___|_   _|  ___| ___ \\  \\/  |_   _| \\ | |  _  \\\n", BORDER_COLOUR)
    special_print(0, "| .  . / /_\\ \\ `--.  | | | |__ | |_/ / .  . | | | |  \\| | | | |\n", BORDER_COLOUR)
    special_print(0, "| |\\/| |  _  |`--. \\ | | |  __||    /| |\\/| | | | | . ` | | | |\n", BORDER_COLOUR)
    special_print(0, "| |  | | | | /\\__/ / | | | |___| |\\ \\| |  | |_| |_| |\\  | |/ /\n", BORDER_COLOUR)
    special_print(0, "\\_|  |_|_| |_|____/  \\_/ \\____/\\_| \\_\\_|  |_/\\___/\\_| \\_/___/\n\n", BORDER_COLOUR)
    
    special_print(0, "#{BORDER_COLOUR}#{COLOUR_SET[:R]} R-red #{COLOUR_SET[:G]} G-green ", nil)
    special_print(0, "#{BORDER_COLOUR}#{COLOUR_SET[:O]} O-orange #{COLOUR_SET[:B]} B-blue ", nil)
    special_print(0, "#{BORDER_COLOUR}#{COLOUR_SET[:P]} P-purple #{COLOUR_SET[:T]} T-turquoise \n", nil)
  end

  def key_peg_generator(guess)
    return [nil] * 4 unless guess[0]
    
    @black_pegs = Array.new
    white_pegs = Array.new
    
    @code.zip(guess).select { |x, y| x == y }.length.times do
      @black_pegs << :Bl
    end

    (@code.select { |x| guess.include? x }.length - @black_pegs.length).times do
      white_pegs << :W
    end

    result = @black_pegs + white_pegs
    
    return result + [nil] * (4 - result.length)
  end

  def play
    codemaker unless @type == 1
    result = nil
    
    until result
      create
      result = turn
    end
    
    [result, @code]
  end

  def codemaker
    code   = Array.new
    values = COLOUR_SET.keys - [:Bl, :W, nil]

    4.times do
      point   = values.sample
      code   << point
      values -= [point]
    end
    
    @code = code
  end

  def turn
    response = (@black_pegs.length == 4) ? 1 : nil
    response = @guesses[-1][-1].nil? ? nil : 0 unless response
    
    until response
      special_print(0, "What is your guess?\n", BASE_COLOUR)
      special_print(0, ">>", BASE_COLOUR, "\t")
      response = gets.chomp.upcase
      
      response = response.split("")
      
      response.map! { |x| x=x.to_sym }
      
      if (COLOUR_SET.keys - response).length == 5
        @guesses.each_with_index do |guess, index|
          if guess[0].nil?
            @guesses[index] = response
            break
          end
        end
        
        response = nil
        
        break
      elsif [:QUIT, :Q].include? response[0]
        @game.finish
      else
        special_print(0, "Invalid guess: #{response.to_s}\n", BASE_COLOUR)
        response = nil
      end
    end
    
    response
  end

  def codebreaker
    nil
  end
end
