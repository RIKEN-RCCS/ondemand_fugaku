require 'fileutils'

BASE_DIR      = ENV['HOME'] + "/ondemand/cache/"
GROUPS_CACHE  = BASE_DIR + "groups.cache"
EXCLUDED_DIRS = ["f-op", "fugaku", "isv"]
LIFE_TIME     = 3600

FUGAKU_SMALL =<<"EOF"
      - [ "fugaku-small", "small",
          data-set-cluster: fugaku,
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
PREPOST_GPU1 =<<"EOF"
      - [ "prepost-gpu1", "gpu1", 
          data-set-cluster: prepost,
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
PREPOST_GPU2 =<<"EOF"
      - [ "prepost-gpu2", "gpu2", 
          data-set-cluster: prepost,
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
PREPOST_MEM1 =<<"EOF"
      - [ "prepost-mem1", "mem1",
          data-set-cluster: prepost,
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
PREPOST_MEM2 =<<"EOF"
      - [ "prepost-mem2", "mem2",
          data-set-cluster: prepost,
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
PREPOST_RESERVED =<<"EOF"
      - [ "prepost-ondemand-reserved", "ondemand-reserved", 
          data-set-cluster: prepost,
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

  dir = File.dirname(GROUPS_CACHE)
  FileUtils.mkdir_p(dir) unless File.directory?(dir)
  f = File.open(GROUPS_CACHE, 'w')
  f.write(Marshal.dump(info))
  f.close()
end

def get_groups_cache()
  unless File.exist?(GROUPS_CACHE) and (Time.now - File.mtime(GROUPS_CACHE)) < LIFE_TIME
    store_groups_cache()
  end

  return load_cache(GROUPS_CACHE)
end

def get_bins(fname, bin_path)
  file = BASE_DIR + fname + ".cache"
  unless File.exist?(file) and (Time.now - File.mtime(file)) < LIFE_TIME
    store_bins_cache(file, bin_path)
  end

  return load_cache(file)
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

def form_cluster(attr, name = "")
  attr <<<<"EOF"
  cluster:
    widget: hidden_field
EOF
  attr << "    value: #{name}\n" if name != ""

  return "- cluster"
end

def form_queue(attr, name = "")
  attr <<<<"EOF"
  queue:
    label: Queue
    widget: select
    options:
EOF

  if name == ""
    attr << FUGAKU_SMALL
    attr << PREPOST_GPU1
    attr << PREPOST_GPU2
    attr << PREPOST_MEM1
    attr << PREPOST_MEM2
    attr << PREPOST_RESERVED
  elsif name == "fugaku_small"
    attr << FUGAKU_SMALL
  elsif name == "prepost"
    attr << PREPOST_GPU1
    attr << PREPOST_GPU2
    attr << PREPOST_MEM1
    attr << PREPOST_MEM2
    attr << PREPOST_RESERVED
  elsif name == "gpu"
    attr << PREPOST_GPU1
    attr << PREPOST_GPU2
  elsif name == "workflow"
    attr << PREPOST_RESERVED
    attr << PREPOST_GPU1
    attr << PREPOST_GPU2
    attr << PREPOST_MEM1
    attr << PREPOST_MEM2
  end
  
  return "- queue"
end

def form_volume(attr)
  attr <<<<"EOF"
  volume:
    widget: hidden_field
EOF
  return "- volume"
end

def form_group(attr)
  attr <<<<"EOF"
  group:
    label: Group
    widget: select
    options:
EOF
  get_groups_cache().each do |n|
    flag = true
    EXCLUDED_DIRS.each do |d|
      flag = false if n[0] == d
    end
    attr << "      - [\"" + n[0] + "\" , \"" + n[0] + "\", " + "data-set-volume: \"" + n[3] + "\"]\n" if flag
  end
  
  return "- group"
end

def form_fugaku_hours(attr)
  attr <<<<"EOF"
  fugaku_hours:
    label: Elapsed time (1 - 72 hours)
    widget: number_field
    value: 1
    min: 1
    max: 72
    step: 1
    required: true
EOF
  return "- fugaku_hours"
end

def form_fugaku_nodes(attr)
  attr <<<<"EOF"
  fugaku_nodes:
    label: Number of nodes (1 - 384)
    widget: number_field
    value: 1
    min: 1
    max: 384
    step: 1
    required: true
EOF
  return "- fugaku_nodes"
end

def form_fugaku_procs(attr)
  attr <<<<"EOF"
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
  return "- fugaku_procs"
end

def form_fugaku_threads(attr)
  attr <<<<"EOF"
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
  return "- fugaku_threads"
end

def form_prepost1_hours(attr)
  attr <<<<"EOF"
  prepost1_hours:
    label: Elapsed time (1 - 3 hours)
    widget: number_field
    value: 1
    min: 1
    max: 3
    step: 1
    required: true
EOF
  return "- prepost1_hours"
end

def form_prepost2_hours(attr)
  attr <<<<"EOF"
  prepost2_hours:
    label: Elapsed time (1 - 24 hours)
    widget: number_field
    value: 1
    min: 1
    max: 24
    step: 1
    required: true
EOF
  return "- prepost2_hours"
end

def form_reserved_hours(attr)
  attr <<<<"EOF"
  reserved_hours:
    label: Elapsed time (1 - 720 hours)
    widget: number_field
    value: 1
    min: 1
    max: 720
    step: 1
    required: true
EOF
  return "- reserved_hours"
end

def form_gpu1_cores(attr, min = 1, max = 72)
  attr <<<<"EOF"
  gpu1_cores:
    label: Number of CPU cores (#{min} - #{max})
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
EOF
  return "- gpu1_cores"
end

def form_gpu2_cores(attr, min = 1, max = 36)
  attr <<<<"EOF"
  gpu2_cores:
    label: Number of CPU cores (#{min} - #{max})
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
EOF
  return "- gpu2_cores"
end

def form_mem1_cores(attr, min = 1, max = 224)
  attr <<<<"EOF"
  mem1_cores:
    label: Number of CPU cores (#{min} - #{max})
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
EOF
  return "- mem1_cores"
end

def form_mem2_cores(attr, min = 1, max = 56)
  attr <<<<"EOF"
  mem2_cores:
    label: Number of CPU cores (#{min} - #{max})
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
EOF
  return "- mem2_cores"
end

def form_reserved_cores(attr, min = 1, max = 8)
  attr <<<<"EOF"
  reserved_cores:
    label: Number of CPU cores (#{min} - #{max})
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
EOF
  return "- reserved_cores"
end

def form_gpu1_memory(attr, min = 5, max = 186)
  attr <<<<"EOF"
  gpu1_memory:
    label: Required memory (#{min} - #{max} GB)
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
EOF
  return "- gpu1_memory"
end

def form_gpu2_memory(attr, min = 5, max = 93)
  attr <<<<"EOF"
  gpu2_memory:
    label: Required memory (#{min} - #{max} GB)
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
EOF
  return "- gpu2_memory"
end

def form_mem1_memory(attr, min = 5, max = 5020)
  attr <<<<"EOF"
  mem1_memory:
    label: Required memory (#{min} - #{max} GB)
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
EOF
  return "- mem1_memory"
end

def form_mem2_memory(attr, min = 5, max = 1500)
  attr <<<<"EOF"
  mem2_memory:
    label: Required memory (#{min} - #{max} GB)
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
EOF
  return "- mem2_memory"
end

def form_reserved_memory(attr, min = 5, max = 32)
  attr <<<<"EOF"
  reserved_memory:
    label: Required memory (#{min} - #{max} GB)
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
EOF
  return "- reserved_memory"
end

def form_gpus_per_node(attr, min = 0, max = 2)
  attr <<<<"EOF"
  gpus_per_node:
    label: Number of GPUs (#{min} - #{max})
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
EOF
  return "- gpus_per_node"
end

def form_mode(attr)
  attr <<<<"EOF"
  mode:
    label: Mode
    widget: select
    options:
    - Normal
    - Boost
    - Eco
    - Boost + Eco
EOF
  return "- mode"
end

def form_version(attr, versions)
  attr <<<<"EOF"
  version:
    label: Version
    widget: select
    options:
EOF
  versions.each do |v|
    attr << "    - [" + v + ", " + v
    versions.each do |i|
      attr << ", data-hide-binary-" + i.delete(".") + ": true " unless i == v
    end
    attr << "]\n"
  end
  
  return "- version"
end

def form_binary(attr, version, binaries, value)
  attr <<<<"EOF"
  binary_#{version.delete(".")}:
    label: Binary file version #{version}
    widget: select
    value: #{value}
    options:
EOF
  binaries.each do |b|
    attr << "      - " + b + "\n"
  end

  return "- binary_" + version.delete(".")
end

def form_filename(attr, memo = "", requred = false)
  attr << "  filename:\n"
  if memo == ""
    attr << "    label: Input file\n"
  else
    attr << "    label: Input file (#{memo})\n"
  end

  attr <<<<"EOF"
    data-filepicker: true
    data-target-file-type: files  # Valid values are: files, dirs, or both
    # Optionally set a default directory
    data-default-directory: #{ENV['HOME']}
    # Optionally only allow editing through the file picker; defaults to false
    data-file_picker_favorites: #{get_groups_fdirs()}
EOF
  attr << "    required: true\n" if requred

  return "- filename"
end

def form_working_dir(attr)
  attr <<<<"EOF"
  working_dir:
    label: Working directory
    data-filepicker: true
    data-target-file-type: dirs  # Valid values are: files, dirs, or both
    data-default-directory: #{ENV['HOME']}
    data-file_picker_favorites: #{get_groups_fdirs()}
    value: #{ENV['HOME']}
    readonly: true
EOF
  return "- working_dir"
end

def form_options(attr, memo = "")
  attr <<<<"EOF"
  options:
    label: Options (#{memo})
    widget: text_field
EOF
  return "- options"
end

def form_commands(attr)
  attr <<<<"EOF"
  commands:
    label: Commands (e.g. mpiexec ./a.out)
    widget: text_area
EOF
  return "- commands"
end

def form_session_name(attr)
  attr <<<<"EOF"
  session_name:
    label: Session name
    required: true
EOF
  return "- session_name"
end

def form_email(attr, only_start = true)
  attr <<<<"EOF"
  email:
    widget: email_field
EOF

  if only_start
    attr << "    label: Email (You will receive an email when it starts)\n"
  else
    attr << "    label: Email (You will receive an email when it starts and ends)\n"
  end
  
  return "- email"
end

def form_desktop(attr)
  attr <<<<"EOF"
  desktop:
    widget: hidden_field
    value: xfce
EOF
  return "- desktop"
end