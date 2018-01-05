module Formatting
  def clear_screen
    system('clear') || system('cls')
  end

  def press_enter_to_continue
    puts "Press ENTER to continue..."
    gets
  end

  def join_or(array)
    case array.size
    when 0 then ''
    when 1 then array.first
    when 2 then "#{array.first} or #{array.last}"
    else "#{array[0..-2].join(', ')}, or #{array.last}"
    end
  end
end

class Grid
  attr_reader :squares

  def initialize
    # model the 6x7 grid using 'squares'
    # probably using a hash of square object to keep track of them
    reset
  end

  def display
    puts "+---+---+---+---+---+---+---+"
    puts "| #{squares[[6, 1]]} | #{squares[[6, 2]]} | #{squares[[6, 3]]} | #{squares[[6, 4]]} | #{squares[[6, 5]]} | #{squares[[6, 6]]} | #{squares[[6, 7]]} |"
    puts "|---|---|---|---|---|---|---|"
    puts "| #{squares[[5, 1]]} | #{squares[[5, 2]]} | #{squares[[5, 3]]} | #{squares[[5, 4]]} | #{squares[[5, 5]]} | #{squares[[5, 6]]} | #{squares[[5, 7]]} |"
    puts "|---|---|---|---|---|---|---|"
    puts "| #{squares[[4, 1]]} | #{squares[[4, 2]]} | #{squares[[4, 3]]} | #{squares[[4, 4]]} | #{squares[[4, 5]]} | #{squares[[4, 6]]} | #{squares[[4, 7]]} |"
    puts "|---|---|---|---|---|---|---|"
    puts "| #{squares[[3, 1]]} | #{squares[[3, 2]]} | #{squares[[3, 3]]} | #{squares[[3, 4]]} | #{squares[[3, 5]]} | #{squares[[3, 6]]} | #{squares[[3, 7]]} |"
    puts "|---|---|---|---|---|---|---|"
    puts "| #{squares[[2, 1]]} | #{squares[[2, 2]]} | #{squares[[2, 3]]} | #{squares[[2, 4]]} | #{squares[[2, 5]]} | #{squares[[2, 6]]} | #{squares[[2, 7]]} |"
    puts "|---|---|---|---|---|---|---|"
    puts "| #{squares[[1, 1]]} | #{squares[[1, 2]]} | #{squares[[1, 3]]} | #{squares[[1, 4]]} | #{squares[[1, 5]]} | #{squares[[1, 6]]} | #{squares[[1, 7]]} |"
    puts "+---+---+---+---+---+---+---+"
  end

  def [](row, col)
    squares[[row, col]]
  end

  def next_row(col)
    (1..7).each do |row|
      return row if squares[[row, col]].marker == Square::INITIAL_MARKER
    end
    nil
  end

  def available_cols
    result = []
    (1..7).each do |col|
      result << col if squares[[6, col]].marker == Square::INITIAL_MARKER
    end
    result
  end

  def next_row(col)
    (1..7).each do |row|
      return row if squares[[row, col]].marker == Square::INITIAL_MARKER
    end
  end

  def full?
    available_cols.empty?
  end

  def reset
    @squares = {}
    (1..6).to_a.product((1..7).to_a).each do |row, column|
      @squares[[row, column]] = Square.new
    end
  end

  def someone_won?
    !!winning_marker
  end

  def winning_marker
    winning_lines.each do |line|
      squares = @squares.values_at(*line)
      next unless squares.select(&:marked?).count == 4
        markers = squares.collect(&:marker)
        return squares.first.marker if markers.min == markers.max
    end
    nil
  end

  def winning_lines
    result = []
    # Get all winning lines horizontal
    (1..6).each do |row|
      (1..4).each do |col|
        line = []
        line << [row, col]
        line << [row, col + 1]
        line << [row, col + 2]
        line << [row, col + 3]
        result << line
      end
    end
    # Get all winning lines vertical
    (1..3).each do |row|
      (1..7).each do |col|
        line = []
        line << [row, col]
        line << [row + 1, col]
        line << [row + 2, col]
        line << [row + 3, col]
        result << line
      end
    end
    # Get all winning line diagonal up-right
    (1..3).each do |row|
      (1..4).each do |col|
        line = []
        line << [row, col]
        line << [row + 1, col + 1]
        line << [row + 2, col + 2]
        line << [row + 3, col + 3]
        result << line
      end
    end
    # Get all winning line diagonal down-left
    (4..6).each do |row|
      (1..4).each do |col|
        line = []
        line << [row, col]
        line << [row - 1, col + 1]
        line << [row - 2, col + 2]
        line << [row - 3, col + 3]
        result << line
      end
    end
    result
  end
