require 'rainbow/ext/string'

SUITS = %w[H D C S]
VALUES = %w[2 3 4 5 6 7 8 9 10 J Q K A]

HIGHEST_TOTAL = 21
DEALER_STAY_VALUE = 17

def prompt(msg)
  puts "=> #{msg}"
end

def valid_input?(input, first_letter_of_valid_answers)
  first_letter_of_valid_answers.include?(input.downcase)
end

def initialize_deck
  SUITS.product(VALUES).shuffle
end

def shuffle_deck!(current_deck)
  current_deck.shuffle!
end

def deal_card!(current_deck, hand)
  # remove card from deck and add to player's hand
  hand << current_deck.shift
  # return will be the card itself
end

def initialize_hands!(current_deck, player1_hand, player2_hand)
  2.times do |_|
    deal_card!(current_deck, player1_hand)
    deal_card!(current_deck, player2_hand)
  end
end

def total(hand)
  values = hand.map { |card| card[1] }
  sum = 0
  values.each do |value|
    sum += if %w[J Q K].include?(value)
             10
           elsif %w[1 2 3 4 5 6 7 8 9 10].include?(value)
             value.to_i
           else # if the card is an Ace
             11
           end
  end
  # correct for Aces
  values.select { |value| value == 'A' }.count.times do
    sum -= 10 if sum > HIGHEST_TOTAL
  end

  sum
end

def make_card(card, rows, show_card=true)
  suit = case card[0]
         when 'S' then "\u2660".color(:white)
         when 'H' then "\u2665".color(:red)
         when 'D' then "\u2666".color(:red)
         when 'C' then "\u2663".color(:white)
         end
  value = card[1]

  if !show_card
    suit = '?'
    value = '?'
  end
  rows_to_add = [
    "+---------+ ",
    "| #{value.ljust(3)} #{value.rjust(3)} | ",
    "| #{suit}     #{suit} | ",
    "|         | ",
    "|   #{value.center(3)}   | ",
    "|         | ",
    "| #{suit}     #{suit} | ",
    "| #{value.ljust(3)} #{value.rjust(3)} | ",
    "+---------+ "
  ]
  rows.each_with_index do |row, index|
    row << rows_to_add[index]
  end
  rows
end

def make_cards(hand, rows, show_card=true)
  hand.each { |card| rows = make_card(card, rows, show_card) }
end

def create_cards_display(player_rows, dealer_rows,
                         player_hand, dealer_hand, turn)
  puts "Your Cards: Total = #{total(player_hand).to_s.color(:green)}"
  puts player_rows
  puts "Dealer's Cards: Total = #{turn == 'player' ? '??' : total(dealer_hand).to_s.color(:green)}"
  puts dealer_rows
end

def display_cards(player_hand, dealer_hand, turn)
  system 'clear'
  player_rows = ['', '', '', '', '', '', '', '', '']
  dealer_rows = ['', '', '', '', '', '', '', '', '']

  if turn == 'player'
    # player_hand.each { |card| player_rows = make_card(card, player_rows) }
    make_cards(player_hand, player_rows)
    dealer_rows = make_card(dealer_hand[1],
                            make_card(dealer_hand[0],
                                      dealer_rows),
                            false)
  else # dealer's turn
    make_cards(player_hand, player_rows)
    make_cards(dealer_hand, dealer_rows)
  end
  create_cards_display(player_rows, dealer_rows, player_hand, dealer_hand, turn)
end

def busted?(hand)
  total(hand) > HIGHEST_TOTAL
end

def hit?(hand)
  total(hand) < DEALER_STAY_VALUE
end

def detect_winner(player1_hand, player2_hand)
  player_total = total(player1_hand)
  dealer_total = total(player2_hand)

  if player_total > HIGHEST_TOTAL
    :player_busted
  elsif dealer_total > HIGHEST_TOTAL
    :dealer_busted
  elsif dealer_total < player_total
    :player
  elsif dealer_total > player_total
    :dealer
  else
    :tie
  end
end

def display_winner(player1_hand, player2_hand)
  result = detect_winner(player1_hand, player2_hand)

  case result
  when :player_busted
    prompt "You busted! Dealer wins!"
  when :dealer_busted
    prompt "Dealer busted! You win!"
  when :player
    prompt "Congratulations! You win!"
  when :dealer
    prompt "You lose! The dealer out-played you!"
  when :tie
    prompt "It's a tie!"
  end
end

def play_again?
  answer = nil
  loop do
    prompt "Would you like to play again? (y or n)"
    answer = gets.chomp
    break if valid_input?(answer, %w[y n])
    prompt "That is not a valid choice."
  end
  answer.downcase.start_with?('y') ? true : false
end

def match_winner?(score)
  score.values.include?(5)
end

def update_score!(player_hand, dealer_hand, score)
  result = detect_winner(player_hand, dealer_hand)

  case result
  when :player_busted, :dealer
    score[:dealer] += 1
  when :dealer_busted, :player
    score[:player] += 1
  end
end

def display_score(score)
  prompt "Player: #{score[:player]} | Dealer: #{score[:dealer]}"
end


loop do # Match loop
  score = {:player => 0, :dealer => 0}
  loop do # Game loop
    system 'clear'
    prompt "Welcome to Twenty-One!"
    # Start game
    deck = initialize_deck

    # Deal cards
    player_hand = []
    dealer_hand = []
    initialize_hands!(deck, player_hand, dealer_hand)

    # Player turn
    turn = 'player'
    loop do
      display_cards(player_hand, dealer_hand, turn)
      player_turn = nil
      loop do # get 'hit' or 'stay' from player
        puts "Would you like to (h)it or (s)tay?"
        player_turn = gets.chomp.downcase
        break if valid_input?(player_turn, ['h', 's'])
        prompt "That is not a valid choice. Must enter 'h' or 's'."
      end

      if player_turn == 'h'
        prompt "You chose to hit!"
        sleep(1)
        deal_card!(deck, player_hand)
      end

      break if player_turn == 's' || busted?(player_hand)
    end

    if busted?(player_hand)
      display_cards(player_hand, dealer_hand, turn)
      display_winner(player_hand, dealer_hand)
      update_score!(player_hand, dealer_hand, score)
      display_score(score)

      prompt "Press ENTER to continue..."
      gets
      # if yes, go back to the top to start the game over
      # if no, break the loop to exit the game
#      play_again? ? next : break
      match_winner?(score) ? break : next
    else
      prompt "You chose to stay at #{total(player_hand).to_s.color(:green)}!"
      sleep(1)
    end

    # Dealer turn
    turn = 'dealer'
    loop do
      display_cards(player_hand, dealer_hand, turn)
      break if busted?(dealer_hand) || !hit?(dealer_hand)

      prompt "The dealer chose to hit!"
      sleep(1)
      deal_card!(deck, dealer_hand)
    end

    # if dealer does not draw another card
    if !busted?(dealer_hand)
      prompt "The dealer chose to stay at #{total(dealer_hand).to_s.color(:green)}."
    end

    update_score!(player_hand, dealer_hand, score)
    display_winner(player_hand, dealer_hand)
    display_score(score)
    prompt "Press ENTER to continue..."
    gets
#    break unless play_again?
    match_winner?(score) ? break : next
  end

  prompt "-----------------------"
  prompt "The match is over!"
  if score.key(5) == :player
          prompt "You won!"
         else
           prompt "The dealer won!"
         end
  break unless play_again?
end
prompt "Thanks for playing Twenty-One! Good bye!"
