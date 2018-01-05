# Most items displayed to screen
module Displayable
  def display_welcome_message
    prompt '------------------------------------------------'
    prompt 'Welcome to Rock, Paper, Scissors, Spock, Lizard!'
    prompt "First to #{self.class::MAX_SCORE} wins!"
    prompt '------------------------------------------------'
  end

  def display_goodbye_message
    prompt '------------------------------------------------------------------'
    prompt 'Thanks for playing Rock, Paper, Scissors, Spock, Lizard. Good bye!'
    prompt '------------------------------------------------------------------'
  end

  def display_moves
    prompt "#{human.name} chose #{human.move}."
    prompt "#{computer.name} chose #{computer.move}."
  end

  def display_game_winner
    winner = human.score == self.class::MAX_SCORE ? human : computer
    prompt "#{winner.name} won the game!"
  end

  def display_score
    human_score = human.score
    computer_score = computer.score
    spacing = ' ' * 16

    prompt '---------Round Score---------'
    prompt "#{human_score}#{spacing}#{computer_score}".center(29)
    prompt '---------Game Score----------'
    prompt "#{human_score.game}#{spacing}#{computer_score.game}".center(29)
    prompt ''
  end

  def display_header
    prompt human.display_in_header + '-----' + computer.display_in_header
  end

  def show_display
    display_moves
    display_winner
    display_header
    display_score
  end

  def clear_screen
    system('clear') || system('cls')
  end
end

# Used for computers that dynamically weight their choices based on move history
module WeightedChoiceConstructor
  def moves_hash(rock, paper, scissors, spock, lizard)
    { 'rock' => rock, 'paper' => paper, 'scissors' => scissors,
      'Spock' => spock, 'lizard' => lizard }
  end

  def update_wins_losses(moves, wins_losses, not_winner = nil)
    winner = @history.winners.last
    move = moves.last
    wins_losses[move] += 1 if winner != not_winner
  end

  def update_wins_losses_percent(wins_losses, wins_losses_percent)
    wins_losses_total = wins_losses.values.inject(:+).to_f
    return if wins_losses_total.zero?
    wins_losses.each do |move, count|
      wins_losses_percent[move] = count / wins_losses_total * 100
    end
  end

  def shift(percent = 0)
    @choice_weights[@move_focus] * percent
  end

  def calc_weights?
    true
  end

  def calc_weights(move_list)
    @move_focus = move_list.last

    return unless calc_weights?
    weight_shifts = {}
    weight_shifts[@move_focus] = @shift

    weight_others = @choice_weights.reject { |k, _| k == @move_focus }
    weight_total = weight_others.values.inject(:+)

    weight_others.each { |k, v| weight_shifts[k] = -v / weight_total * @shift }

    @choice_weights.each_key do |move|
      @choice_weights[move] += weight_shifts[move]
    end
  end

  def choice_ranges
    sum = 0
    @choice_weights.values.map { |item| sum += item }
  end

  def choice
    ranges = choice_ranges
    random = rand(0...100)
    case random
    when (0...ranges[0]) then 'rock'
    when (ranges[0]...ranges[1]) then 'paper'
    when (ranges[1]...ranges[2]) then 'scissors'
    when (ranges[2]...ranges[3]) then 'Spock'
    when (ranges[3]...ranges[4]) then 'lizard'
    end
  end
end

# Methods to help format basic objects
module Formatting
  def prompt(msg)
    puts "=> #{msg}"
  end

  def join_or(array)
    case array.size
    when 1 then array.first
    when 2 then "#{array.first} or #{array.last}"
    else
      result = "#{array[0..-2].join(', ')}, or #{array.last}"
      add_item_num(result)
    end
  end

  def add_item_num(string)
    match_num = 0
    string.gsub(/(\w+\s*\w+)(?=,)|\w+\z/) do |match|
      match_num += 1
      "(#{match_num})#{match}"
    end
  end
end

class Move
  VALUES = %w(rock paper scissors Spock lizard).freeze

  def to_s
    @value
  end
end

class Rock < Move
  def initialize
    @value = 'rock'
  end

  def >(other)
    [Scissors, Lizard].include?(other.class)
  end

  def <(other)
    [Spock, Paper].include?(other.class)
  end
end

class Paper < Move
  def initialize
    @value = 'paper'
  end

  def >(other)
    [Rock, Spock].include?(other.class)
  end

  def <(other)
    [Scissors, Lizard].include?(other.class)
  end
end

class Scissors < Move
  def initialize
    @value = 'scissors'
  end

  def >(other)
    [Paper, Lizard].include?(other.class)
  end

  def <(other)
    [Rock, Spock].include?(other.class)
  end
end

