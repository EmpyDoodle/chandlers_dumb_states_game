#!/usr/bin/env ruby

require 'json'

$app_root = File.expand_path('..', File.dirname(__FILE__))

class CDSG

 attr_accessor :results

  def initialize(region, capitals = false, hard = false)
    @app_root = $app_root
    @config = JSON.parse(File.read(File.join(@app_root, 'var', 'config.json')))
    @data = JSON.parse(File.read(File.join(@app_root, 'var', region + '.json')))
    @region = region
    @capitals_mode = capitals
    @hard_mode = hard
    @data.delete_if { |k,v| v['independent'] == false } unless @hard_mode
  end

  def self.regions()
    @config = @config || JSON.parse(File.read(File.join($app_root, 'var', 'config.json')))
    @config['game_modes'].each_key.to_a
  end

  def match_guess(guess, answer)
    ## Needs improving to allow imperfect spelling!
    guess.downcase.gsub(/(\.|\')/, '').gsub('-', ' ').gsub(/\A[sS][tT]/, 'Saint') == answer.downcase.gsub(/(\.|\')/, '').gsub('-', ' ') ? answer : false
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

  def capital_answer(state)
    @data[state]['capital']
  end

  def correct_capital?(guess, state)
    match_guess(guess, @data[state]['capital'])
  end

  def hint(answer)
    answer.chars.each_with_index.map { |c,i| (i == 0 || i == ' ') ? c : '-' }.join
  end

  def quit?(str)
    str =~ /\A([qQ]|quit|exit)\z/ ? true : false
  end

  def self.help()
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
    return CDSG.help() if str =~ /\A([hH]|help)\z/
    if str =~ /\A(progress|results|answers)\z/
      puts ''
      puts ('------------ RESULTS ------------')
      puts "You achieved *** #{@results.length} / #{@data.length} ***"
      puts ''
      if @capitals_mode
        @results.sort_by { |k, v| k }.each { |k,v| puts "+ #{v} is the capital of #{k}" }
      else
        @results.sort.each { |r| puts "+ #{r.to_s.chomp}"}
      end
      puts ('---------------------------------')
      true
    else
      false
    end
  end

  def game_intro()
    puts "*** Beginning Chandler's Dumb States Game ***"
    puts "***** Region: #{@region.upcase} *****"
    puts "********* HARD MODE *********" if @hard_mode
  end

  def game_outro(completed = false)
    puts ''
    puts '************* Game Finished *************'
    puts "Thank you for playing Chandler's dumb states game"
    puts '*****************************************'
    game_progress('results')
    if @capitals_mode
      @data.select { |k,v| !@results.keys.to_a.include?(k) }.each { |k,v| puts "- #{v['capital']} is the capital of #{k}"}
    else
      @data.each_key.to_a.select { |c| !@results.include?(c) }.each { |c| puts "- #{c.to_s.chomp}"}
    end
    puts ("!!! Say hello to the new champ of Chandler's Dumb States Game !!!") if completed
    puts ('---------------------------------')
    puts ('Please hit Enter to exit')
    gets.chomp
  end

  def remaining_states()
    @data.dup.delete_if { |k,v| @results.include?(k) }.each_key.to_a
  end

  def play()
    game_intro
    return play_capitals if @capitals_mode
    @results = Array.new
    completed = false
    loop do
      puts ''
      guess = gets.chomp
      break if quit?(guess)
      next if game_progress(guess)
      puts hint(remaining_states.shuffle.first) if guess =~ /[hH]int/
      result = correct_state?(guess)
      if result
        puts "* [CORRECT] --- #{result} *"
        @results << result
      else
        puts '* [INCORRECT] *'
      end
      completed = true if @results.size == @data.size
      break if completed
    end
    completed == true ? game_outro(true) : game_outro()
  end

  def play_capitals()
    puts '***** Playing in Capitals Mode *****'
    @results = Hash.new
    @data.each_key.to_a.select { |d| @data[d]['capital'] != '#' }.shuffle.each do |k|
      begin
        puts ''
        puts "What is the capital of #{k}?"
        guess = gets.chomp
        break if quit?(guess)
        if guess =~ /[hH]int/
          puts hint(capital_answer(k))
          raise ''
        end
        raise '' if game_progress(guess)
      rescue
        retry
      end
      result = correct_capital?(guess, k)
      if result
        puts "* [CORRECT] --- #{result} *"
        @results[k] = result
      else
        puts "* [INCORRECT] --- The answer is #{@data[k]['capital']} *"
      end
    end
    game_outro
  end

end
