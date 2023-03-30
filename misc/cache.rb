$BASE_DIR = ENV['HOME'] + "/ondemand/cache/"
$GROUPS_CACHE = $BASE_DIR + "groups.cache"
$LIFE_TIME = 3600
$EXC_DIRS = ["f-op", "fugaku", "isv"]

def load_cache(file)
  f = File.open(file, 'r')
  info = Marshal.load(f.read())
  f.close()

  return info
end

def store_bins_cache(file, bin_path)
  output = `ls -1 #{bin_path}`.split("\n")
  dir = File.dirname(file)
  Dir.mkdir(dir) unless File.directory?(dir)
  f = File.open(file, 'w')
  f.write(Marshal.dump(output))
  f.close()
end

def store_groups_cache()
  output = `sh /var/www/ood/apps/sys/ondemand_apps/misc/data_share_dir.sh`.split(" ")
  info = Array.new()
  output.each_slice(2) do |m, n|
    volume = "/vol000" + m.split("/")[1].split("0")[1]
    info.push([m.split("/").last, m, n, volume])  # [ group_name, data_dir, share_dir, volume ]
  end
  
  dir = File.dirname($GROUPS_CACHE)
  Dir.mkdir(dir) unless File.directory?(dir)
  f = File.open($GROUPS_CACHE, 'w')
  f.write(Marshal.dump(info))
  f.close()
end

def get_groups_cache()
  if File.exist?($GROUPS_CACHE) and (Time.now - File.mtime($GROUPS_CACHE)) < $LIFE_TIME
    return load_cache($GROUPS_CACHE)
  else
    store_groups_cache()
    return load_cache($GROUPS_CACHE)
  end
end

def get_bins(fname, bin_path)
  file = $BASE_DIR + fname + ".cache"
  if File.exist?(file) and (Time.now - File.mtime(file)) < $LIFE_TIME
    return load_cache(file)
  else
    store_bins_cache(file, bin_path)
    return load_cache(file)
  end
end

def get_groups()
  groups = []
  get_groups_cache().each do |n|
    flag = true
    $EXC_DIRS.each do |d|
      flag = false if n[0] == d
    end
    groups.push("[\"" + n[0] + "\" , \"" + n[0] + "\", " + "data-set-volume: \"" + n[3] + "\"]") if flag
  end

  return groups
end

def get_groups_dirs()
  groups = []
  get_groups_cache().each do |n|
    groups.push(n[1], n[2])
  end

  return groups
end

def get_groups_fdirs()
  dirs = "{\"title\": \"Home\", \"href\": \"" + ENV['HOME'] + "\"},"
  get_groups_cache().each do |n|
    dirs += "{\"title\": \"data ("  + n[0] + ")\", \"href\": \"" + n[1] + "\"},"
    dirs += "{\"title\": \"share (" + n[0] + ")\", \"href\": \"" + n[2] + "\"},"
  end

  return "'[" + dirs.chop + "]'"
end
