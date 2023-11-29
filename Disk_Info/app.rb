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

  def num_with_commas(number)
    return number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
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
end

# Define a route at the root '/' of the app.
get '/' do
  @disk_info = []
  @groups = `groups`.split.reject { |e| e.start_with?("isv") } - ["fugaku"]

  @groups.each do |g|
    lines = `accountd -m -g #{g} | grep -v root`.split("\n")
    tmp = [lines.first.split[2] + " " + lines.first.split[3]] # date
    lines[3..-1].each do |l|
      s        = l.split
      user     = s[1]
      volume   = s[0]
      capacity = s[3].gsub(",", "")
      inode    = s[2].gsub(",", "")
      capacity_limit = get_disk_limit("capacity", g, volume)
      inode_limit    = get_disk_limit("inode",    g, volume)
      tmp.push([user, volume, capacity, inode, capacity_limit, inode_limit])
    end
    @disk_info.push(tmp)
  end

  # Render the view
  erb :index
end
