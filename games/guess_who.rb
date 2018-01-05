require 'yaml'

module Formattable
  def title_case(string)
    string.split.map(&:capitalize).join(' ')
  end

  def to_trait_sym(string)
    string.to_s.gsub(/\s+/, '_').downcase.to_sym
  end

  def to_trait_string(string)
    title_case(string.to_s.gsub(/_/, ' '))
  end

  def clear_screen
    system('clear') || system('cls')
  end

  def press_enter_to_continue
    puts "Press ENTER to continue..."
    gets
  end

  def plural_people(amount)
    amount == 1 ? " #{amount} person" : "#{amount} people"
  end
end

class Person
  attr_reader :traits, :name

  def initialize(traits)
    @name = traits[:name]
    @traits = traits
  end

  def to_s
    name
  end

  def display_traits
    traits.values.each { |value| print value.center(10) }
    puts
  end

  def [](trait)
    traits[trait]
  end

  def size
    traits.keys.size
  end

  def ==(other)
    name == other.name
  end
end

class List
  include Formattable

  attr_accessor :dosiers

  def initialize
    make_dosiers
  end

  def make_dosiers
    dosier_data = File.read "./guess_who_person_traits.yml"
    @dosiers = YAML::load dosier_data
    @dosiers.map! { |dosier| Person.new(dosier)}
  end

  def display(options = {})
    clear_screen if options[:clear]
    dosiers.first.traits.keys.each do |key|
      value = to_trait_string(key)
      value = title_case(value)
      print value.center(10)
    end
    puts
    puts '-' * 10 * self[0].traits.size
    dosiers.each { |person| person.display_traits }
    puts
  end

  def size
    dosiers.size
  end

  def [](idx)
    dosiers[idx]
  end

  def []=(idx, value)
    dosiers[idx] = value
  end

  def first
    self[0]
  end

  def delete(person)
    dosiers.delete(person)
  end
end

class Player
  include Formattable

  attr_reader :list, :secret_person

  def initialize(name)
    @list = List.new
    @name = name
    @secret_person = @list.dosiers.sample
  end

  def get_people(trait, desc, options)
    if options[:with] == true
      list.dosiers.select { |person| person[trait] == desc }
    else
      list.dosiers.select { |person| person[trait] != desc }
    end
  end

  def remove_people(trait, desc, options)
    get_people(trait, desc, options).each do |person|
      list.delete(person)
    end
  end

  def flip_down(trait, desc, other)
    puts "#{self} chose to check for #{to_trait_string(trait)}: #{desc}."
    if other.secret_person[trait] == desc
      puts "#{other}'s secret person matches that description!"
      self.remove_people(trait, desc, with: false)
    else
      puts "#{other}'s secret person does not match that description."
      self.remove_people(trait, desc, with: true)
    end
  end

  def status
    puts "#{self} has narrowed it down to #{plural_people(list.size)}"
  end

  def choose_secret
    list.display
    choice = nil
    puts
    loop do
      print "Choose your secret person (enter name): "
      choice = gets.chomp.capitalize
      break if list.dosiers.collect(&:name).include? choice
      puts "Sorry, that person is not on the list."
    end
    @secret_person = list.dosiers.select { |person| person[:name] == choice }.first
  end

  def all_options
    result = Hash.new([])
    list.dosiers.each do |dosier|
      dosier.traits.each do |trait, desc|
        result[trait] += [desc]
      end
    end
    result
  end

  def to_s
    @name.to_s
  end
end

class GuessWho
  include Formattable

  attr_reader :player1, :player2

  def initialize
    @player1 = Player.new("Alex")
    @player2 = Player.new("Jasmine")
  end

  def play
    clear_screen
    display_welcome_message
    player1.choose_secret
    loop do
      player1.list.display(clear: true)
      player1_ask
      press_enter_to_continue

      player1.list.display(clear: true)
      break if player_won?
      puts player1.status

      press_enter_to_continue
      player1.list.display(clear: true)
      player2_ask
      puts player2.status
      press_enter_to_continue
      break if player_won?
    end
    display_result
    display_goodbye_message
  end

  private

  def player1_ask
    trait = nil
    desc = nil
    loop do
      puts "Guess a trait of player 2's secret person:"
      print "Trait: "
      trait = gets.chomp.strip
      trait = to_trait_sym(trait)
      print "Description: "
      desc = gets.chomp.capitalize.strip
      break unless player1.get_people(trait, desc, with: true).empty?
      puts "Sorry, that is not a possible guess."
    end

    player1.flip_down(trait, desc, player2)
  end

  def player2_ask
    trait = player2.all_options.select { |k, v| v.uniq.size > 1 && k != :name }.keys.sample
    desc = player2.all_options[trait].sample

    player2.flip_down(trait, desc, player1)
  end

  def player_won?
    !!winner
  end

  def player2_won?
    return unless player2.list.size == 1
    player2.list.first == player1.secret_person
  end

  def winner
    if player1.list.size == 1 && player1.list.first == player2.secret_person
      return player1
    elsif player2.list.size == 1 && player2.list.first == player1.secret_person
      return player2
    end
    nil
  end

  def display_welcome_message
    puts "Welcome to Guess Who!"
  end

  def display_result
    puts "#{winner} won!"
    case winner
    when player1
      puts "#{player2}'s secret person was #{winner.list.first}."
    when player2
      puts "#{player1}'s secret person was #{winner.list.first}."
    end
  end

  def display_goodbye_message
    "Thank you for playing Guess Who! Goodbye!"
  end
end

game = GuessWho.new
game.play
