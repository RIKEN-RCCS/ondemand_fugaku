require 'fileutils'

$attr           = ""
BASE_DIR        = ENV['HOME'] + "/ondemand/cache/"
GROUPS_CACHE    = BASE_DIR + "groups.cache"
EXCLUDED_GROUPS = ["f-op", "fugaku", "oss-adm", "isv001", "isv002", "isv003"]
LIFE_TIME       = 3600

FUGAKU_SMALL =<<"EOF"
      - [ "fugaku-small", "small",
          data-set-cluster: fugaku,
          data-hide-fugaku-small-free-hours: true,
          data-hide-fugaku-large-hours: true,
          data-hide-fugaku-large-free-hours: true,
          data-hide-fugaku-large-nodes: true,
          data-hide-fugaku-large-procs: true,
          data-hide-fugaku-llio: true,
          data-hide-prepost1-hours: true,
          data-hide-prepost2-hours: true,
          data-hide-reserved-hours: true,
          data-hide-gpus-per-node: true,
          data-hide-opengl-with-nvidia: true,
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
FUGAKU_SMALL_FREE =<<"EOF"
      - [ "fugaku-small-free", "small-free",
          data-set-cluster: fugaku,
          data-hide-fugaku-small-hours: true,
          data-hide-fugaku-large-hours: true,
          data-hide-fugaku-large-free-hours: true,
          data-hide-fugaku-large-nodes: true,
          data-hide-fugaku-large-procs: true,
          data-hide-fugaku-llio: true,
          data-hide-prepost1-hours: true,
          data-hide-prepost2-hours: true,
          data-hide-reserved-hours: true,
          data-hide-gpus-per-node: true,
          data-hide-opengl-with-nvidia: true,
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
FUGAKU_LARGE =<<"EOF"
      - [ "fugaku-large", "large",
          data-set-cluster: fugaku,
          data-hide-fugaku-small-hours: true,
          data-hide-fugaku-small-free-hours: true,
          data-hide-fugaku-small-nodes: true,
          data-hide-fugaku-small-procs: true,
          data-hide-fugaku-large-free-hours: true,
          data-hide-prepost1-hours: true,
          data-hide-prepost2-hours: true,
          data-hide-reserved-hours: true,
          data-hide-gpus-per-node: true,
          data-hide-opengl-with-nvidia: true,
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
FUGAKU_LARGE_FREE =<<"EOF"
      - [ "fugaku-large-free", "large-free",
          data-set-cluster: fugaku,
          data-hide-fugaku-small-hours: true,
          data-hide-fugaku-small-free-hours: true,
          data-hide-fugaku-small-nodes: true,
          data-hide-fugaku-small-procs: true,
          data-hide-fugaku-large-hours: true,
          data-hide-prepost1-hours: true,
          data-hide-prepost2-hours: true,
          data-hide-reserved-hours: true,
          data-hide-gpus-per-node: true,
          data-hide-opengl-with-nvidia: true,
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
          data-hide-fugaku-small-hours: true,
          data-hide-fugaku-small-free-hours: true,
          data-hide-fugaku-small-nodes: true,
          data-hide-fugaku-small-procs: true,
          data-hide-fugaku-large-hours: true,
          data-hide-fugaku-large-free-hours: true,
          data-hide-fugaku-large-nodes: true,
          data-hide-fugaku-large-procs: true,
          data-hide-fugaku-llio: true,
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
          data-hide-fugaku-small-hours: true,
          data-hide-fugaku-small-free-hours: true,
          data-hide-fugaku-small-nodes: true,
          data-hide-fugaku-small-procs: true,
          data-hide-fugaku-large-hours: true,
          data-hide-fugaku-large-free-hours: true,
          data-hide-fugaku-large-nodes: true,
          data-hide-fugaku-large-procs: true,
          data-hide-fugaku-llio: true,
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
          data-hide-fugaku-small-hours: true,
          data-hide-fugaku-small-free-hours: true,
          data-hide-fugaku-small-nodes: true,
          data-hide-fugaku-small-procs: true,
          data-hide-fugaku-large-hours: true,
          data-hide-fugaku-large-free-hours: true,
          data-hide-fugaku-large-nodes: true,
          data-hide-fugaku-large-procs: true,
          data-hide-fugaku-llio: true,
          data-hide-prepost2-hours: true,
          data-hide-reserved-hours: true,
          data-hide-gpus-per-node: true,
          data-hide-opengl-with-nvidia: true,
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
          data-hide-fugaku-small-hours: true,
          data-hide-fugaku-small-free-hours: true,
          data-hide-fugaku-small-nodes: true,
          data-hide-fugaku-small-procs: true,
          data-hide-fugaku-large-hours: true,
          data-hide-fugaku-large-free-hours: true,
          data-hide-fugaku-large-nodes: true,
          data-hide-fugaku-large-procs: true,
          data-hide-fugaku-llio: true,
          data-hide-prepost1-hours: true,
          data-hide-reserved-hours: true,
          data-hide-gpus-per-node: true,
          data-hide-opengl-with-nvidia: true,
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
          data-hide-fugaku-small-hours: true,
          data-hide-fugaku-small-free-hours: true,
          data-hide-fugaku-small-nodes: true,
          data-hide-fugaku-small-procs: true,
          data-hide-fugaku-large-hours: true,
          data-hide-fugaku-large-free-hours: true,
          data-hide-fugaku-large-nodes: true,
          data-hide-fugaku-large-procs: true,
          data-hide-fugaku-llio: true,
          data-hide-prepost1-hours: true,
          data-hide-prepost2-hours: true,
          data-hide-gpus-per-node: true,
          data-hide-opengl-with-nvidia: true,
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

def store_bins_cache(file, dir_paths)
  bins = []
  dir_paths.split(":").each do |d|
    d = d + '/' unless d[-1] == '/'
    Dir.foreach(d) do |x|
      bins.push(x) if File.file?(d + x)
    end
  end
  
  # Create cache
  FileUtils.mkdir_p(File.dirname(file))
  f = File.open(file, 'w')
  f.write(Marshal.dump(bins.sort()))
  f.close()
end

def store_groups_cache()
  output = `sh /var/www/ood/apps/sys/ondemand_fugaku/misc/data_share_dir.sh`.split
  info = Array.new()
  output.each_slice(2) do |m, n|
    volume = "/vol000" + m.split("/")[1].split("0")[1]
    info.push([m.split("/").last, m, n, volume])  # [ group_name, data_dir, share_dir, volume ]
  end

  FileUtils.mkdir_p(File.dirname(GROUPS_CACHE))
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

def get_bins(fname, dir_paths)
  file = BASE_DIR + fname + ".cache"
  unless File.exist?(file) and (Time.now - File.mtime(file)) < LIFE_TIME
    store_bins_cache(file, dir_paths)
  end

  return load_cache(file)
end

def get_groups_dirs()
  groups = []
  get_groups_cache().each do |n|
    groups.push(n[1], n[2], "/2ndfs/" + n[0])
  end

  return groups
end

def get_groups_fdirs()
  dirs = "{\"title\": \"Home\", \"href\": \"" + ENV['HOME'] + "\"},"
  get_groups_cache().each do |n|
    dirs += "{\"title\": \"data ("  + n[0] + ")\", \"href\": \"" + n[1] + "\"},"
    dirs += "{\"title\": \"share (" + n[0] + ")\", \"href\": \"" + n[2] + "\"},"
    dirs += "{\"title\": \"2ndfs (" + n[0] + ")\", \"href\": \"/2ndfs/" + n[0] + "\"},"
  end

  return "'[" + dirs.chop + "]'"
end

def form_cluster(name = "")
  $attr <<<<"EOF"
  cluster:
    widget: hidden_field
EOF
  $attr << "    value: #{name}\n" if name != ""

  return "- cluster"
end

# Since the code becomes complicated when checking whether the free queue is available for each group,
# the free queue will be displayed in the user's selection item if one group can use the free queue.
def store_free_queue_cache(file)
  groups = []
  get_groups_cache().each do |n|
    flag = true
    EXCLUDED_GROUPS.each do |d|
      flag = false if n[0] == d
    end
    groups.push(n[0]) if flag
  end

  flag = false
  groups.each do |g|
    output = `sh /var/www/ood/apps/sys/ondemand_fugaku/misc/free_queue.sh #{g}`.split
    if output[0] != "0"
      flag = true
      break
    end
  end

  FileUtils.mkdir_p(File.dirname(file))
  f = File.open(file, 'w')
  f.write(Marshal.dump(flag))
  f.close()
end

def check_free_queue()
  file = BASE_DIR + "free_queue.cache"
  unless File.exist?(file) and (Time.now - File.mtime(file)) < LIFE_TIME
    store_free_queue_cache(file)
  end
  
  return load_cache(file)
end

def form_queue(name = "")
  $attr <<<<"EOF"
  queue:
    label: Queue
    widget: select
    options:
EOF
  
  free_queue_available = check_free_queue()
  
  if name == "fugaku_small_and_prepost"
    $attr << FUGAKU_SMALL
    $attr << FUGAKU_SMALL_FREE if free_queue_available
    $attr << PREPOST_GPU1
    $attr << PREPOST_GPU2
    $attr << PREPOST_MEM1
    $attr << PREPOST_MEM2
    $attr << PREPOST_RESERVED
  elsif name == "fugaku_small"
    $attr << FUGAKU_SMALL
    $attr << FUGAKU_SMALL_FREE if free_queue_available
  elsif name == "fugaku_small_and_large"
    $attr << FUGAKU_SMALL
    $attr << FUGAKU_SMALL_FREE if free_queue_available
    $attr << FUGAKU_LARGE
    $attr << FUGAKU_LARGE_FREE if free_queue_available
  elsif name == "prepost"
    $attr << PREPOST_GPU1
    $attr << PREPOST_GPU2
    $attr << PREPOST_MEM1
    $attr << PREPOST_MEM2
    $attr << PREPOST_RESERVED
  elsif name == "gpu"
    $attr << PREPOST_GPU1
    $attr << PREPOST_GPU2
  elsif name == "workflow"
    $attr << PREPOST_RESERVED
    $attr << PREPOST_GPU1
    $attr << PREPOST_GPU2
    $attr << PREPOST_MEM1
    $attr << PREPOST_MEM2
  else name == "all"
    $attr << FUGAKU_SMALL
    $attr << FUGAKU_SMALL_FREE if free_queue_available
    $attr << FUGAKU_LARGE
    $attr << FUGAKU_LARGE_FREE if free_queue_available
    $attr << PREPOST_GPU1
    $attr << PREPOST_GPU2
    $attr << PREPOST_MEM1
    $attr << PREPOST_MEM2
    $attr << PREPOST_RESERVED
  end
  
  return "- queue"
end

def form_volume()
  $attr <<<<"EOF"
  volume:
    widget: hidden_field
    cacheable: false
EOF
  return "- volume"
end

def form_group()
  $attr <<<<"EOF"
  group:
    label: Group
    widget: select
    options:
EOF
  added_groups = []
  get_groups_cache().each do |n|
    flag = true
    EXCLUDED_GROUPS.each do |d|
      flag = false if n[0] == d
    end
    if flag
      $attr << "      - [\"" + n[0] + "\" , \"" + n[0] + "\"]\n"
      added_groups.push(n[0])
    end
  end

  extra_groups = `groups`.split - added_groups - EXCLUDED_GROUPS
  extra_groups.each do |g|
    $attr << "      - [\"" + g + "\" , \"" + g + "\"]\n"
  end
  
  return "- group"
end

def form_fugaku_small_hours()
  $attr <<<<"EOF"
  fugaku_small_hours:
    label: Elapsed time (1 - 72 hours)
    widget: number_field
    value: 1
    min: 1
    max: 72
    step: 1
    required: true
EOF
  return "- fugaku_small_hours"
end

def form_fugaku_large_hours()
  $attr <<<<"EOF"
  fugaku_large_hours:
    label: Elapsed time (1 - 24 hours)
    widget: number_field
    value: 1
    min: 1
    max: 24
    step: 1
    required: true
EOF
  return "- fugaku_large_hours"
end

def form_fugaku_small_free_hours()
  $attr <<<<"EOF"
  fugaku_small_free_hours:
    label: Elapsed time (1 - 12 hours)
    widget: number_field
    value: 1
    min: 1
    max: 12
    step: 1
    required: true
EOF
  return "- fugaku_small_free_hours"
end

def form_fugaku_large_free_hours()
  $attr <<<<"EOF"
  fugaku_large_free_hours:
    label: Elapsed time (1 - 12 hours)
    widget: number_field
    value: 1
    min: 1
    max: 12
    step: 1
    required: true
EOF
  return "- fugaku_large_free_hours"
end

def form_fugaku_small_nodes()
  $attr <<<<"EOF"
  fugaku_small_nodes:
    label: Number of nodes (1 - 384)
    widget: number_field
    value: 1
    min: 1
    max: 384
    step: 1
    required: true
EOF
  return "- fugaku_small_nodes"
end

def form_fugaku_large_nodes()
  $attr <<<<"EOF"
  fugaku_large_nodes:
    label: Number of nodes (385 - 12,288)
    widget: number_field
    value: 385
    min: 385
    max: 12288
    step: 1
    required: true
EOF
  return "- fugaku_large_nodes"
end

def form_fugaku_small_procs()
  $attr <<<<"EOF"
  fugaku_small_procs:
    label: Total number of processes (1 - 18,432)
    widget: number_field
    value: 1
    min: 1
    max: 18432
    step: 1
    required: true
    help: |
      Total number of processes <= Number of nodes x 48.
EOF
  return "- fugaku_small_procs"
end

def form_fugaku_large_procs()
  $attr <<<<"EOF"
  fugaku_large_procs:
    label: Total number of processes (385 - 589,824)
    widget: number_field
    value: 385
    min: 385
    max: 589,824
    step: 1
    required: true
    help: |
      Total number of processes <= Number of nodes x 48.
EOF
  return "- fugaku_large_procs"
end

def form_fugaku_threads(help = "Number of threads x Total number of processes <= Number of nodes x 48.")
  $attr <<<<"EOF"
  fugaku_threads:
    label: Number of threads (1 - 48)
    widget: number_field
    value: 1
    min: 1
    max: 48
    step: 1
    required: true
    help: |
      #{help}
EOF
  return "- fugaku_threads"
end

def form_prepost1_hours()
  $attr <<<<"EOF"
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

def form_prepost2_hours()
  $attr <<<<"EOF"
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

def form_reserved_hours()
  $attr <<<<"EOF"
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

def form_gpu1_cores(min = 1, max = 72)
  $attr <<<<"EOF"
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

def form_gpu2_cores(min = 1, max = 36)
  $attr <<<<"EOF"
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

def form_mem1_cores(min = 1, max = 224)
  $attr <<<<"EOF"
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

def form_mem2_cores(min = 1, max = 56)
  $attr <<<<"EOF"
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

def form_reserved_cores( min = 1, max = 8)
  $attr <<<<"EOF"
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

def form_gpu1_memory(min = 5, max = 186)
  $attr <<<<"EOF"
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

def form_gpu2_memory(min = 5, max = 93)
  $attr <<<<"EOF"
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

def form_mem1_memory(min = 5, max = 5020)
  $attr <<<<"EOF"
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

def form_mem2_memory(min = 5, max = 1500)
  $attr <<<<"EOF"
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

def form_reserved_memory(min = 5, max = 32)
  $attr <<<<"EOF"
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

def form_gpus_per_node(min = 0, max = 2)
  $attr <<<<"EOF"
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

def form_opengl_with_nvidia()
  $attr <<<<"EOF"
  opengl_with_nvidia:
    label: "OpenGL with NVIDIA"
    widget: check_box
    checked_value: "true"
    unchecked_value: "false"
    cacheable: true
    help: |
      This option is experimental. If this app fails to start, please maximize the required memory.
EOF
  return "- opengl_with_nvidia"
end

def form_mode()
  $attr <<<<"EOF"
  mode:
    label: Execution mode
    widget: select
    help: |
      Please refer to the manual for details ([English](https://www.fugaku.r-ccs.riken.jp/doc_root/en/user_guides/use_latest/PowerControlFunction/index.html) or [Japanese](https://www.fugaku.r-ccs.riken.jp/doc_root/ja/user_guides/use_latest/PowerControlFunction/index.html)).
    options:
    - Normal
    - Boost
    - Eco
    - Boost + Eco
EOF
  return "- mode"
end

def form_version(versions)
  $attr <<<<"EOF"
  version:
    label: Version
    widget: select
    options:
EOF
  versions.each do |v|
    $attr << "    - [" + v + ", " + v
    versions.each do |i|
      $attr << ", data-hide-exec-" + i.delete(".-") + ": true " unless i == v
    end
    $attr << "]\n"
  end
  
  return "- version"
end

def form_exec(version, exec_files, value)
  $attr <<<<"EOF"
  exec_#{version.delete(".-")}:
    label: Executable file version #{version}
    widget: select
    value: #{value}
    options:
EOF
  exec_files.each do |e|
    $attr << "      - " + e + "\n"
  end

  return "- exec_" + version.delete(".-")
end

def form_input_file(required = true, memo = "")
  memo = "(" + memo + ")" if memo != ""

  $attr <<<<"EOF"
  input_file:
    label: Input file #{memo}
    data-filepicker: true
    data-target-file-type: files  # Valid values are: files, dirs, or both
    # Optionally set a default directory
    data-default-directory: #{ENV['HOME']}
    # Optionally only allow editing through the file picker; defaults to false
    data-file_picker_favorites: #{get_groups_fdirs()}
    required: #{required.to_s}
EOF

  return "- input_file"
end

def form_multi_input_files(required = true, prefix = "", label = "")
  $attr <<<<"EOF"
  input_file_#{prefix}:
    label: Input file #{label}
    data-filepicker: true
    data-target-file-type: files  # Valid values are: files, dirs, or both
    # Optionally set a default directory
    data-default-directory: #{ENV['HOME']}
    # Optionally only allow editing through the file picker; defaults to false
    data-file_picker_favorites: #{get_groups_fdirs()}
    required: #{required.to_s}
EOF

  return "- input_file_" + prefix
end

def form_output_file(required = true, memo = "")
  memo = "(" + memo + ")" if memo != ""
  
  $attr <<<<"EOF"
  output_file:
    label: Output file #{memo}
    required: #{required.to_s}
EOF
  return "- output_file"
end

def form_working_dir(required = true, label = "Working directory", type = "dirs", item = "working_dir", help = "")
  $attr <<<<"EOF"
  #{item}:
    label: #{label}
    value: #{ENV['HOME']}
    data-target-file-type: #{type}
    data-filepicker: true
    data-default-directory: #{ENV['HOME']}
    data-file_picker_favorites: #{get_groups_fdirs()}
    required: #{required.to_s}
    help: #{help}
EOF
  
  return "- " + item
end

def form_llio(flag, memo = "")
  memo = "Executable files are transferred there automatically." if memo == ""
  
  $attr <<<<"EOF"
  fugaku_llio:
    label: "Targets with LLIO"
    widget: select
    value: "none"
    help: "Enable this setting when using more than 7,000 nodes or 28,000 processes. To reduce IO load, the targets are transferred to the cache area. #{memo} [More info.](https://www.fugaku.r-ccs.riken.jp/doc_root/en/user_guides/use_latest/LayeredStorageAndLLIO/index.html)"
    options:
      - ["(None)", "none"]
EOF
  if flag == "input_file"
    $attr <<<<"EOF"
      - ["Input file", "input_file"]
      - ["Directory where input file exists", "directrory_where_input_file_exists"]
EOF
  elsif flag == "working_dir"
    $attr <<<<"EOF"
      - ["Working directory", "working_dir"]
EOF
  end
  return "- fugaku_llio"
end

def form_options(memo = "")
  $attr <<<<"EOF"
  options:
    label: Options (#{memo})
    widget: text_field
EOF
  return "- options"
end

def form_commands(memo = "")
  $attr <<<<"EOF"
  commands:
    label: Commands (#{memo})
    widget: text_area
EOF
  if memo == ""
    $attr << "    label: Commands\n"
  else
    $attr << "    label: Commands (#{memo})\n"
  end

  return "- commands"
end

def form_session_name()
  $attr <<<<"EOF"
  session_name:
    label: Session name
    required: true
EOF
  return "- session_name"
end

def form_email(only_start = true)
  $attr <<<<"EOF"
  email:
    widget: email_field
EOF

  if only_start
    $attr << "    label: Email (You will receive an email when it starts)\n"
  else
    $attr << "    label: Email (You will receive an email when it starts and ends)\n"
  end

  return "- email"
end

def form_desktop()
  $attr <<<<"EOF"
  desktop: xfce
EOF
  return "- desktop"
end

def form_select(item, label, options, value = "", help = "")
  $attr <<<<"EOF"
  #{item}:
    widget: select
    label: #{label}
    options:
EOF
  if options[0].is_a?(Array)
    if options[0].length == 2
      options.each do |i|
        $attr << "    - [\"" + i[0] + "\", \"" + i[1] + "\"]\n"
      end
    elsif options[0].length == 3
      options.each do |i|
        $attr << "    - [\"" + i[0] + "\", \"" + i[1] + "\", " + i[2] + "]\n"
      end
    end
  else
    options.each do |i|
      $attr << "    - [\"" + i + "\"]\n"
    end
  end
  $attr << "    value: " + value + "\n" if value != ""
  $attr << "    help: |\n"              if help  != ""
  $attr << "      " + help + "\n"       if help  != ""

  return "- #{item}"
end

def form_attr()
  attr = $attr.dup
  $attr = ""
  return attr
end

