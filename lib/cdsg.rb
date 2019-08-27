#!/usr/bin/env ruby

require 'json'

$app_root = File.expand_path('..', File.dirname(__FILE__))

class CDSG

 attr_accessor :results, :app_root, :config, :data, :region, :capitals_mode, :hard_mode

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

  def hint(answer, count = 1)
    case count
    when 1
      answer.chars.each_with_index.map { |c,i| (c =~ /([A-Z]|-|'|\s)/) ? c : '*' }.join
    when 2
      answer.chars.each_with_index.map { |c,i| ( [0,4,8,12,16].any?(i) || c =~ /([A-Z]|-|'|\s)/) ? c : '*' }.join
    when 3
      answer.chars.each_with_index.map { |c,i| (i.even? || c =~ /([A-Z]|-|'|\s)/) ? c : '*' }.join
    else
      "All hints used for this guess!"
    end
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
    puts "+ To stop the game manually, enter 'quit' or 'exit'"
    puts "+ To see your progress so far, enter 'progress'"
    puts "+ To get a hint of the answer, enter 'hint' - you can do this up to 3 times per answer"
    puts "+ To see this help text again, enter ''"
    puts ''
    puts "To skip to the next state, enter 'skip' or 'next'" if @capitals_mode
    puts '***************************************'
    puts ''
    true
  end

  def game_progress(str)
    return CDSG.help() if str =~ /\A(\?|help)\z/
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
    puts '********* HARD MODE *********' if @hard_mode
    if @capitals_mode && @config['game_modes'][@region]['capitals_mode'] == false
      puts ''
      puts "!!! Capitals Mode unavailable for region: #{@region} - playing normally !!!"
      @capitals_mode = false
    end
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
    hint_count = 0
    loop do
      puts ''
      guess = gets.chomp
      break if quit?(guess)
      next if game_progress(guess)
      if guess =~ /\A([hH]|[hH]int)\z/
        hint_count += 1
        puts "* Hints Used: #{hint_count.to_s}"
        puts ''
        puts hint(remaining_states.shuffle.first, hint_count)
      end
      result = correct_state?(guess)
      if result
        puts "* [CORRECT] --- #{result} *"
        @results << result
        hint_count = 0
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
    hint_count = 0
    @data.each_key.to_a.select { |d| @data[d]['capital'] != '#' }.shuffle.each do |k|
      begin
        puts ''
        puts "What is the capital of #{k}?"
        guess = gets.chomp
        break if quit?(guess)
        if guess =~ /\A([hH]|[hH]int)\z/
          hint_count += 1
          puts "* Hints Used: #{hint_count.to_s} *"
          puts ''
          puts hint(capital_answer(k), hint_count)
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
      hint_count = 0
    end
    game_outro
  end

end
