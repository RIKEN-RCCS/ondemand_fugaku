require "csv"

set :erb, :escape_html => true

helpers do
  def dashboard_title
    "Open OnDemand"
  end

  def dashboard_url
    "/pun/sys/dashboard/"
  end

  def title
    "Disk usage for each user by group"
  end

  def KtoG(number)
    return number.to_i / 1024/ 1024
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
  @groups = `groups`.split.reject { |e| e.start_with?("isv") } - ["fugaku"]
  
  @disk_info      = []
  @disk_size_sum  = []
  @disk_inode_sum = []
  @date           = []
  
  @groups.each{ |g|
    # In order to increase the accuracy of file size addition, the -s option is used to output KiB instead of GiB
    lines = `accountd -c -s -m -g #{g} | grep -v root`
    c = CSV.new(lines.split("\n")[1])
    @date.push(c.readlines[0][1].strip)
    
    c = CSV.new(lines.split("\n")[2..-1].join("\n"), headers: true)
    size_sum  = 0
    inode_sum = 0
    c.each{|n|
      size_sum  += n[4].to_i
      inode_sum += n[3].to_i
    }
    c.rewind()
    @disk_info.push(c)
    @disk_size_sum.push(size_sum)
    @disk_inode_sum.push(inode_sum)
  }
  
  # Render the view
  erb :index
end
