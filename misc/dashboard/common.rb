# coding: utf-8
require 'fileutils'
require 'date'
require 'csv'
require 'time'

SYS_OOD_DIR   = "/system/ood/"
ACC_DIR       = SYS_OOD_DIR + "accounting/"
ACC_GROUP_DIR = ACC_DIR + "group/"
ACC_HOME_DIR  = ACC_DIR + "home/"
Budget_info   = Struct.new(:limit, :usage, :avail, :ratio)
Disk_info     = Struct.new(:volume, :limit, :usage, :avail, :ratio)

def get_disk_limit(kind, group_name, volume)
  if kind == "capacity"
    file = ACC_GROUP_DIR + group_name + "/disk.csv"
  else
    file = ACC_GROUP_DIR + group_name + "/inode.csv"
  end
  return -1 unless File.exist?(file)

  File.open(file, "r") do |f|
    f.each_line do |l|
      i = l.split(",")
      return i[3] if i[0] == "GROUP" and i[1] == group_name and i[2] == volume
    end
  end

  return -1
end

def get_fugaku_pt(group, w_commas = true)
  file = ACC_GROUP_DIR + group + "/group_budget.csv"
  if File.exist?(file)
    CSV.foreach(file) do |row|
      if row[0] == "RESOURCE_GROUP" and row[1] == "f-pt"
	return (w_commas)? num_with_commas(row[2].to_i/3600) : row[2].to_i/3600
      end
    end
  end

  return -1 # for debug
end

def dashboard_exist_user_info()
  file = ACC_HOME_DIR + ENV['USER'] + ".disk"
  return File.exist?(file)
end

def dashboard_info(file)
  info = []
  File.open(file, "r") do |f|
    f.each_line do |l|
      info.push(l)
    end
  end

  return info
end

def num_with_commas(number)
  return number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
end

def dashboard_budget(group_name)
  file = ACC_GROUP_DIR + group_name + "/group_budget.csv"
  return nil unless File.exist?(file)

  period = Date.today.month.between?(4, 9)? "1" : "2"
  File.open(file, "r") do |f|
    # Budgets in Fugaku are divided into early and late periods.
    # The order is reversed to give priority to the later period.
    f.readlines.reverse_each do |l|
      i = l.split(",")
      if ((i[0] == "SUBTHEMEPERIOD" and i[2] == period) or i[0] == "SUBTHEME") and i[3].to_i != 0
        limit = i[3].to_i/3600
        usage = i[4].to_i/3600
        avail = i[6].to_i/3600
        ratio = ((usage * 100) / limit).round
        return Budget_info.new(num_with_commas(limit), num_with_commas(usage), num_with_commas(avail), ratio)
      end
    end
  end

  return nil
end

def get_budget_limit(group_name)
  tmp = dashboard_budget(group_name)
  return tmp != nil ? tmp[0].gsub(",", "") : nil
end

def _disk_info(file, group_name)
  return [] unless File.exist?(file)
  
  info = []
  File.open(file, "r") do |f|
    f.each_line do |l|
      i = l.split(",")
      if i[0] == "GROUP" and i[1] == group_name and i[2] != "vol0001"
        volume = "/" + i[2]
        limit  = i[3].to_i
        usage  = i[4].to_i
        avail  = i[5].to_i
        ratio  = ((usage * 100) / limit).round
        info.push(Disk_info.new(volume, num_with_commas(limit), num_with_commas(usage), num_with_commas(avail), ratio))
      end
    end
  end

  return info
end

def dashboard_disk(group_name)
  file = ACC_GROUP_DIR + group_name + "/disk.csv"
  return _disk_info(file, group_name)
end

def dashboard_inode(group_name)
  file = ACC_GROUP_DIR + group_name + "/inode.csv"
  return _disk_info(file, group_name)
end

def _home_info(file)
  File.open(file, "r") do |f|
    f.each_line do |l|
      i = l.split(",")
      volume = "/" + i[2]
      limit  = i[3].to_i
      usage  = i[4].to_i
      avail  = i[5].to_i
      ratio  = ((usage * 100) / limit).round
      return Disk_info.new(volume, num_with_commas(limit), num_with_commas(usage), num_with_commas(avail), ratio)
    end
  end

  return nil
end

def dashboard_home_disk()
  file = ACC_HOME_DIR + ENV['USER'] + ".disk"
  return _home_info(file)
end

def dashboard_home_inode()
  file = ACC_HOME_DIR + ENV['USER'] + ".inode"
  return _home_info(file)
end

def dashboard_color(num)
  if 0 <= num and num <= 25
    return "green"
  elsif 25 < num and num <= 75
    return "blue"
  else
    return "red"
  end
end

def dashboard_date()
  file = ACC_DIR + "date.txt"
  File.open(file, 'r') do |f|
    first_line = f.gets
    return first_line
  end
end

def ratio(a, b, limit = nil)
  if a.to_i > b.to_i 
    return 100
  else
    if limit != nil
      v = (a.to_f * 100/ b.to_f)
      return (v < limit)? v.truncate(2) : limit
    else
      return (a.to_f * 100/ b.to_f).truncate(2)
    end
  end
end
