#!/usr/bin/env ruby
# coding: utf-8
require 'zlib'

# 引数は必ず1つ必要
if ARGV.length != 1
  puts "Usage: #{File.basename($0)} <account_name>"
  puts "Please provide the account name as an argument."
  exit 1
end

# 引数からアカウント名を取得
account = ARGV[0]
directory_path = "/var/log/ondemand-nginx/#{account}"

# ディレクトリの存在確認
unless Dir.exist?(directory_path)
  puts "Error: Directory '#{directory_path}' does not exist."
  exit 1
end

unknown_lines = []
# ディレクトリ内のファイルを正規表現でフィルタリング
Dir.entries(directory_path).select do |file_name|
  next if !file_name.start_with?('error')

  file_path = File.join(directory_path, file_name)
  if file_path.end_with?('.gz')
    Zlib::GzipReader.open(file_path) do |gz|
      gz.each_line do |line|
        if line.include?("pjsub") && line.include?("-N")
          columns = line.split(/[ ,]+/)  # スペースとカンマで分割
          if columns.length >= 13
            app_name = columns[12].gsub(/\\"/, '')  # ダブルクォーテーションを削除
            date     = columns[3].gsub(/\[/, '')
            if app_name.start_with?("ood_")
              puts "#{date} #{app_name}"
            else
              unknown_lines << "#{date} #{app_name} #{line}"
            end
          end
        end
      end
    end
  else
    File.open(file_path, 'r') do |file|
      file.each_line do |line|
        if line.include?("pjsub") && line.include?("-N")
          columns = line.split(/[ ,]+/)  # スペースとカンマで分割
          if columns.length >= 13
	    app_name = columns[12].gsub(/\\"/, '')  # ダブルクォーテーションを削除
            date     = columns[3].gsub(/\[/, '')
            if app_name.start_with?("ood_")
      	      puts "#{date} #{app_name}"
            else
              unknown_lines << "#{date} #{app_name} #{line}"
            end
          end
      	end
      end
    end
  end
end

puts "---"
puts "The number of unknow lines is " + unknown_lines.length.to_s
puts unknown_lines
