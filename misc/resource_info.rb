# coding: utf-8
require "csv"

# ユーザごとのリソースの累計を格納するハッシュ
totals = Hash.new(0)

# 入力ファイルを解析して、ユーザ毎のリソースの使用量の総計を求める
CSV.new($stdin, headers: true).each do |row|
  user = row['USER']
  rsc  = row['ACCT_RSC'].to_i
  totals[user] += rsc
end

# CSV形式で出力
totals.each do |user, rsc|
  puts "#{user},#{rsc}"
end
