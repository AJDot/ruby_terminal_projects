module Displayable
  def display_welcome_message
    puts 'Welcome to Tic Tac Toe!'
    puts "The first to #{TTTGame::ROUNDS_TO_WIN}"
    puts ''
  end

  def display_goodbye_message
    puts 'Thanks for playing Tic Tac Toe! Goodbye!'
  end

  def clear_screen_and_display_board
    clear
    display_board
  end

  def clear_screen_and_display_board_score
    clear_screen_and_display_board
    display_score
  end

  def display_board
    puts "#{human} is #{human.marker}. #{computer} is #{computer.marker}."
    puts ''
    board.draw
    puts ''
  end

  def display_board_score
    display_board
    display_score
  end

  def display_score
    puts "#{human}: #{human.score} | #{computer}: #{computer.score}"
  end

  def display_result
    clear_screen_and_display_board
    display_score

    case board.winning_marker
    when human.marker    then puts "#{human} won!"
    when computer.marker then puts "#{computer} won!"
    else                      puts "It's a tie!"
    end
    press_enter_to_continue
  end

  def display_play_again_message
    puts "Let's play again!"
    puts ''
  end
end

module Helpers
  def press_enter_to_continue
    puts 'Press ENTER to continue'
    gets
  end

  def joinor(array, delimiter = ', ', conjunction = 'or')
    case array.size
    when 0 then ''
    when 1 then array.first
    when 2 then array.join(" #{conjunction} ")
    else
      "#{array[0..-2].join(delimiter)} #{conjunction} #{array.last}"
    end
  end

  def clear
    system('clear') || system('cls')
  end
end

class Board
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] +  # rows
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] +  # cols
                  [[1, 5, 9], [3, 5, 7]]               # diagonals

  def initialize
    @squares = {}
    reset
  end

  def [](key)
    @squares[key]
  end

  def []=(key, marker)
    @squares[key].marker = marker
  end

  def unmarked_keys
    @squares.keys.select { |key| @squares[key].unmarked? }
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won?
    !!winning_marker
  end

  def winning_marker
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      return squares.first.marker if identical_markers?(squares, 3)
    end
    nil
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end

  # rubocop:disable Metrics/AbcSize
  def draw
    puts '     |     |'
    puts "  #{@squares[1]}  |  #{@squares[2]}  |  #{@squares[3]}"
    puts '     |     |'
    puts '-----+-----+-----'
    puts '     |     |'
    puts "  #{@squares[4]}  |  #{@squares[5]}  |  #{@squares[6]}"
    puts '     |     |'
    puts '-----+-----+-----'
    puts '     |     |'
    puts "  #{@squares[7]}  |  #{@squares[8]}  |  #{@squares[9]}"
    puts '     |     |'
  end
  # rubocop:enable Metrics/AbcSize

  def at_risk_marker_keys
    WINNING_LINES.each_with_object({}) do |line, result|
      squares = @squares.select { |k, _| line.include? k }
      next unless identical_markers?(squares.values, 2)

      risk_marker = marked_marker(squares, :marked?).marker
      risk_square = marked_marker(squares, :unmarked?)
      risk_key = @squares.key(risk_square)

      append_to_hash_value_array(result, risk_marker, risk_key)
    end
  end

  private

  def identical_markers?(squares, count)
    markers = squares.select(&:marked?).collect(&:marker)
    return false if markers.size != count
    markers.min == markers.max
  end

  def marked_marker(squares, is_marked)
    squares.values.select(&is_marked).first
  end

  def append_to_hash_value_array(hash, key, value)
    hash[key] = [value] if hash[key].nil?
    hash[key] << value unless hash[key].include? value
  end
end

class Square
  INITIAL_MARKER = ' '.freeze

  attr_accessor :marker

  def initialize(marker = INITIAL_MARKER)
    @marker = marker
  end

  def to_s
    @marker
  end

  def unmarked?
    marker == INITIAL_MARKER
  end

  def marked?
    marker != INITIAL_MARKER
  end
end

class Player
  attr_reader :marker, :score

  def initialize(marker)
    @marker = marker
    @score = Score.new
  end

  def reset
    score.reset
  end

  def pick_name
    name = nil
    loop do
      name = gets.chomp.strip
      break unless name.empty?
      puts 'Sorry, name cannot be empty. Try again.'
    end
    @name = name
  end

  def to_s
    @name.to_s
  end
end

class Score
  attr_reader :value

  def initialize
    @value = 0
  end

  def increment
    @value += 1
  end

  def reset
    @value = 0
  end

  def to_s
    @value.to_s
  end
end

class TTTGame
  include Displayable, Helpers

  MARKER_1 = 'X'.freeze
  MARKER_2 = 'O'.freeze
  FIRST_TO_MOVE = MARKER_1
  ROUNDS_TO_WIN = 5

  attr_reader :board, :human, :computer

  def initialize
    @board = Board.new
    @human = Player.new(pick_human_marker)
    @computer = Player.new(pick_computer_marker)
    @current_marker = FIRST_TO_MOVE
  end

  def play
    setup_game

    loop do
      reset
      display_board_score

      play_round
      next unless someone_won_game?
      break unless play_again?
      setup_next_game
    end

    display_goodbye_message
  end

  private

  def play_round
    loop do
      current_player_moves
      break if board.someone_won? || board.full?
      clear_screen_and_display_board_score if human_turn?
    end

    update_score
    display_result
  end

  def setup_game
    clear
    display_welcome_message
    pick_names
  end

  def setup_next_game
    display_play_again_message
    human.reset
    computer.reset
  end

  def pick_human_marker
    marker = nil
    loop do
      puts "Choose your marker (#{MARKER_1} or #{MARKER_2})"
      marker = gets.chomp.upcase!
      break if [MARKER_1, MARKER_2].include? marker
      'Marker invalid. Please choose again.'
    end
    marker
  end

  def pick_computer_marker
    [MARKER_1, MARKER_2].reject { |marker| marker == human.marker }.first
  end

  def pick_names
    puts 'Choose your name:'
    human.pick_name
    puts "Choose the computer's name"
    computer.pick_name
  end

  def someone_won_game?
    [human.score.value, computer.score.value].include? ROUNDS_TO_WIN
  end

  def human_turn?
    @current_marker == human.marker
  end

  def human_moves
    unmarked_keys = board.unmarked_keys

    puts "Choose a square (#{joinor(unmarked_keys)}): "
    square = nil
    loop do
      square = gets.chomp.to_i
      break if unmarked_keys.include?(square)
      puts "Sorry, that's not a valid choice."
    end

    board[square] = human.marker
  end

  def computer_moves
    keys = computer_key_choices
    board[keys.sample] = computer.marker
  end

  def computer_key_choices
    board.at_risk_marker_keys[computer.marker] ||
      board.at_risk_marker_keys[human.marker] ||
      ([5] if center_available?) ||
      board.unmarked_keys
  end

  def center_available?
    board.unmarked_keys.include? 5
  end

  def current_player_moves
    human_turn? ? human_moves : computer_moves
    switch_player
  end

  def switch_player
    @current_marker = human_turn? ? computer.marker : human.marker
  end

  def update_score
    case board.winning_marker
    when human.marker
      human.score.increment
    when computer.marker
      computer.score.increment
    end
  end

  def play_again?
    answer = nil
    loop do
      puts 'Would you like to play again? (y/n)'
      answer = gets.chomp.downcase
      break if %w(y n).include? answer
      puts 'sorry, must by y or n'
    end

    answer == 'y'
  end

  def reset
    board.reset
    @current_marker = FIRST_TO_MOVE
    clear
  end
end

game = TTTGame.new
game.play
