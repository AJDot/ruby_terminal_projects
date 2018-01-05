require 'rainbow/ext/string'

class Card
  SUITS = %w(C H S D).freeze
  FACES = %w(2 3 4 5 6 7 8 9 10 J Q K A).freeze

  def initialize(suit, face)
    @suit = suit
    @face = face
  end

  def suit
    case @suit
    when 'H' then 'Hearts'
    when 'D' then 'Diamonds'
    when 'S' then 'Spades'
    when 'C' then 'Clubs'
    end
  end

  def face
    case @face
    when 'J' then 'Jack'
    when 'Q' then 'Queen'
    when 'K' then 'King'
    when 'A' then 'Ace'
    else @face
    end
  end

  def ace?
    face == 'Ace'
  end

  def king?
    face == 'King'
  end

  def queen?
    face == 'Queen'
  end

  def jack?
    face == 'Jack'
  end

  # rubocop:disable MethodLength
  def pic_array(hide: false)
    suit_icon, face_icon = suit_and_face_icons
    suit_icon = '?' if hide
    face_icon = '?' if hide

    ['+---------+ ',
     "| #{face_icon.ljust(3)} #{face_icon.rjust(3)} | ",
     "| #{suit_icon}     #{suit_icon} | ",
     '|         | ',
     "|   #{face_icon.center(3)}   | ",
     '|         | ',
     "| #{suit_icon}     #{suit_icon} | ",
     "| #{face_icon.ljust(3)} #{face_icon.rjust(3)} | ",
     '+---------+ ']
  end
  # rubocop:enable MethodLength

  def suit_and_face_icons
    suit_icon = case @suit
                when 'S' then "\u2660".color(:white)
                when 'H' then "\u2665".color(:red)
                when 'D' then "\u2666".color(:red)
                when 'C' then "\u2663".color(:white)
                end
    face_icon = @face
    [suit_icon, face_icon]
  end
end

class Deck
  attr_accessor :cards

  def initialize
    reset
  end

  def reset
    self.cards = setup_cards
    shuffle_cards
  end

  def setup_cards
    suits = Card::SUITS
    faces = Card::FACES
    suits.product(faces).map { |suit, face| Card.new(suit, face) }
  end

  def deal_card
    cards.shift
  end

  def shuffle_cards
    cards.shuffle!
  end
end

module Hand
  def add_card(new_card)
    cards << new_card
  end

  def display_hand
    puts "----- #{name}'s Hand -----"
    display_cards
    puts ''
    puts "=> Total: #{total}"
    puts ''
  end

  def display_cards(hide: false)
    pic_arrays = if hide
                   [cards.first.pic_array, cards.last.pic_array(hide: true)]
                 else
                   cards.map(&:pic_array)
                 end
    puts pic_arrays.transpose.map(&:join)
  end

  def total
    total = 0
    cards.each do |card|
      total += card_value(card)
    end

    cards.select(&:ace?).count.times do
      break if total <= 21
      total -= 10
    end

    total
  end

  def card_value(card)
    if card.ace? then 11
    elsif card.king? || card.queen? || card.jack? then 10
    else card.face.to_i
    end
  end

  def busted?
    total > 21
  end
end

class Participant
  include Hand

  attr_accessor :cards, :name

  def initialize
    @cards = []
    set_name
    @stop = false
  end

  def hit(new_card)
    @stop = false
    add_card(new_card)
  end

  def stay
    @stop = true
  end

  def stay?
    @stop == true
  end

  def reset
    self.cards = []
  end
end

class Player < Participant
  def set_name
    name = ''
    loop do
      puts "What's your name?"
      name = gets.chomp.strip
      break unless name.empty?
      puts 'Sorry, must enter a value.'
    end
    self.name = name
  end

  def display_flop
    display_hand
  end
end

class Dealer < Participant
  def set_name
    self.name = %w(EVE Number\ 5 Hal R2D2 Chappie).sample
  end

  def display_flop
    puts "----- #{name}'s Hand -----"
    puts display_cards(hide: true)
    puts ''
  end
end

module Helpers
  def clear_screen
    system('clear') || system('cls')
  end

  def press_enter_to_continue
    puts '(Press ENTER to continue)'
    gets
  end
end

class TwentyOne
  include Helpers

  attr_accessor :deck, :player, :dealer

  def initialize
    @deck = Deck.new
    @player = Player.new
    @dealer = Dealer.new
  end

  def start
    display_welcome_message
    press_enter_to_continue
    play_round
    display_goodbye_message
  end

  def play_round
    loop do
      clear_and_deal_cards
      display_cards({turn: 'player', clear: true})
      player_turn
      dealer_turn unless player.busted?
      display_result
      play_again? ? reset : break
    end
  end

  def deal_cards
    2.times do
      player.add_card(deck.deal_card)
      dealer.add_card(deck.deal_card)
    end
  end

  def clear_and_deal_cards
    clear_screen
    deal_cards
  end

  def player_turn
    loop do
      make_player_decision
      break if player.busted? || player.stay?
    end
  end

  def make_player_decision
    name = player.name
    if hit_or_stay == 'h'
      player.hit(deck.deal_card)
      puts "#{name} hits!"
    else
      player.stay
      puts "#{name} stays!"
    end
    display_cards({turn: 'player', clear: true})
  end

  def dealer_turn
    display_cards({turn: 'dealer', clear: true})
    press_enter_to_continue
    loop do
      make_dealer_decision
      break if dealer.busted? || dealer.stay?
    end
  end

  def hit_or_stay
    choice = nil
    loop do
      puts '(H)it or (S)tay?'
      choice = gets.chomp.downcase
      break if %w(h s).include? choice
      puts "Sorry, must enter 'H' or 'S'."
    end
    choice
  end

  def make_dealer_decision
    name = dealer.name
    if dealer.total < 17
      dealer.hit(deck.deal_card)
      display_cards({turn: 'dealer', clear: true})
      puts "#{name} hits!"
      press_enter_to_continue
    else
      puts "#{name} stays!"
      dealer.stay
    end
  end

  def display_cards(options = {})
    clear_screen if options[:clear]
    if options[:turn] == 'player'
      player.display_flop
      dealer.display_flop
    else
      player.display_hand
      dealer.display_hand
    end
  end

  def display_result
    display_cards({turn: 'dealer', clear: true})
    puts result_output
  end

  def display_welcome_message
    clear_screen
    puts 'Welcome to Twenty-One!'
  end

  def display_goodbye_message
    puts 'Thanks for playing Twenty-One! Goodbye!'
  end

  def result_output
    case
    when player.busted? then "#{player.name} busted! #{dealer.name} won!"
    when dealer.busted? then "#{dealer.name} busted! #{player.name} won!"
    else winner ? "#{winner} won!" : "It's a tie!"
    end
  end

  def winner
    case player.total <=> dealer.total
    when -1 then dealer.name
    when 0 then nil
    when 1 then player.name
    end
  end

  def reset
    deck.reset
    player.reset
    dealer.reset
  end

  def play_again?
    answer = nil
    loop do
      puts 'Would you like to play again? (y/n)'
      answer = gets.chomp.downcase
      break if %w(y n).include? answer
      puts "Sorry, must choose 'y' or 'n'."
    end
    answer == 'y'
  end
end

game = TwentyOne.new
game.start
