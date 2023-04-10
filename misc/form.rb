require 'fileutils'

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
  FileUtils.mkdir_p(dir) unless File.directory?(dir)
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
  FileUtils.mkdir_p(dir) unless File.directory?(dir)
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

def get_cluster(queue = "")
  s =<<"EOF"
cluster:
    widget: hidden_field
EOF
  s += "    value: #{queue}" if queue != ""

  return s
end

$FUGAKU_SMALL =<<"EOF"
      - [ "fugaku-small", "small", data-set-cluster: fugaku,
          data-hide-prepost1-hours: true,
          data-hide-prepost2-hours: true,
          data-hide-reserved-hours: true,
          data-hide-gpus-per-node: true,
          data-hide-gpu1-cores: true,
          data-hide-gpu2-cores: true,
          data-hide-mem1-cores: true,
          data-hide-mem2-cores: true,
          data-hide-reserved-cores: true,
          data-hide-gpu1-memory: true,
          data-hide-gpu2-memory: true,
          data-hide-mem1-memory: true,
          data-hide-mem2-memory: true,
          data-hide-reserved-memory: true ]
EOF

$PREPOST_GPU1 =<<"EOF"
      - [ "prepost-gpu1", "gpu1", data-set-cluster: prepost,
          data-hide-group: true,
          data-hide-fugaku-hours: true,
          data-hide-fugaku-nodes: true,
          data-hide-fugaku-procs: true,
          data-hide-prepost2-hours: true,
          data-hide-reserved-hours: true,
          data-hide-gpu2-cores: true,
          data-hide-mem1-cores: true,
          data-hide-mem2-cores: true,
          data-hide-reserved-cores: true,
          data-hide-gpu2-memory: true,
          data-hide-mem1-memory: true,
          data-hide-mem2-memory: true,
          data-hide-reserved-memory: true,
          data-hide-mode: true ]
EOF

$PREPOST_GPU2 =<<"EOF"
      - [ "prepost-gpu2", "gpu2", data-set-cluster: prepost,
          data-hide-group: true,
          data-hide-fugaku-hours: true,
          data-hide-fugaku-nodes: true,
          data-hide-fugaku-procs: true,
          data-hide-prepost1-hours: true,
          data-hide-reserved-hours: true,
          data-hide-gpu1-cores: true,
          data-hide-mem1-cores: true,
          data-hide-mem2-cores: true,
          data-hide-reserved-cores: true,
          data-hide-gpu1-memory: true,
          data-hide-mem1-memory: true,
          data-hide-mem2-memory: true,
          data-hide-reserved-memory: true,
          data-hide-mode: true ]
EOF

$PREPOST_MEM1 =<<"EOF"
      - [ "prepost-mem1", "mem1", data-set-cluster: prepost,
          data-hide-group: true,
          data-hide-fugaku-hours: true,
          data-hide-fugaku-nodes: true,
          data-hide-fugaku-procs: true,
          data-hide-prepost2-hours: true,
          data-hide-reserved-hours: true,
          data-hide-gpus-per-node: true,
          data-hide-gpu1-cores: true,
          data-hide-gpu2-cores: true,
          data-hide-mem2-cores: true,
          data-hide-reserved-cores: true,
          data-hide-gpu1-memory: true,
          data-hide-gpu2-memory: true,
          data-hide-mem2-memory: true,
          data-hide-reserved-memory: true,
          data-hide-mode: true ]
EOF

$PREPOST_MEM2 =<<"EOF"
      - [ "prepost-mem2", "mem2", data-set-cluster: prepost,
          data-hide-group: true,
          data-hide-fugaku-hours: true,
          data-hide-fugaku-nodes: true,
          data-hide-fugaku-procs: true,
          data-hide-prepost1-hours: true,
          data-hide-reserved-hours: true,
          data-hide-gpus-per-node: true,
          data-hide-gpu1-cores: true,
          data-hide-gpu2-cores: true,
          data-hide-mem1-cores: true,
          data-hide-reserved-cores: true,
          data-hide-gpu1-memory: true,
          data-hide-gpu2-memory: true,
          data-hide-mem1-memory: true,
          data-hide-reserved-memory: true,
          data-hide-mode: true ]
EOF

