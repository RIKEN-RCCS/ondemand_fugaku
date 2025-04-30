#!/usr/bin/ruby
# coding: utf-8
require "fileutils"
require "zlib"
require "csv"

###
Exclusive_appname = ["ood_job_submitter_supercon2023", "ood_openfoam", "ood_vscode_supercon2023", "ood_openfoam_fundation", "ood_desktop_meeting", "--bulk", "--data", "-L", "-L rscgrp=small", "gpu1", "BatchMode=yes"]
###
#Fugaku = true
#PrePost = false
Fugaku = false
PrePost = true
###

APPNAME     = 0
CATEGORY    = 1
SUBCATEGORY = 2
log_files = "/var/log/ondemand-nginx/*/error.log*"
csv_file  = "./applications.csv"

def fugaku_grep(prepost, line)
  return if Fugaku != true
  if line.include?("pjsub") && line.include?("execve")
    year_month = line.split("\[")[1].split[0].split("-")[0..1]
    return if line.split(",").size <= 3
    appname = line.split(",")[2][3..-3]
    appname = line.split(",")[6][3..-3] if appname.include?("@") # specified mail address
    appname = line.split(",")[7][3..-3] if appname.include?("-N")
    return if(Exclusive_appname.include?(appname) || appname.include?("\"ood_desktop"))
    appname = "ood_h_phi"   if appname == "ood_hphi"
    appname = "ood_kiertta" if appname.start_with?("ood_kiertaa")
    prepost.push([year_month, appname])
  end
end

def prepost_grep(prepost, line)
  return if PrePost != true
  if line.include?("sbatch") && line.include?("execve")
    year_month = line.split("\[")[1].split[0].split("-")[0..1]
    return if line.split(",").size <= 5
    appname = line.split(",")[5][3..-3]
    appname = line.split(",")[9][3..-3] if appname.include?("@") # specified mail address
    return if(Exclusive_appname.include?(appname))
    prepost.push([year_month, appname])
  end
end

def output_statistics(kind, items, prepost)
  prepost_app = prepost.map { |i| items[i[1]][kind] }
  counts = prepost_app.group_by{ |i| i }.transform_values(&:count)
  counts.sort_by { |i| i[1] }.reverse.each do |v|
    print v[0].to_s + "\t" + v[1].to_s + "\n"
  end
end

exit if Fugaku == false && PrePost == false
prepost = Array.new
Dir.glob(log_files) do |file|
  if FileTest.file?(file)
    if file.end_with?("gz")
      Zlib::GzipReader.open(file) do |f|
        f.each_line do |line|
          fugaku_grep(prepost, line)
          prepost_grep(prepost, line)
        end
      end
    else
      File.open(file) do |f|
        f.each_line do |line|
          fugaku_grep(prepost, line)
          prepost_grep(prepost, line)
        end
      end
    end
  end
end

# Read CSV file while deleting spaces before and after each item
items = Hash.new
CSV.foreach(csv_file) do |row|
  tmp = []
  row.map do |c|
    tmp.push(c.strip)
  end
  items.store(tmp[1], [tmp[0], tmp[2], tmp[3]])
end

counts = prepost.group_by{ |i| i }.transform_values(&:count)
counts.each do |value, count|
  begin
    puts "#{value[0][0]}-#{value[0][1]}\t#{items[value[1]][0]}\t#{count}"
  rescue => e
    puts value[1]
    puts e
    exit(1)
  end
end

puts "--"
output_statistics(APPNAME, items, prepost)
puts "--"
output_statistics(CATEGORY, items, prepost)
puts "--"
output_statistics(SUBCATEGORY, items, prepost)
puts "--"
