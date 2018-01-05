SCORE_TO_WIN = 5
VALID_CHOICES = %w(rock paper scissors lizard Spock)
letter_to_word = {}
VALID_CHOICES.each do |word|
  letter = word[0]
  letter_to_word[letter] = word
end
puts letter_to_word.inspect

def prompt(message)
  Kernel.puts("=> #{message}")
end

def win?(first, second)
  # Defining winning situations in this way allows you to change the
  # choices to whatever you want.
  [
    [VALID_CHOICES[2], VALID_CHOICES[1]],
    [VALID_CHOICES[1], VALID_CHOICES[0]],
    [VALID_CHOICES[0], VALID_CHOICES[3]],
    [VALID_CHOICES[3], VALID_CHOICES[4]],
    [VALID_CHOICES[4], VALID_CHOICES[2]],
    [VALID_CHOICES[2], VALID_CHOICES[3]],
    [VALID_CHOICES[3], VALID_CHOICES[1]],
    [VALID_CHOICES[1], VALID_CHOICES[4]],
    [VALID_CHOICES[4], VALID_CHOICES[0]],
    [VALID_CHOICES[0], VALID_CHOICES[2]]
  ].include?([first, second])
end

def display_results(player, computer)
  if win?(player, computer)
    prompt("You won!")
  elsif win?(computer, player)
    prompt("Computer won!")
  else
    prompt("It's a tie!")
  end
end

def get_valid_input(input, choices)
  if choices.key?(input)
    choices[input]
  elsif choices.key?(input.swapcase)
    choices[input.swapcase]
  else
    ''
  end
end

def display_score(player_score, cpu_score)
  prompt("------------Score------------")
  prompt("----You---- ||||| ----CPU----")
  prompt("#{format('%7.3d', player_score)}#{format('%18.3d', cpu_score)}")
end

prompt("------------------------------------------------")
prompt("Welcome to Rock, Paper, Scissors, Lizard, Spock!")
prompt("First to #{SCORE_TO_WIN} wins!")
prompt("------------------------------------------------")
puts

loop do # main loop
  player_score = 0
  cpu_score = 0

  loop do # game loop
    choice = ''

    loop do # user choice loop
      prompt("Choose one: #{VALID_CHOICES.join(', ')}")
      prompt("Input first letter to make selection.")
      letter_choice = Kernel.gets().chomp()

      # If the letter is in the choice hash, select it
      # elsif the downcase of letter is in hash, select it
      # else return empty string
      choice = get_valid_input(letter_choice, letter_to_word)

      break unless choice == '' # break if valid choice was made
      prompt("That's not a valid choice.")
    end

    cpu_choice = VALID_CHOICES.sample

    Kernel.puts("You chose: #{choice}; Computer chose: #{cpu_choice}")

    display_results(choice, cpu_choice)

    if win?(choice, cpu_choice)
      player_score += 1
    elsif win?(cpu_choice, choice)
      cpu_score += 1
    end
    display_score(player_score, cpu_score)

    winner = if player_score == SCORE_TO_WIN
               "You"
             elsif cpu_score == SCORE_TO_WIN
               "The CPU"
             end
    if winner
      prompt("#{winner} won the game!")
      break
    end
  end

  prompt("Do you want to play again?")
  answer = Kernel.gets().chomp()
  break unless answer.downcase().start_with?('y')
end

prompt("Thank you for playing. Good bye!")
