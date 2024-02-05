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
    "Disk info"
  end
end

# Define a route at the root '/' of the app.
get '/' do
  @disk_info = []
  @groups = `groups`.split.reject { |e| e.start_with?("isv") } - ["fugaku", "f-op"]

  unused_groups = []
  @groups.each do |g|
    lines = `accountd -m -g #{g} | grep -v root`.split("\n")
    if lines.size < 2
      unused_groups.push(g)
      next
    end
    tmp          = [lines.first.split[2] + " " + lines.first.split[3]] # date
    capacity_sum = 0
    inode_sum    = 0
    lines[3..-1].each do |l|
      s        = l.split
      user     = s[1]
      volume   = s[0]
      capacity = s[3].gsub(",", "").to_i
      inode    = s[2].gsub(",", "").to_i
      capacity_limit = get_disk_limit("capacity", g, volume).to_i
      inode_limit    = get_disk_limit("inode",    g, volume).to_i
      capacity_sum  += capacity
      inode_sum     += inode
      tmp.push([user, volume, capacity, inode, capacity_limit, inode_limit])
    end

    tmp.drop(1).each do |t|
      t.push(t[4] - capacity_sum) # Add capacity avail. (capacity_limit - capacity_sum)
      t.push(t[5] - inode_sum)    # Add inode avail.    (inode_limit    - inode_sum)
    end
    @disk_info.push(tmp)
  end

  @groups -= unused_groups

  # Render the view
  erb :index
end
