require 'rainbow/ext/string'

WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] + # rows
                [[1, 4, 7], [2, 5, 8], [3, 6, 9]] + # columns
                [[1, 5, 9], [3, 5, 7]]              # diagonals
INITIAL_MARKER = ' '
PLAYER_MARKER = 'X'
COMPUTER_MARKER = 'O'
FIRST_MOVE = 'choose' # select "player", "computer", or "choose"

def prompt(msg)
  puts "=> #{msg}"
end

def joinor(arr, delimiter=', ', conjuction='or')
  # joined_arr = []
  # arr.each do |num|
  #   joined_arr << num
  # end
  case arr.size
  when 0 then ''
  when 1 then arr.first
  when 2 then arr.join(' or ')
  else
    # This will mutate arr but in this program the arr will always be calculated
    # again before being passed into this method
    arr[-1] = "#{conjuction} #{arr[-1]}"
    arr.join(delimiter)
  end
end

# rubocop:disable Metrics/AbcSize
def display_board(brd)
  system 'clear'
  brd_help = brd.map do |k, v|
    if v == ' '
      [k, "-#{k}-".color(:red)]
    else
      [k, v]
    end
  end
  brd_help = brd_help.to_h
  puts "You're a #{PLAYER_MARKER}. Computer is #{COMPUTER_MARKER}."
  puts ""
  puts "     |     |"
  puts " #{brd_help[7].to_s.center(3)} | #{brd_help[8].to_s.center(3)} | #{brd_help[9].to_s.center(3)}"
  puts "     |     |"
  puts "-----+-----+-----"
  puts "     |     |"
  puts " #{brd_help[4].to_s.center(3)} | #{brd_help[5].to_s.center(3)} | #{brd_help[6].to_s.center(3)}"
  puts "     |     |"
  puts "-----+-----+-----"
  puts "     |     |"
  puts " #{brd_help[1].to_s.center(3)} | #{brd_help[2].to_s.center(3)} | #{brd_help[3].to_s.center(3)}"
  puts "     |     |"
  puts ""
end
# rubocop:enable Metrics/AbcSize

def initialize_board
  new_board = {}
  (1..9).each { |num| new_board[num] = INITIAL_MARKER }
  new_board
end

def empty_squares(brd)
  brd.keys.select { |num| brd[num] == INITIAL_MARKER }
end

def middle_square_available?(brd)
  empty_squares(brd).include?(5)
end

def find_at_risk_square(brd, marker)
  at_risk_lines = WINNING_LINES.select do |line|
    brd.values_at(*line).count(marker) == 2 &&
      brd.values_at(*line).count(INITIAL_MARKER) == 1
  end

  at_risk_squares = empty_squares(brd).select do |square|
    at_risk_lines.flatten.include?(square)
  end

  at_risk_squares.sample
end

def player_places_piece!(brd)
  square = ''
  loop do
    prompt "Choose a square (#{joinor(empty_squares(brd), ', ', 'or')}):"
    square = gets.chomp.to_i
    break if empty_squares(brd).include?(square)
    prompt "Sorry, that's not a valid choice."
  end
  brd[square] = PLAYER_MARKER # player is the X
end

def computer_places_piece!(brd)
  square = if find_at_risk_square(brd, COMPUTER_MARKER)
             find_at_risk_square(brd, COMPUTER_MARKER)
           elsif find_at_risk_square(brd, PLAYER_MARKER)
             find_at_risk_square(brd, PLAYER_MARKER)
           elsif middle_square_available?(brd)
             5
           else
             empty_squares(brd).sample
           end

  brd[square] = COMPUTER_MARKER
end

def board_full?(brd)
  empty_squares(brd).empty?
end

def someone_won?(brd)
  !!detect_winner(brd)
end

def detect_winner(brd)
  WINNING_LINES.each do |line|
    if brd.values_at(*line).count(PLAYER_MARKER) == 3
      return 'Player'
    elsif brd.values_at(*line).count(COMPUTER_MARKER) == 3
      return 'Computer'
    end
  end
  nil
end

def increment_win_count(brd, win_hsh)
  win_hsh[detect_winner(brd)] += 1
end

def display_scores(scores_hsh)
  scores_hsh.map { |k, v| "#{k}: #{v}" }.join(' | ')
end

def place_piece!(player, brd)
  case player
  when 'player'
    player_places_piece!(brd)
  when 'computer' then computer_places_piece!(brd)
  when 'choose' then prompt_play_order
  end
end

def play_order(first_player)
  case first_player
  when 'player'   then ['player', 'computer']
  when 'computer' then ['computer', 'player']
  when 'choose'
    loop do
      prompt "Who goes first? Choose '(P)layer' or '(C)omputer':"
      choice = gets.chomp
      case choice.downcase[0]
      when 'p' then break ['player', 'computer']
      when 'c' then break ['computer', 'player']
      else prompt "That is not a valid choice."
      end
    end
  end
end

def alternate_player(current_player, player1, player2)
  if current_player == player1
    player2
  else
    player1
  end
end

prompt "Welcome to Tic Tac Toe!"
loop do # play again loop
  player1, player2 = play_order(FIRST_MOVE)
  prompt "First to win 5 games wins the match."
  wins_count = { 'Player' => 0, 'Computer' => 0 }
  game_count = 1
  loop do # match loop
    board = initialize_board
    current_player = player1

    loop do # game loop
      display_board(board)
      prompt "The score is --> #{display_scores(wins_count)}"

      place_piece!(current_player, board)
      current_player = alternate_player(current_player, player1, player2)
      break if someone_won?(board) || board_full?(board)
    end

    display_board(board)

    if someone_won?(board)
      increment_win_count(board, wins_count)
      prompt "#{detect_winner(board)} won the game!"
    else
      prompt "It's a tie!"
    end

    game_count += 1
    break if wins_count.values.include?(5)
    prompt "Ready to play game \##{game_count}? Press ENTER to continue..."
    gets
  end

  prompt "#{wins_count.key(5)} won the match!"

  prompt "Play again? (y or n)"
  answer = gets.chomp
  break unless answer.downcase.start_with?('y')
end

prompt "Thanks for playing Tic Tac Toe! Good bye!"