class Spock < Move
  def initialize
    @value = 'Spock'
  end

  def >(other)
    [Rock, Scissors].include?(other.class)
  end

  def <(other)
    [Paper, Lizard].include?(other.class)
  end
end

class Lizard < Move
  def initialize
    @value = 'lizard'
  end

  def >(other)
    [Paper, Spock].include?(other.class)
  end

  def <(other)
    [Rock, Scissors].include?(other.class)
  end
end

class Player
  attr_accessor :move, :name, :score

  def initialize
    set_name
    @score = Score.new
  end

  def make_choice(choice)
    self.move = Object.const_get(choice.capitalize).new
  end

  def display_in_header
    name.center(12)
  end

  def to_s
    name
  end
end

class Human < Player
  VALID_INPUTS = {
    'rock' => 'Rock', 'r' => 'Rock', 'R' => 'Rock', '1' => 'Rock',
    'paper' => 'Paper', 'p' => 'Paper', 'P' => 'Paper', '2' => 'Paper',
    'scissors' => 'Scissors', 's' => 'Scissors', '3' => 'Scissors',
    'Spock' => 'Spock', 'S' => 'Spock', '4' => 'Spock',
    'lizard' => 'Lizard', 'l' => 'Lizard', 'L' => 'Lizard', '5' => 'Lizard'
  }.freeze

  include Formatting

  def set_name
    n = ''
    loop do
      prompt "What's your name?"
      n = gets.chomp.strip
      break unless n.empty?
      prompt 'Sorry, must enter a value.'
    end
    self.name = n
  end

  def choose
    choice = nil
    loop do
      prompt "Please choose #{join_or(Move::VALUES)}:"
      choice = gets.chomp
      break if VALID_INPUTS.keys.include? choice
      prompt 'sorry, invalid choice.'
    end
    choice = VALID_INPUTS[choice]
    make_choice(choice)
  end
end

class Computer < Player
  attr_reader :history

  def initialize(history)
    super()
    @history = history
  end

  def set_name
    self.name = 'Sonny'
  end

  def choose
    choice = Move::VALUES.sample
    make_choice(choice)
  end
end

# Sonny is the default Computer - chooses a random move
class Sonny < Computer; end

# R2D2 always chooses rock
class R2D2 < Computer
  def set_name
    self.name = 'R2D2'
  end

  def choose
    make_choice('rock')
  end
end

# Chappie always tries to tie based on the history of the human's choices.
# The human's last move is used to modify the choice weights by increasing
# the weight of the human's last choice and decreasing the weight of the other
# moves.
class Chappie < Computer
  include WeightedChoiceConstructor

  attr_reader :choice_weights

  def initialize(history)
    super
    @choice_weights = moves_hash(20.0, 20.0, 20.0, 20.0, 20.0)
    @human_wins = moves_hash(0, 0, 0, 0, 0)
    @human_wins_percent = moves_hash(0.0, 0.0, 0.0, 0.0, 0.0)
  end

  def set_name
    self.name = 'Chappie'
  end

  def calc_weights?
    @shift = shift(0.15)
    weight_focus = @choice_weights[@move_focus]
    weight_focus + @shift <= 100
  end

  def choose
    return super if history.games.empty?
    update_wins_losses(history.human_moves, @human_wins)
    update_wins_losses_percent(@human_wins, @human_wins_percent)
    calc_weights(history.human_moves)
    make_choice(choice)
  end
end

# Hal has a very high tendency to choose 'scissors', rarely 'rock', and never
# 'paper'
class Hal < Computer
  include WeightedChoiceConstructor

  def initialize(history)
    super
    @choice_weights = moves_hash(4, 0, 60, 18, 18)
  end

  def set_name
    self.name = 'Hal'
  end

  def choose
    make_choice(choice)
  end
end

# Number 5 always chooses the human's last move
class Number5 < Computer
  def set_name
    self.name = 'Number 5'
  end

  def choose
    history.games.empty? ? super : make_choice(history.human_moves[-1])
  end
end

# EVE chooses based on history of losses.
# EVE always tries to choose the winning move based on history
# Each move starts with an equal probability of being chosen.
# If the computer loses or ties a round, the chance of choosing the move that
# lost decreases and the others increase.
class EVE < Computer
  include WeightedChoiceConstructor

  attr_reader :choice_weights

  def initialize(history)
    super
    @choice_weights = moves_hash(20.0, 20.0, 20.0, 20.0, 20.0)
    @losses = moves_hash(0, 0, 0, 0, 0)
    @loss_percentages = moves_hash(0.0, 0.0, 0.0, 0.0, 0.0)
  end

  def set_name
    self.name = 'EVE'
  end

  def calc_weights?
    @shift = shift(-0.15)
    true
  end

  def choose
    return super if history.games.empty?
    update_wins_losses(history.computer_moves, @losses, name)
    update_wins_losses_percent(@losses, @loss_percentages)
    if last_loss_percent > 20 && last_winner != name
      calc_weights(history.computer_moves)
    end
    make_choice(choice)
  end

  def last_loss_percent
    @loss_percentages[history.computer_moves.last]
  end

  def last_winner
    @history.winners.last
  end
