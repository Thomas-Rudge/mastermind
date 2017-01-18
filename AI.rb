class AI
  def initialize
    @last_pegs    = Array.new
    @guess_count  = -1
    @valid_chars  = [:R, :G, :O, :B, :P, :T]
    @permutations = @valid_chars.repeated_permutation(4).to_a
  end

  def invoke(latest_guesses, latest_pegs)
    sleep 0.8 # Because fast AI are scary
    guesses  = Marshal.load(Marshal.dump(latest_guesses))
    pegs     = Marshal.load(Marshal.dump(latest_pegs))
    response = nil # This will be returned
    pegs     = pegs.compact
    guess    = guesses[@guess_count]
    @permutations -= [guess] # Don't make the same guess twice
    # First guess is one random character
    if @guess_count == -1
      response = [@valid_chars.sample] * 4
    # Not sure if this would ever happen (>_<)
    elsif @permutations.length == 1
      response = @permutations[0]
    else
      # A bad guess is removed from the list of possible permutations
      # A bad colour is removed from the list of valid colours, and permutations
      # with that colour are removed from the list of possible permutations.
      # The AI first tries to get four pegs and then either jumbles or rotates the guess to win
      # This method assumes the peg count will always stay the same or go up.
      # This isn't the most optimum method, but it gives the user a chance at winning.
      case
      when pegs.length == 0
        guess.uniq.each do |char|
          @permutations = @permutations.reject { |x| x.include? char }
          @valid_chars -= [char]
        end

        response = [@valid_chars.sample] * 4
      when pegs.length == 1
        @valid_chars -= [guess[0]]
        char = @valid_chars.sample
        @valid_chars -= [char]

        response = [guess[0]] + ([char] * 3)
      when pegs.length == 2
        if guess.uniq.length == 1
          @valid_chars -= [guess[0]]
        elsif guess.uniq.length == 2 && guesses[@guess_count-1].uniq.length == 2
          @valid_chars -= [guesses[@guess_count-1][-1]]
        elsif (guess.uniq.length == 2 &&
               guesses[@guess_count-1].uniq.length == 1) ||
               guess.uniq.length == 3
          @valid_chars -= [guess[-1]]
        end

        until response
          response = guess[0, 2] + ([@valid_chars.sample] * 2)
          response = response == guess ? nil : response
        end
      when pegs.length == 3
        @valid_chars -= [guess[-1]]
        response = guess[0, 3] + [@valid_chars.sample]
      when pegs.length == 4
        @permutations = @permutations.select { |x| x.sort == guess.sort }

        if pegs.count(:W) == 4
          until response
            response = guess.shuffle
            response = (@permutations.include? response) ? response : nil
          end
        else
          until response
            response = [true, false].sample ? guess.shuffle : guess.rotate
            response = (@permutations.include? response) ? response : nil
          end
        end
      end
    end

    response = @permutations.sample unless response # Always ensure response
    @guess_count += 1

    response
  end
end