end

class Square
  INITIAL_MARKER = ' '.freeze

  attr_accessor :marker

  def initialize(marker = INITIAL_MARKER)
    # keep track of the marker in this square
    @marker = marker
  end

  def marked?
    @marker != INITIAL_MARKER
  end

  def unmarked?
    @marker == INITIAL_MARKER
  end

  def to_s
    @marker
  end
end

class Player
  attr_reader :name, :marker

  @@player_count = 0

  def initialize(marker)
    # set player's name, marker
    @marker = marker
    @@player_count += 1
    @player_num = @@player_count
    set_name
  end

  def set_name
    name = nil
    loop do
      puts "What is the name of Player #{@player_num}?"
      name = gets.chomp.strip
      break unless name.empty?
      puts "Sorry, you must enter a value."
    end
    @name = name
  end

  def to_s
    name
  end
end

class Human < Player; end

class Computer < Player; end

class Connect4
  include Formatting

  attr_reader :grid, :player1, :player2

  PLAYER1_MARKER = 'X'
  PLAYER2_MARKER = 'O'

  def initialize
    clear_screen
    @grid = Grid.new
    @player1 = Human.new(PLAYER1_MARKER)
    choose_player2
    @current_player = @player1
  end

  def play
    clear_screen
    display_welcome_message
    press_enter_to_continue
    loop do
      reset
      play_round
      clear_screen
      display_grid
      display_result
      break unless play_again?
    end
      display_goodbye_message
  end

  private

  def play_round
    loop do
      clear_screen
      display_grid
      player_moves
      break if grid.someone_won? || grid.full?
    end
  end

  def play_again?
    choice = nil
    loop do
      puts "Would you like to play again? (y/n)"
      choice = gets.chomp.downcase
      break if %(y n).include? choice
    end
    choice == 'y'
  end

  def reset
    grid.reset
    @current_player = player1
  end

  def display_welcome_message
    puts "Welcome to Connect 4!"
    puts <<~HEREDOC
      Connect 4 is a 2-player game consisting of a 6x7 grid where players take
      turns marking the lowest unoccupied square in a column. The first player
      to mark 4 squares in a row wins.
    HEREDOC
  end

  def choose_player2
    choice = nil
    loop do
      puts "Play against another (h)uman or a (c)omputer?"
      choice = gets.chomp.downcase
      break if %w(h c).include? choice
    end
    @player2 = (choice == 'h' ? Human : Computer).new(PLAYER2_MARKER)
  end

  def display_grid
    grid.display
    puts "#{@current_player}'s Turn"
  end

  def player_moves
    case @current_player
    when Human then human_player_moves(@current_player)
    when Computer then computer_player_moves(@current_player)
    end
  end

  def human_player_moves(player)
    available_cols = grid.available_cols
    col = nil
    loop do
      puts "Choose a column (#{join_or(available_cols)}):"
      col = gets.chomp.to_i
      break if available_cols.include? col
      puts "Sorry, must choose from available columns."
    end
    row = grid.next_row(col)
    grid[row, col].marker = player.marker
    change_player
  end

  def computer_player_moves(player)
    col = grid.available_cols.sample
    row = grid.next_row(col)
    grid[row, col].marker = player.marker
    change_player
  end

  def change_player
    @current_player = player1_turn? ? player2 : player1
  end

  def player1_turn?
    @current_player == player1
  end

  def display_result
    return puts "It's a draw" if grid.full?
    case grid.winning_marker
    when player1.marker
      puts "#{player1.name} won!"
    when player2.marker
      puts "#{player2.name} won!"
    end
  end

  def display_goodbye_message
    puts "Thank you for playing Connect 4! Goodbye!"
  end
end

game = Connect4.new
game.play
