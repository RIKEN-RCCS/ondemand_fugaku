#!/usr/bin/ruby
# coding: utf-8
require "fileutils"
require "zlib"
require "csv"

###
Exclusive_appname = ["ood_job_submitter", "ood_job_submitter_supercon2023", "ood_openfoam", "ood_vscode_supercon2023", "ood_openfoam_fundation", "ood_desktop_meeting", "ood_jupyter_qc"]
###
#Fugaku = true
#PrePost = false
Fugaku = false
PrePost = true
###

APPNAME     = 0
CATEGORY    = 1
SUBCATEGORY = 2
PROGRESS_LINE_INTERVAL = 1_000_000
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
    return unless appname.start_with?("ood_")
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
    return unless appname.start_with?("ood_")
    return if(Exclusive_appname.include?(appname))
    prepost.push([year_month, appname])
  end
end

def output_statistics(section, kind, items, prepost)
  prepost_app = prepost.filter_map do |i|
    next unless items[i[1]]
    items[i[1]][kind]
  end
  counts = prepost_app.group_by{ |i| i }.transform_values(&:count)
  counts.sort_by { |i| i[1] }.reverse.each do |v|
    puts CSV.generate_line([section, nil, v[0], v[1]])
  end
end

def print_progress(file, file_index, total_files, line_count, matched_count)
  percentage = total_files > 0 ? format("%.1f", file_index.to_f * 100 / total_files) : "0.0"
  STDERR.puts "file=#{file_index}/#{total_files} (#{percentage}%) lines=#{line_count} matched=#{matched_count} current=#{file}"
end

exit if Fugaku == false && PrePost == false
prepost = Array.new
line_count = 0
files = Dir.glob(log_files)
total_files = files.size
files.each_with_index do |file, idx|
  if FileTest.file?(file)
    if file.end_with?("gz")
      Zlib::GzipReader.open(file) do |f|
        f.each_line do |line|
          line_count += 1
          fugaku_grep(prepost, line)
          prepost_grep(prepost, line)
          print_progress(file, idx + 1, total_files, line_count, prepost.size) if (line_count % PROGRESS_LINE_INTERVAL).zero?
        end
      end
    else
      File.open(file) do |f|
        f.each_line do |line|
          line_count += 1
          fugaku_grep(prepost, line)
          prepost_grep(prepost, line)
          print_progress(file, idx + 1, total_files, line_count, prepost.size) if (line_count % PROGRESS_LINE_INTERVAL).zero?
        end
      end
    end
  end
end

print_progress("done", total_files, total_files, line_count, prepost.size) if total_files > 0

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
puts CSV.generate_line(["section", "month", "name", "count"])
counts.sort_by { |value, _count| [value[0][0], value[0][1], value[1]] }.each do |value, count|
  next unless items[value[1]]
  puts CSV.generate_line(["monthly", "#{value[0][0]}-#{value[0][1]}", items[value[1]][0], count])
end

output_statistics("appname_summary", APPNAME, items, prepost)
output_statistics("category_summary", CATEGORY, items, prepost)
output_statistics("subcategory_summary", SUBCATEGORY, items, prepost)
