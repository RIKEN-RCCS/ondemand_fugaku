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

  def get_update_time()
    return File.read(ACC_DIR + "date.txt")
  end
end

# Define a route at the root '/' of the app.
get '/' do
  @resource_info = []
  @groups    = `groups`.split.reject { |e| e.start_with?("isv") } - ["fugaku"]
  month      = Time.now.month
  year       = (month.between?(1, 3))? Time.now.year - 1 : Time.now.year # 年度なので1月から3月の場合はyear-1する
  period     = month.between?(4, 9) 
  filename   = (period)? year.to_s + "-1.csv" : year.to_s + "-2.csv"

  unused_groups = []
  @groups.each do |g|
    if dashboard_resource(g) == nil
      unused_groups.push(g)
      next
    end

    period_file   = ACC_GROUP_DIR + g + "/" + filename
    resource_file = ACC_GROUP_DIR + g + "/resource.csv"
    if File.exist?(period_file) and File.exist?(resource_file)
      defined_limit = {}
      CSV.foreach(resource_file, headers: true) do |row|
        defined_limit[row[1]] = row[2] if row[0].start_with?("USER")
      end
    
      tmp = []
      CSV.foreach(period_file) do |row|
        user  = row[0]
        limit = (defined_limit[user] == "unlimited")? get_resource_limit(g).to_i : defined_limit[user].to_i / 3600
        usage = row[1].to_i / 3600 # NH
        avail = (defined_limit[user] == "unlimited")? dashboard_resource(g).avail : limit - usage
        tmp.push([user, limit, usage, avail])
      end

      # Add Exclusive use
      if File.exist?(resource_file)
        sum = 0
        CSV.foreach(resource_file, headers: true) do |row|
          next if row[0] != "EXCLUSIVEUSE"
          date = Date.parse(row[3]) # End date of a job
          sum += row[5].to_i if date.month.between?(4, 9) == period
        end
        if sum != 0
          user  = "(Exclusive Use)"
          limit = get_resource_limit(g).to_i
          usage = sum / 3600 # NH
          avail = dashboard_resource(g).avail
          tmp.push([user, limit, usage, avail])
        end
      end
      
      @resource_info.push(tmp)
    else
      unused_groups.push(g)
    end # if File.exist?(period_file)
  end # end groups.each do |g|

  @groups -= unused_groups
  
  # Render the view
  erb :index
end
