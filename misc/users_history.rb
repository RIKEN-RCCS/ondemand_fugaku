#!/usr/bin/ruby
# coding: utf-8
require "fileutils"

log_dir="/var/log/ondemand-nginx"
times = []
Dir.glob(log_dir + "/*") do |d|
  times.push(File.birthtime(d)) if FileTest.directory?(d)
end

# Extract the year and month of each Time object and
# calculate the number of objects per year and month
counts = times.sort.group_by { |t| [t.year, t.month] }.transform_values(&:count)

# Generate all year and month combinations
years = times.map(&:year).sort.uniq
months = (1..12).to_a
all_combinations = years.product(months)

# Count for all year and month combinations
num = 0
puts "Year-Month\tCount\tAcc. Count\n"
all_combinations.each do |year, month|
  num += count = counts[[year, month]] || 0
  puts "#{year}-#{month}\t#{count}\t#{num}"
end
