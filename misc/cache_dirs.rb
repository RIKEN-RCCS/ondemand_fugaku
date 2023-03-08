def load_cache(file)
  f = File.open(file, 'r')
  dirs = Marshal.load(f.read())
  f.close()
  return dirs
end

def store_cache(file)
  dir = File.dirname(file)
  if not File.directory?(dir)
    Dir.mkdir(dir)
  end

  dirs = `sh /var/www/ood/apps/sys/ondemand_apps/misc/data_share_dir.sh`.split(" ")
  f = File.open(file, 'w')
  f.write(Marshal.dump(dirs))
  f.close()
end

def get_cached_dirs(file, lifetime)
  if File.exist?(file) and (Time.now - File.mtime(file)) < lifetime
    return load_cache(file)
  else
    store_cache(file)
    return load_cache(file)
  end
end

def get_favorites_dirs(file, lifetime)
  dirs = ""
  tmp_dirs = get_cached_dirs(file, lifetime)
  share_num = 1
  data_num  = 1
  tmp_dirs.each{|d|
    if d.include?("/share/")
      dirs += "{\"title\": \"Share Directory" + share_num.to_s + "\", \"href\": \"" + d + "\"},"
      share_num += 1
    elsif d.include?("/data/")
      dirs += "{\"title\": \"Data Directory" + data_num.to_s + "\", \"href\": \"" + d + "\"},"
      data_num += 1
    end
  }
  return "'[" + dirs.chop! + "]'"
end