$PREPOST_RESERVED =<<"EOF"
      - [ "prepost-ondemand-reserved", "ondemand-reserved", data-set-cluster: prepost,
          data-hide-group: true,
          data-hide-fugaku-hours: true,
          data-hide-fugaku-nodes: true,
          data-hide-fugaku-procs: true,
          data-hide-prepost1-hours: true,
          data-hide-prepost2-hours: true,
          data-hide-gpus-per-node: true,
          data-hide-gpu1-cores: true,
          data-hide-gpu2-cores: true,
          data-hide-mem1-cores: true,
          data-hide-mem2-cores: true,
          data-hide-gpu1-memory: true,
          data-hide-gpu2-memory: true,
          data-hide-mem1-memory: true,
          data-hide-mem2-memory: true,
          data-hide-mode: true ]
EOF

def get_queue(queue = "")
  s =<<"EOF"
queue:
    label: Queue
    widget: select
    options:
EOF

  if queue == ""
    s << $FUGAKU_SMALL
    s << $PREPOST_GPU1
    s << $PREPOST_GPU2
    s << $PREPOST_MEM1
    s << $PREPOST_MEM2
    s << $PREPOST_RESERVED
  elsif queue == "fugaku_small"
    s << $FUGAKU_SMALL
  elsif queue == "prepost"
    s << $PREPOST_GPU1
    s << $PREPOST_GPU2
    s << $PREPOST_MEM1
    s << $PREPOST_MEM2
    s << $PREPOST_RESERVED
  elsif queue == "gpu"
    s << $PREPOST_GPU1
    s << $PREPOST_GPU2
  elsif queue == "workflow"
    s << $PREPOST_RESERVED
    s << $PREPOST_GPU1
    s << $PREPOST_GPU2
    s << $PREPOST_MEM1
    s << $PREPOST_MEM2
  end
  
  return s
end

def get_volume()
<<"EOF"
volume:
    widget: hidden_field
EOF
end

def get_group()
  s = <<"EOF"
group:
    label: Group
    widget: select
    options:
EOF
  get_groups_cache().each do |n|
    flag = true
    $EXC_DIRS.each do |d|
      flag = false if n[0] == d
    end
    s << "      - [\"" + n[0] + "\" , \"" + n[0] + "\", " + "data-set-volume: \"" + n[3] + "\"]\n" if flag
  end

  return s
end

def get_fugaku_hours()
<<"EOF"
fugaku_hours:
    label: Elapsed time (1 - 72 hours)
    widget: number_field
    value: 1
    min: 1
    max: 72
    step: 1
    required: true
EOF
end

def get_fugaku_nodes()
<<"EOF"
fugaku_nodes:
    label: Number of nodes (1 - 384)
    widget: number_field
    value: 1
    min: 1
    max: 384
    step: 1
    required: true
EOF
end

def get_fugaku_procs()
<<"EOF"
fugaku_procs:
    label: Total number of processes (1 - 18,432)
    widget: number_field
    value: 48
    min: 1
    max: 18432
    step: 1
    required: true
    help: |
      Total number of processes <= Number of nodes x 48.
EOF
end

def get_fugaku_threads()
<<"EOF"
fugaku_threads:
    label: Number of threads (1 - 48)
    widget: number_field
    value: 1
    min: 1
    max: 48
    step: 1
    required: true
    help: |
      Number of threads x Total number of processes <= Number of nodes x 48.
EOF
end

def get_prepost1_hours()
<<"EOF"
prepost1_hours:
    label: Elapsed time (1 - 3 hours)
    widget: number_field
    value: 1
    min: 1
    max: 3
    step: 1
    required: true
EOF
end

def get_prepost2_hours()
<<"EOF"
prepost2_hours:
    label: Elapsed time (1 - 24 hours)
    widget: number_field
    value: 1
    min: 1
    max: 24
    step: 1
    required: true
EOF
end

def get_reserved_hours()
<<"EOF"
reserved_hours:
    label: Elapsed time (1 - 720 hours)
    widget: number_field
    value: 1
    min: 1
    max: 720
    step: 1
    required: true
EOF
end