end

# Collaborator class for Player
class Score
  attr_reader :round
  attr_accessor :game

  def initialize
    @round = 0
    @game = 0
  end

  def reset
    @round = 0
  end

  def ==(other)
    @round == other
  end

  def +(other)
    @round += other
    self
  end

  def to_s
    @round.to_s
  end
end

class History
  include Formatting

  attr_reader :human_moves, :computer_moves, :winners, :games, :rounds

  def initialize
    @human_moves = []
    @computer_moves = []
    @winners = []
    @games = []
    @rounds = []
  end

  def add_human_move(move)
    human_moves.push(move.to_s)
  end

  def add_computer_move(move)
    computer_moves.push(move.to_s)
  end

  def add_winner(winner)
    winners.push(winner.to_s)
  end

  def add_game(num)
    games.push(num.to_s)
  end

  def add_round(num)
    rounds.push(num.to_s)
  end

  def update(human_move, computer_move, winner, game, round)
    add_human_move(human_move)
    add_computer_move(computer_move)
    add_winner(winner)
    add_game(game)
    add_round(round)
  end

  # rubocop:disable Metrics/AbcSize
  def format_line(round)
    human_moves[round].center(12) +
      '     ' +
      computer_moves[round].center(12) +
      games[round].center(6) +
      rounds[round].center(8) +
      winners[round].center(12)
  end
  # rubocop:enable Metrics/AbcSize

  def format_history
    result = []
    human_moves.size.times do |round|
      result << format_line(round)
    end
    result
  end

  def display
    prompt '-----------History------------Game--Round-----Winner---'
    format_history.each { |line| prompt line }
    prompt '-------------------------------------------------------'
  end
end

# Game Orchestration Engine
class RPSGame
  include Displayable, Formatting

  OPPONENTS = {
    'EVE' => 'EVE', '1' => 'EVE',
    'Number 5' => 'Number 5', '2' => 'Number 5',
    'R2D2' => 'R2D2', '3' => 'R2D2',
    'Chappie' => 'Chappie', '4' => 'Chappie',
    'Sonny' => 'Sonny', '5' => 'Sonny',
    'Hal' => 'Hal', '6' => 'Hal'
  }.freeze

  MAX_SCORE = 10

  attr_accessor :human, :computer
  attr_reader :history

  def initialize
    clear_screen
    @history = History.new
    @human = Human.new
    choose_opponent
    @game = 1
    @round = 0
  end

  def play
    display_welcome_message
    loop do
      play_round until [human.score, computer.score].include? MAX_SCORE
      show_after_game_display
      break unless play_again?
      next_game
    end
    display_goodbye_message
  end

  private

  def choose_opponent
    opponents = ['EVE', 'Number 5', 'R2D2', 'Chappie', 'Sonny', 'Hal']
    choice = nil
    loop do
      puts "Choose Opponent: #{join_or(opponents)}"
      choice = OPPONENTS[gets.chomp]
      break unless choice.nil?
      prompt 'Input invalid. Please choose again.'
    end
    choice.delete!(' ')
    self.computer = Object.const_get(choice).new(history)
  end

  def update_score
    winner.score += 1
  end

  def log_history
    history.update(human.move, computer.move, winner, @game, @round)
  end

  def display_winner
    msg = winner == 'Tie' ? "It's a tie!" : "#{winner} won the round!"
    prompt msg
  end

  def winner
    human_move = human.move
    computer_move = computer.move
    if human_move > computer_move
      human
    elsif human_move < computer_move
      computer
    else
      'Tie'
    end
  end

  def next_round
    @round += 1
  end

  def next_game
    human.score.reset
    computer.score.reset
    @game += 1
    @round = 0
  end

  def show_after_game_display
    display_game_winner
    update_game_count
    history.display
    show_display
  end

  def update_game_count
    game_winner = human.score == MAX_SCORE ? human : computer
    game_winner.score.game += 1
  end

  def play_again?
    answer = nil
    loop do
      prompt 'Would you like to play again? (y/n)'
      answer = gets.chomp.downcase
      break if %w(y n).include? answer
      prompt 'Sorry, must be y or n.'
    end
    answer == 'y'
  end

  def play_round
    next_round
    human.choose
    computer.choose
    display_winner
    log_history
    update_score unless winner == 'Tie'
    clear_screen

    history.display
    show_display
  end
end

RPSGame.new.play
