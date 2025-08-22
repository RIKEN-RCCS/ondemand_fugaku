require "/var/www/ood/apps/sys/ondemand_fugaku/misc/dashboard/common.rb"

set :erb, :escape_html => true

helpers do
  def dashboard_title
    "Open OnDemand"
  end

  def dashboard_url
    "/pun/sys/dashboard/"
  end

  def title
    "Budget info"
  end

  def get_update_time()
    file = File.join(ACC_DIR, "date.txt")
    File.read(file) if File.file?(file) && File.readable?(file)
  end
  
  def check_admin(group)
    cmd = "resourcemod -g #{group}"
    o = (Socket.gethostname == "fn06sv04")? `#{cmd}` : `ssh login #{cmd}`
    return (o != "You have no authority to execute the tool.\n")
  end
end

# Define a route at the root '/' of the app.
get '/' do
  @is_admin    = []
  @budget_info = []
  @groups      = `groups`.split.reject { |e| e.start_with?("isv") } - ["fugaku"]
    
  unused_groups = []
  @groups.each do |g|
    if dashboard_budget(g) == nil
      unused_groups.push(g)
      next
    end
      
    user_budget_file  = ACC_GROUP_DIR + g + "/user_budget.csv"
    group_budget_file = ACC_GROUP_DIR + g + "/group_budget.csv"
    if File.exist?(user_budget_file) and File.exist?(group_budget_file) and File.readable?(user_budget_file) and File.readable?(group_budget_file)
      defined_limit = {}
      CSV.foreach(group_budget_file, headers: true) do |row|
        defined_limit[row[1]] = row[2] if row[0].start_with?("USER")
      end
        
      tmp = []
      CSV.foreach(user_budget_file) do |row|
        user  = row[0]
        limit = (defined_limit[user] == "unlimited")? get_budget_limit(g).to_i : defined_limit[user].to_i / 3600
        usage = row[1].to_i / 3600 # NH
        avail = (defined_limit[user] == "unlimited")? dashboard_budget(g).avail : limit - usage
        avail = 0 if avail.to_i < 0
        tmp.push([user, limit, usage, avail])
      end

      # Add Exclusive use
      sum = 0
      CSV.foreach(group_budget_file, headers: true) do |row|
        next if row[0] != "EXCLUSIVEUSE"
        date = Date.parse(row[3]) # End date of a job
        sum += row[5].to_i if date.month.between?(4, 9) == Time.now.month.between?(4, 9)
      end
      if sum != 0
        user  = "(Exclusive Use)"
        limit = get_budget_limit(g).to_i
        usage = sum / 3600 # NH
        avail = dashboard_budget(g).avail
        tmp.push([user, limit, usage, avail])
      end
        
      @budget_info.push(tmp)
      @is_admin.push(check_admin(g))
    else
      unused_groups.push(g)
    end # if File.exist?(period_file)
  end # end groups.each do |g|
    
  @groups -= unused_groups

  # Render the view
  erb :index
end

post '/new' do
  group   = params['group']
  user    = params['user']
  voule_s = params['volume_NH'].to_i * 3600

  cmd  = "resourcemod -g #{group} -u #{user}"
  cmd += " -resource #{voule_s}" if params['volume_NH'] != get_budget_limit(group)
  (Socket.gethostname == "fn06sv04")? system(cmd) : system("ssh login #{cmd}")
  
  # Rewrite group_budget.csv
  group_budget_file = ACC_GROUP_DIR + group + "/group_budget.csv"
  cmd = "accountj -g #{group} -c -r 1 -e -E | tr -d '\"' | egrep '^SUBTHEME|^SUBTHEMEPERIOD|^EXCLUSIVEUSE|^RESOURCE_GROUP|^USER' | egrep -v '^USER_' > #{group_budget_file}"
  (Socket.gethostname == "fn06sv04")? system(cmd) : system("ssh login #{cmd}")
  
  redirect '/pun/sys/Budget_Info/'
end
