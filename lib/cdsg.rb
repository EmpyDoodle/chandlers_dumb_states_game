#!/usr/bin/env ruby

require 'json'

$app_root = File.expand_path('..', File.dirname(__FILE__))

class CDSG

  def initialize(region, capitals = false)
    @app_root = $app_root
    @data = JSON.parse(File.read(File.join(@app_root, 'var', region + '.json')))
    @results = Array.new
    @region = region
    @capitals_mode = capitals
  end

  def self.regions()
    Dir.entries(File.join($app_root, 'var')).delete_if { |e| e =~ /\A\.{1,2}\z/ }.map { |f| f.split('.').first }
  end

  def match_guess(guess, answer)
    guess.downcase == answer.downcase ? answer : false
    #return answer if guess.downcase == answer.downcase
    #rexpr = guess.chars.map { |c| "(#{c}?)"}
    #(guess.chars.map { |c| answer.downcase.include?(c.downcase) }.count(true)) >= answer.length / 2 ? answer : false
  end

  def correct_state?(guess)
    @data.select { |k,v| !@results.include?(k) }.each do |k,v|
      return k if match_guess(guess, k)
      v['aliases'].each { |s| return k if match_guess(guess, s) }
      if guess.length == 2
        return k if match_guess(guess.upcase, v['abbreviation'])
      end
    end
    false
  end

  def correct_capital?(guess, state)
    match_guess(guess, @data[state]['capital'])
  end

  def quit?(str)
    str =~ /\A([qQ]|quit|exit)\z/ ? true : false
  end

  def help()
    puts ''
    puts '************* How to Play *************'
    puts 'Type one answer into the terminal and hit Enter'
    puts 'You will be told whether it is correct or not'
    puts 'When you reach the max answers, the game will stop'
    puts ''
    puts "To stop the game manually, enter 'quit' or 'exit'"
    puts "To see your progress so far, enter 'progress'"
    puts "To skip to the next state, enter 'skip' or 'next'" if @capitals_mode
    puts '***************************************'
    puts ''
    true
  end

  def game_progress(str)
    return help() if str =~ /\A([hH]|help)\z/
    if str =~ /\A(progress|results|answers)\z/
      puts ''
      puts ('------------ RESULTS ------------')
      puts "You achieved *** #{@results.length} / #{@data.length} ***"
      puts ''
      @res\ults.sort.each { |r| puts "+ #{r.to_s.chomp}"}
      puts ''
      puts ('---------------------------------')
      true
    else
      false
    end
  end

  def game_intro()
    puts "*** Beginning Chandler's Dumb States Game ***"
    puts "***** Region: #{@region.upcase} *****"
  end

  def game_outro()
    puts ''
    puts '************* Game Finished *************'
    puts "Thank you for play Chandler's dumb states game"
    puts '*****************************************'
    game_progress('results')
    @data.each_key.to_a.select { |c| !@results.include?(c) }.each { |c| puts "- #{c.to_s.chomp}"}
    puts ('---------------------------------')
  end

  def play()
    game_intro
    return play_capitals if @capitals_mode
    loop do
      guess = gets.chomp
      break if quit?(guess)
      next if game_progress(guess)
      result = correct_state?(guess)
      if result
        puts "* [CORRECT] --- #{result} *"
        @results << result
      else
        puts '* [INCORRECT] *'
      end
      puts ''
      break if @results.size == @data.size
    end
    game_outro
  end

  def play_capitals()
    puts '***** Playing in Capitals Mode *****'
    @data.each_key.to_a.shuffle.each do |k|
     puts ''
      puts "What is the capital of #{k}?"
      guess = gets.chomp
      break if quit?(guess)
      game_progress(guess)
      result = correct_capital?(guess, k)
      if result
        puts "* [CORRECT] --- #{result} *"
        @results << { k => result }
      else
        puts '* [INCORRECT] *'
      end
    end
    game_outro
  end

end
