require_relative 'printer'
require_relative 'AI'

AFFIRM = ["y", "yes", "yep", "sure", "ok", "okay"]
QUIT   = ["q", "quit", "exit"]

BASE_COLOUR = "\e[0;36m"
PERMUTATIONS = [:R, :G, :O, :B, :P, :T].repeated_permutation(4).to_a

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

      if ["codebreaker", "codemaker", "0", "1"].include? response
        response = {"codebreaker"=>0, "codemaker"=>1, "0"=>0, "1"=>1}[response]
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
  include Printer

  COLOUR_SET = {:Bl=>"\e[40m\e[37m", # BLACK
                :R =>"\e[41m\e[30m", # RED
                :G =>"\e[42m\e[30m", # GREEN
                :O =>"\e[43m\e[30m", # ORANGE
                :B =>"\e[44m\e[30m", # BLUE
                :P =>"\e[45m\e[30m", # PURPLE
                :T =>"\e[46m\e[30m", # TURQUOISE
                :W =>"\e[47m\e[30m", # WHITE/GREY
                nil=>"\e[0m"}        # Default

  BORDER_COLOUR = "\e[37m" # BLACK

  PREFIX = " " * 20

  def initialize(game, type)
    @game      = game
    @type      = type #0 - Codebreaker : 1 - Codemaker
    @guesses   = Array.new(12).map! { |x| x=Array.new(4) }
    @code      = nil
    @hint_pegs = Array.new # Not nil because length is check before first play

    @ai = AI.new unless @type == 0
  end

  def create
    puts "CODE #{@code}"
    puts "Guesses from create #{@guesses}"
    #clear_screen
    print_pipe = lambda { special_print(0 ,"|", BORDER_COLOUR) }
    dynamic_chars = {:Bl=>:*, :W=>:-, nil=>" ", 0=>"  ", 1=>"__"}
    text_format   = {0=>"30m", 1=>"4;30m"}
    # print the title & helper
    title
    # Now we print the board
    special_print(0, " __ __ __ __ _ _\n", BORDER_COLOUR, PREFIX)
    @guesses.each do |guess| # Go through each guess
      key_pegs = key_peg_generator(guess)
      2.times do |i| #Because each row is two rows tall in the shell
        special_print(0, "", nil, PREFIX)
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

    print("\n")
  end

  def title
    special_print(0, "___  ___ ___  _____ _____ ______________  ________ _   _______\n", BORDER_COLOUR)
    special_print(0, "|  \\/  |/ _ \\/  ___|_   _|  ___| ___ \\  \\/  |_   _| \\ | |  _  \\\n", BORDER_COLOUR)
    special_print(0, "| .  . / /_\\ \\ `--.  | | | |__ | |_/ / .  . | | | |  \\| | | | |\n", BORDER_COLOUR)
    special_print(0, "| |\\/| |  _  |`--. \\ | | |  __||    /| |\\/| | | | | . ` | | | |\n", BORDER_COLOUR)
    special_print(0, "| |  | | | | /\\__/ / | | | |___| |\\ \\| |  | |_| |_| |\\  | |/ /\n", BORDER_COLOUR)
    special_print(0, "\\_|  |_|_| |_|____/  \\_/ \\____/\\_| \\_\\_|  |_/\\___/\\_| \\_/___/\n\n", BORDER_COLOUR)

    special_print(0, "   #{BORDER_COLOUR}#{COLOUR_SET[:R]} R-red #{COLOUR_SET[:G]} G-green ", nil)
    special_print(0, "#{BORDER_COLOUR}#{COLOUR_SET[:O]} O-orange #{COLOUR_SET[:B]} B-blue ", nil)
    special_print(0, "#{BORDER_COLOUR}#{COLOUR_SET[:P]} P-purple #{COLOUR_SET[:T]} T-turquoise \n", nil)
  end

  def key_peg_generator(_guess)
    return [nil] * 4 unless _guess[0]
    guess = _guess.clone
    black_pegs = Array.new
    white_pegs  = Array.new

    @code.zip(guess).select { |x, y| x == y }.length.times do
      black_pegs << :Bl
    end

    @code.each do |char|
      if guess.include? char
        white_pegs << :W
        guess.slice!(guess.index(char))
      end
    end

    black_pegs.length.times { white_pegs.slice!(white_pegs.index(:W)) }

    result = black_pegs + white_pegs
    @hint_pegs = result + [nil] * (4 - result.length)

    @hint_pegs
  end

  def play
    @type == 0 ? codebreaker : codemaker

    result = nil

    until result
      create
      result = check_game_status
      break if result
      puts "Guess OBID #{@guesses.object_id}"
      result = @type == 0 ? turn : @ai.invoke(@guesses, @hint_pegs)

      @guesses.each_with_index do |guess, index|
        if guess[0].nil?
          puts "result #{result}"
          @guesses[index] = result
          break
        end
      end

      result = nil
    end

    [result, @code]
  end

  def check_game_status
    status = @hint_pegs.count(:Bl) == 4 ? 1 : nil
    status = @guesses[-1][-1].nil? ? nil : 0 unless status

    status
  end

  def codemaker
    while true
      special_print(0, "Please give a code for the system to break (don't worry, we wont peek)\n", BASE_COLOUR)
      special_print(0, "The code must contain these characters:- R, G, O, B, P, T\n", BASE_COLOUR)
      special_print(0, ">>", BASE_COLOUR, "\t")
      response = gets.chomp.upcase.split("").map! { |x| x=x.to_sym }

      if PERMUTATIONS.include? response
        @code = response
        break
      else
        special_print("Invalid code: #{response.join("")}")
      end
    end
  end

  def codebreaker
    @code   = PERMUTATIONS.sample
  end

  def turn
    while true
      special_print(0, "What is your guess?\n", BASE_COLOUR)
      special_print(0, ">>", BASE_COLOUR, "\t")
      response = gets.chomp.upcase

      response = response.split("")

      response.map! { |x| x=x.to_sym }

      if PERMUTATIONS.include? response
        break
      elsif [:QUIT, :Q].include? response[0]
        @game.finish
      else
        special_print(0, "Invalid guess: #{response.to_s}\n", BASE_COLOUR)
      end
    end

    response
  end
end
