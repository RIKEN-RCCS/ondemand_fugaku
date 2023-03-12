$CACHE_FILE = ENV['HOME'] + "/ondemand/group_info.cache"
$LIFE_TIME = 3600
$EXC_DIRS = ["f-op", "fugaku", "isv"]

def load_cache()
  f = File.open($CACHE_FILE, 'r')
  info = Marshal.load(f.read())
  f.close()
  
  return info
end

def store_cache()
  output = `sh /var/www/ood/apps/sys/ondemand_apps/misc/data_share_dir.sh`.split(" ")
  info = Array.new()
  output.each_slice(2) do |m, n|
    volume = "/vol000" + m.split("/")[1].split("0")[1]
    info.push([m.split("/").last, m, n, volume])  # [ group_name, data_dir, share_dir, volume ]
  end
  
  dir = File.dirname($CACHE_FILE)
  Dir.mkdir(dir) unless File.directory?(dir)
  f = File.open($CACHE_FILE, 'w')
  f.write(Marshal.dump(info))
  f.close()
end

def get_cache()
  if File.exist?($CACHE_FILE) and (Time.now - File.mtime($CACHE_FILE)) < $LIFE_TIME
    return load_cache()
  else
    store_cache()
    return load_cache()
  end
end

def get_groups()
  groups = []
  get_cache().each do |n|
    flag = true
    $EXC_DIRS.each do |d|
      flag = false if n[0] == d
    end
    groups.push("[\"" + n[0] + "\" , \"" + n[0] + "\", " + "data-set-volume: \"" + n[3] + "\"]") if flag
  end

  return groups
end

def get_dirs()
  groups = []
  get_cache().each do |n|
    groups.push(n[1], n[2])
  end

  return groups
end

def get_favorites_dirs()
  dirs = ""
  get_cache().each do |n|
    dirs += "{\"title\": \"data ("  + n[0] + ")\", \"href\": \"" + n[1] + "\"},"
    dirs += "{\"title\": \"share (" + n[0] + ")\", \"href\": \"" + n[2] + "\"},"
  end

  return "'[" + dirs.chop + "]'"
end
