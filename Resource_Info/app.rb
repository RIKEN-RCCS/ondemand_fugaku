# coding: utf-8
require "/var/www/ood/apps/sys/ondemand_fugaku/misc/utils.rb"

set :erb, :escape_html => true

helpers do
  def dashboard_title
    "Open OnDemand"
  end

  def dashboard_url
    "/pun/sys/dashboard/"
  end

  def title
    "Resource info"
  end

  def rate(a, b)
    if b.to_i == 0 then
      return 0
    else
      return (a.to_f * 100/ b.to_f).truncate(2)
    end
  end

  def color(num)
    if 0 <= num and num <= 25 then
      return "green"
    elsif 25 < num and num <= 75 then
      return "blue"
    else
      return "red"
    end
  end

  def get_update_time()
    return File.read(ACC_DIR + "date.txt")
  end
end

# Define a route at the root '/' of the app.
get '/' do
  @resource_info = []
  @groups = `groups`.split.reject { |e| e.start_with?("isv") } - ["fugaku"]
  year  = Time.now.year.to_s
  month = Time.now.month
  current_period = Time.now.month.between?(4, 9)
  filename = current_period ? year + "-1.csv" : year + "-2.csv"

  unused_groups = []
  @groups.each do |g|
    file = ACC_GROUP_DIR + g + "/" + filename
    if File.exist?(file) then
      tmp = []
      CSV.foreach(file) do |row|
        user  = row[0]
        limit = get_resource_limit(g)
        usage = row[1].to_i / 3600 # NH
        tmp.push([user, limit, usage])
      end

      # Add Exclusive use
      file = ACC_GROUP_DIR + g + "/resource.csv"
      if File.exist?(file) then
        sum = 0
        CSV.foreach(file) do |row|
          next if row[0] != "EXCLUSIVEUSE"
          date = Date.parse(row[3]) # End date of a job
          sum += row[5].to_i if date.month.between?(4, 9) == current_period
        end
        if sum != 0 then
          user  = "(Exclusive Use)"
          limit = get_resource_limit(g)
          usage = sum / 3600 # NH
          tmp.push([user, limit, usage])
        end
      end
      
      @resource_info.push(tmp)
    else
      unused_groups.push(g)
    end
  end

  p @resource_info.push
  @groups -= unused_groups

  # Render the view
  erb :index
end
