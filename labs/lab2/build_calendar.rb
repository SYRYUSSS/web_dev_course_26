#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'date'

if ARGV.size != 4
  puts "Использование: ruby build_calendar.rb teams.txt ДД.ММ.ГГГГ ДД.ММ.ГГГГ calendar.txt"
  exit 1
end

teams_file = ARGV[0]
start_date_str = ARGV[1]
end_date_str = ARGV[2]
output_file = ARGV[3]

unless File.exist?(teams_file)
  puts "Ошибка: Файл '#{teams_file}' не найден!"
  exit 1
end

begin
  start_date = Date.parse(start_date_str)
  end_date = Date.parse(end_date_str)
rescue
  puts "Ошибка: Неправильный формат даты!"
  exit 1
end

teams = []
File.foreach(teams_file, encoding: 'UTF-8') do |line|
  line = line.strip
  next if line.empty?
  name = line.gsub(/^\d+\.\s*/, '')
  teams << name
end

puts "Найдено команд: #{teams.size}"

if teams.size < 2
  puts "Ошибка: Нужно хотя бы 2 команды!"
  exit 1
end

pairs = []
(0...teams.size).each do |i|
  (i+1...teams.size).each do |j|
    pairs << [teams[i], teams[j]]
  end
end

total_matches_needed = pairs.size * 2
puts "Всего пар: #{pairs.size}"
puts "Нужно матчей (с учетом ответных): #{total_matches_needed}"

time_slots = ["12:00", "15:00", "18:00"]
game_days = []

current = start_date
while current <= end_date
  game_days << current if [5, 6, 0].include?(current.wday)
  current = current.next_day
end

puts "Игровых дней: #{game_days.size}"
puts "Всего слотов (дни × время): #{game_days.size * 3}"

slots = []
game_days.each do |day|
  time_slots.each do |time|
    slots << { 
      date: day, 
      time: time,
      games_count: 0 
    }
  end
end

slots = slots.shuffle

matches = []

pairs.each do |team1, team2|
  slot = slots.find { |s| s[:games_count] < 2 }
  if slot
    matches << {
      date: slot[:date],
      time: slot[:time],
      team1: team1,
      team2: team2
    }
    slot[:games_count] += 1
    puts "Матч 1: #{slot[:date]} #{slot[:time]} | #{team1} vs #{team2} (в слоте теперь #{slot[:games_count]} игр)"
  else
    puts "Больше нет свободных слотов! Остановка."
    break
  end
  
  slot = slots.find { |s| s[:games_count] < 2 }
  if slot
    matches << {
      date: slot[:date],
      time: slot[:time],
      team1: team2,
      team2: team1
    }
    slot[:games_count] += 1
    puts "Матч 2: #{slot[:date]} #{slot[:time]} | #{team2} vs #{team1} (в слоте теперь #{slot[:games_count]} игр)"
  else
    puts "Больше нет свободных слотов! Остановка."
    break
  end
end

matches = matches.sort_by { |m| [m[:date], m[:time]] }

puts "\n" + "=" * 50
puts "СТАТИСТИКА СЛОТОВ:"
slots_with_games = slots.select { |s| s[:games_count] > 0 }
slots_with_games.each do |s|
  puts "  #{s[:date]} #{s[:time]}: #{s[:games_count]} игр"
end

puts "\n" + "=" * 50
puts "ВСЕГО МАТЧЕЙ: #{matches.size} из #{total_matches_needed}"

File.open(output_file, 'w:UTF-8') do |f|
  f.puts "СПОРТИВНЫЙ КАЛЕНДАРЬ"
  f.puts "=" * 60
  f.puts "Период: #{start_date.strftime('%d.%m.%Y')} - #{end_date.strftime('%d.%m.%Y')}"
  f.puts "Команд: #{teams.size}, Матчей: #{matches.size}"
  f.puts "=" * 60
  f.puts
  
  current_date = nil
  matches.each do |m|
    if current_date != m[:date]
      current_date = m[:date]
      f.puts "\n#{current_date.strftime('%d.%m.%Y')} (#{['вс','пн','вт','ср','чт','пт','сб'][current_date.wday]})"
    end
    f.puts "  #{m[:time]} | #{m[:team1]} vs #{m[:team2]}"
  end
  
  f.puts "\n" + "=" * 60
end

puts "Готово! Календарь в файле: #{output_file}"