def get_gpu1_cores(min = 1, max = 72)
<<"EOF"
gpu1_cores:
    label: Number of CPU cores (#{min} - #{max})
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
EOF
end

def get_gpu2_cores(min = 1, max = 36)
<<"EOF"
gpu2_cores:
    label: Number of CPU cores (#{min} - #{max})
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
EOF
end

def get_mem1_cores(min = 1, max = 224)
<<"EOF"
mem1_cores:
    label: Number of CPU cores (#{min} - #{max})
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
EOF
end

def get_mem2_cores(min = 1, max = 56)
<<"EOF"
mem2_cores:
    label: Number of CPU cores (#{min} - #{max})
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
EOF
end

def get_reserved_cores(min = 1, max = 8)
<<"EOF"
reserved_cores:
    label: Number of CPU cores (#{min} - #{max})
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
EOF
end

def get_gpu1_memory(min = 5, max = 186)
<<"EOF"
gpu1_memory:
    label: Required memory (#{min} - #{max} GB)
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
EOF
end

def get_gpu2_memory(min = 5, max = 93)
<<"EOF"
gpu2_memory:
    label: Required memory (#{min} - #{max} GB)
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
EOF
end

def get_mem1_memory(min = 5, max = 5020)
<<"EOF"
mem1_memory:
    label: Required memory (#{min} - #{max} GB)
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
EOF
end

def get_mem2_memory(min = 5, max = 1500)
<<"EOF"
mem2_memory:
    label: Required memory (#{min} - #{max} GB)
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
EOF
end

def get_reserved_memory(min = 5, max = 32)
<<"EOF"
reserved_memory:
    label: Required memory (#{min} - #{max} GB)
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
EOF
end

def get_gpus_per_node(min = 0, max = 2)
<<"EOF"
gpus_per_node:
    label: Number of GPUs (#{min} - #{max})
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
EOF
end

def get_mode()
<<"EOF"
mode:
    label: Mode
    widget: select
    options:
    - Normal
    - Boost
    - Eco
    - Boost + Eco
EOF
end

def get_working_dir()
<<"EOF"
working_dir:
    label: Working directory
    data-filepicker: true
    data-target-file-type: dirs  # Valid values are: files, dirs, or both
    data-default-directory: #{ENV['HOME']}
    data-file_picker_favorites: #{get_groups_fdirs()}
    value: #{ENV['HOME']}
    readonly: true
EOF
end

def get_email(kind = 0)
  r =<<"EOF"
email:
    widget: email_field
EOF

  if kind == 0
    return r << "    label: Email (You will receive an email when it starts)\n"
  else
    return r << "    label: Email (You will receive an email when it starts and ends)\n"
  end
end

def get_desktop()
<<"EOF"
desktop:
    widget: hidden_field
    value: xfce
EOF
end

def get_filename(str="", requred=false)
  s = "filename:\n"
  if str == ""
    s << "    label: Input file\n"
  else
    s << "    label: Input file (#{str})\n"
  end
  
  s<<<<"EOF"
    data-filepicker: true
    data-target-file-type: files  # Valid values are: files, dirs, or both
    # Optionally set a default directory
    data-default-directory: #{ENV['HOME']}
    # Optionally only allow editing through the file picker; defaults to false
    data-file_picker_favorites: #{get_groups_fdirs()}
EOF
  s << "    required: true\n" if requred

  return s
end

def get_commands()
<<"EOF"
commands:
    label: Commands (e.g. mpiexec ./a.out)
    widget: text_area
EOF
end

def get_version(versions)
  s =<<"EOF"
version:
    label: Version
    widget: select
    options:
EOF
  versions.each do |v|
    s << "    - [" + v + ", " + v
    versions.each do |i|
      s<< ", data-hide-binary-" + i.delete(".") + ": true " unless i == v
    end
    s << "]\n"
  end
  
  return s
end

def get_binary(version, binaries, value)
  s =<<"EOF"
binary_#{version.delete(".")}:
    label: Binary file version #{version}
    widget: select
    value: #{value}
    options:
EOF
  binaries.each do |b|
    s << "      - " + b + "\n"
  end

  return s
end

def get_session_name()
<<"EOF"
session_name:
    label: Session name
    required: true
EOF
end

def get_options(str="")
<<"EOF"
options:
    label: Options (#{str})
    widget: text_field
EOF
end

def registor_item(attr, item)
  attr << eval("get_" + item)
  if item == "volume"
    print "A"
    print attr
    print "B"
  end
  return "- " + item
end
