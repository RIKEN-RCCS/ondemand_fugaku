# coding: utf-8
require 'fileutils'

SINGULARITY_DIR        = "/home/apps/singularity/ondemand/"
REMOTE_DESKTOP_AARCH64 = SINGULARITY_DIR + "desktop_ubi88_aarch64.sif"
REMOTE_DESKTOP_X86_64  = SINGULARITY_DIR + "desktop_ubi86_x86_64.sif"
JUPYTER_AARCH64        = SINGULARITY_DIR + "jupyter_ubi88_aarch64.sif"
JUPYTER_X86_64         = SINGULARITY_DIR + "jupyter_ubi86_x86_64.sif"
RSTUDIO_AARCH64        = SINGULARITY_DIR + "rstudio_ubi88_aarch64.sif"
RSTUDIO_X86_64         = SINGULARITY_DIR + "rstudio_ubi86_x86_64.sif"
VSCODE_AARCH64         = SINGULARITY_DIR + "vscode_ubi88_aarch64.sif"
VSCODE_X86_64          = SINGULARITY_DIR + "vscode_ubi86_x86_64.sif"
LLIO_LBOUND_NODES      = 7000
LLIO_LBOUND_PROCS      = 28000
EXCLUDED_GROUPS        = ["f-op", "fugaku", "oss-adm", "isv001", "isv002", "isv003"]
SYS_OOD_DIR            = "/system/ood/"
ACC_DIR                = SYS_OOD_DIR + "accounting/"
ACC_GROUP_DIR          = ACC_DIR + "group/"
ACC_HOME_DIR           = ACC_DIR + "home/"
APP_CACHE_DIR          = SYS_OOD_DIR + "app/"
Resource_info          = Struct.new(:limit, :usage, :avail, :rate)
Disk_info              = Struct.new(:volume, :limit, :usage, :avail, :rate)
$attr                  = ""

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

def get_group_dirs()
  info = []
  `groups`.split.each do |g|
    file = ACC_GROUP_DIR + g + ".disk"
    if File.exist?(file) then
      dirs = File.readlines(file).grep(/\/vol/)
      unless dirs.empty?
        dirs.each do |d|
          info.push(d.chomp)
	end
        info.push("/2ndfs/" + g)
      end
    end
  end

  return info.sort
end

def get_groups_fdirs()
  dirs = "{\"title\": \"Home\", \"href\": \"" + ENV['HOME'] + "\"},"
  get_group_dirs.each do |d|
    dirs += "{\"title\": \"" +  d + "\", \"href\": \"" + d + "\"},"
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
def check_free_queue()
  `groups`.split.each do |g|
    file = ACC_GROUP_DIR + g + ".free_queue"
    if File.exist?(file) then
      File.open(file, 'r') do |l|
        return true if l.gets.chomp == "ON"
      end
    end
  end

  return false
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
  groups = `groups`.split - EXCLUDED_GROUPS
  groups.each do |n|
    $attr << "      - [\"" + n + "\" , \"" + n + "\"]\n"
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

def form_gpus_per_node(enable_vgl = false, is_desktop = false, min = 0, max = 2)
    $attr <<<<"EOF"
  gpus_per_node:
    label: Number of GPUs (#{min} - #{max})
    value: #{min}
    required: true
    widget: select
    options:
EOF
    $attr << "      - [ \"0\", \"0\" ]\n" if min <= 0 and max >= 0
    if is_desktop then
      $attr << "      - [ \"1 using VirtualGL\", \"1_VGL\" ]\n" if min <= 1 and max >= 1
      $attr << "      - [ \"1\",                 \"1\"     ]\n" if min <= 1 and max >= 1
      $attr << "      - [ \"2 using VirtualGL\", \"2_VGL\" ]\n" if min <= 2 and max >= 2
      $attr << "      - [ \"2\",                 \"2\"     ]\n" if min <= 2 and max >= 2
      $attr << "    help: Option \"using VirtualGL\" means that X rendering is accelerated using GPU.\n"
    else
      if enable_vgl then
        $attr << "      - [ \"1\", \"1_VGL\" ]\n" if min <= 1 and max >= 1
        $attr << "      - [ \"2\", \"2_VGL\" ]\n" if min <= 2 and max >= 2
        $attr << "    help: When GPU >= 1, X rendering is accelerated using GPU.\n"
      else
        $attr << "      - [ \"1\", \"1\" ]\n" if min <= 1 and max >= 1
        $attr << "      - [ \"2\", \"2\" ]\n" if min <= 2 and max >= 2
      end
    end
    return "- gpus_per_node"
end

def form_check(item, label, help, required = true)
  $attr <<<<"EOF"
  #{item}:
    label: #{label}
    widget: check_box
    checked_value: "true"
    unchecked_value: "false"
    cacheable: true
    required: #{required.to_s}
    help: #{help}
EOF
  return "- #{item}"
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

def form_free_input_file(required = true, label = "Input file", item = "input_file", help = "")
  $attr <<<<"EOF"
  #{item}:
    label: #{label}
    data-filepicker: true
    data-target-file-type: files  # Valid values are: files, dirs, or both
    # Optionally set a default directory
    data-default-directory: #{ENV['HOME']}
    # Optionally only allow editing through the file picker; defaults to false
    data-file_picker_favorites: #{get_groups_fdirs()}
    required: #{required.to_s}
    help: #{help}
EOF

  return "- #{item}"
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

def form_load_cache(file)
  f = File.open(APP_CACHE_DIR + file, 'r')
  cache = Marshal.load(f.read())
  f.close()

  return cache
end

def dashboard_info(file)
  info = []
  File.open(file, "r") do |f|
    f.each_line do |l|
      info.push(l)
    end
  end

  return info
end

def num_with_commas(number)
  return number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
end

def dashboard_resource(group_name)
  file = ACC_GROUP_DIR + group_name + ".resource"
  return nil unless File.exist?(file)
  
  File.open(file, "r") do |f|
    # Resources in Fugaku are divided into early and late periods.
    # The order is reversed to give priority to the later period.
    f.readlines.reverse_each do |l|
      i = l.split(",")
      if i[0] == "SUBTHEMEPERIOD" and i[1] == group_name and i[3].to_i != 0 and i[5] != "---" then
        limit = i[3].to_i/3600
        usage = i[7].to_i/3600
        avail = i[6].to_i/3600
        rate  = ((usage * 100) / limit).round
        return Resource_info.new(num_with_commas(limit), num_with_commas(usage), num_with_commas(avail), rate)
      end
    end
  end

  return nil
end

def _disk_info(file, group_name)
  return [] unless File.exist?(file)
  
  info = []
  File.open(file, "r") do |f|
    f.each_line do |l|
      i = l.split(",")
      if i[0] == "GROUP" and i[1] == group_name and i[2] != "vol0001" then
        volume = "/" + i[2]
        limit  = i[3].to_i
        usage  = i[4].to_i
        avail  = i[5].to_i
        rate   = ((usage * 100) / limit).round
        info.push(Disk_info.new(volume, num_with_commas(limit), num_with_commas(usage), num_with_commas(avail), rate))
      end
    end
  end

  return info
end

def dashboard_disk(group_name)
  file = ACC_GROUP_DIR + group_name + ".disk"
  return _disk_info(file, group_name)
end

def dashboard_inode(group_name)
  file = ACC_GROUP_DIR + group_name + ".inode"
  return _disk_info(file, group_name)
end

def _home_info(file)
  File.open(file, "r") do |f|
    f.each_line do |l|
      i = l.split(",")
      volume = "/" + i[2]
      limit  = i[3].to_i
      usage  = i[4].to_i
      avail  = i[5].to_i
      rate   = ((usage * 100) / limit).round
      return Disk_info.new(volume, num_with_commas(limit), num_with_commas(usage), num_with_commas(avail), rate)
    end
  end

  return nil
end

def dashboard_home_disk()
  file = ACC_HOME_DIR + ENV['USER'] + ".disk"
  return _home_info(file)
end

def dashboard_home_inode()
  file = ACC_HOME_DIR + ENV['USER'] + ".inode"
  return _home_info(file)
end

def dashboard_color(num)
  if 0 <= num and num <= 25 then
    return "green"
  elsif 25 < num and num <= 75 then
    return "blue"
  else
    return "red"
  end
end

def dashboard_date()
  file = ACC_DIR + "date.txt"
  File.open(file, 'r') do |f|
    first_line = f.gets
    return first_line
  end
end

def output_xfce(gpus_per_node = "0")
  <<"EOF"
# Remove any preconfigured monitors
if [[ -f "${HOME}/.config/monitors.xml" ]]; then
  mv "${HOME}/.config/monitors.xml" "${HOME}/.config/monitors.xml.bak"
fi

# Copy over default panel if doesn't exist, otherwise it will prompt the user
PANEL_CONFIG="${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
if [[ ! -e "${PANEL_CONFIG}" ]]; then
  mkdir -p "$(dirname "${PANEL_CONFIG}")"
  cp "/etc/xdg/xfce4/panel/default.xml" "${PANEL_CONFIG}"
fi

# Disable startup services
xfconf-query -c xfce4-session -p /startup/ssh-agent/enabled -n -t bool -s false
xfconf-query -c xfce4-session -p /startup/gpg-agent/enabled -n -t bool -s false

# Disable useless services on autostart
AUTOSTART="${HOME}/.config/autostart"
rm -fr "${AUTOSTART}"    # clean up previous autostarts
mkdir -p "${AUTOSTART}"
for service in "pulseaudio" "rhsm-icon" "spice-vdagent" "tracker-extract" "tracker-miner-apps" "tracker-miner-user-guides" "xfce4-power-manager" "xfce-polki\
t"; do
  echo -e "[Desktop Entry]\nHidden=true" > "${AUTOSTART}/${service}.desktop"
done

# Run Xfce4 Terminal as login shell (sets proper TERM)
TERM_CONFIG="${HOME}/.config/xfce4/terminal/terminalrc"
if [[ ! -e "${TERM_CONFIG}" ]]; then
  mkdir -p "$(dirname "${TERM_CONFIG}")"
  sed 's/^ \{4\}//' > "${TERM_CONFIG}" << EOL
    [Configuration]
    CommandLoginShell=TRUE
EOL
else
  sed -i \
    '/^CommandLoginShell=/{h;s/=.*/=TRUE/};${x;/^$/{s//CommandLoginShell=TRUE/;H};x}' \
    "${TERM_CONFIG}"
fi

# Set custom Directories
USER_DIRS_CONFIG="${HOME}/.config/user-dirs.dirs"
if [[ ! -e "${USER_DIRS_CONFIG}" ]]; then
    xdg-user-dirs-update --set DESKTOP ${HOME}
    xdg-user-dirs-update --set DOCUMENTS ${HOME}
    xdg-user-dirs-update --set DOWNLOAD ${HOME}
    xdg-user-dirs-update --set MUSIC ${HOME}
    xdg-user-dirs-update --set PICTURES ${HOME}
    xdg-user-dirs-update --set PUBLICSHARE ${HOME}
    xdg-user-dirs-update --set TEMPLATES ${HOME}
    xdg-user-dirs-update --set VIDEOS ${HOME}
fi

# launch dbus first through eval becuase it can conflict with a conda environment
# see https://github.com/OSC/ondemand/issues/700
eval $(dbus-launch --sh-syntax)

# For some reason the lang module information disappears, so reload it.
module remove lang
module load lang

_VIRTUALGL=""
[ `arch` = "x86_64" ] && [ "#{gpus_per_node}" = "1_VGL" -o "#{gpus_per_node}" = "2_VGL" ] && _VIRTUALGL="vglrun -d egl"
EOF
end

def submit_working_dir(working_dir)
  <<"EOF"
WORKING_DIR=#{working_dir}
    [ "${WORKING_DIR}" = "" ] && WORKING_DIR=${HOME}
    mkdir -p "${WORKING_DIR}"
    cd "${WORKING_DIR}"
EOF
end

def submit_gpus_per_node(queue, gpus_per_node)
  return if queue != "gpu1" and queue != "gpu2"

  if gpus_per_node == "0" then
    return "gpus_per_node: 0"
  elsif gpus_per_node == "1" or gpus_per_node == "1_VGL" then
    return "gpus_per_node: 1"
  elsif gpus_per_node == "2" or gpus_per_node == "2_VGL" then
    return "gpus_per_node: 2"
  end
end

def submit_email(email = "", only_start = true)
  if email != ""
    str = "email: #{email}\n  email_on_started: true\n"
    if only_start
      return str
    else
      return str << "  email_on_terminated: true\n"
    end
  end
end

def submit_native_fugaku(queue, fugaku_small_hours, fugaku_small_free_hours, fugaku_small_nodes,
                         fugaku_small_procs, fugaku_large_hours, fugaku_large_free_hours, fugaku_large_nodes,
                         fugaku_large_procs, group, volume, mode, additional_options = "")
  str = "native:\n"
  if queue == "small" then
    str << "    - -L elapse=#{fugaku_small_hours}:00:00,node=#{fugaku_small_nodes},jobenv=singularity --mpi proc=#{fugaku_small_procs}\n"
  elsif queue == "small-free" then
    str << "    - -L elapse=#{fugaku_small_free_hours}:00:00,node=#{fugaku_small_nodes},jobenv=singularity --mpi proc=#{fugaku_small_procs}\n"
  elsif queue == "large" then
    str << "    - -L elapse=#{fugaku_large_hours}:00:00,node=#{fugaku_large_nodes},jobenv=singularity --mpi proc=#{fugaku_large_procs}\n"
  elsif queue == "large-free" then
    str << "    - -L elapse=#{fugaku_large_free_hours}:00:00,node=#{fugaku_large_nodes},jobenv=singularity --mpi proc=#{fugaku_large_procs}\n"
  end
  str << "    - --no-check-directory\n"
  str << "    - -g #{group}\n"

  # volume == "" is set when a group with no data/share directory defined (e.g. rist-a) is set.
  if volume == "/vol0004" or volume == ""
    str << "    - -x PJM_LLIO_GFSCACHE=/vol0004\n"
  else
    str << "    - -x PJM_LLIO_GFSCACHE=/vol0004:#{volume}\n"
  end

  if mode == "Boost"
    str << "    - -L freq=2200\n"
  elsif mode == "Eco"
    str << "    -  -L eco_state=2\n"
  elsif mode == "Boost + Eco"
    str << "    -  -L freq=2200,eco_state=2\n"
  end

  str << "    - " + additional_options + "\n" if additional_options != ""

  return str
end

def submit_native_fugaku_small(queue, fugaku_small_hours, fugaku_small_free_hours, fugaku_small_nodes, fugaku_small_procs,
                               group, volume, mode)
  submit_native_fugaku(queue, fugaku_small_hours, fugaku_small_free_hours, fugaku_small_nodes, fugaku_small_procs,
                      "-1", "-1", "-1", "-1", group, volume, mode)
end

def submit_native_prepost(queue, prepost1_hours, gpu1_cores, gpu1_memory, prepost2_hours,
                          gpu2_cores, gpu2_memory, mem1_cores, mem1_memory, mem2_cores,
                          mem2_memory, reserved_hours, reserved_cores, reserved_memory)
  str = "native:\n"
  if queue == "gpu1"
    str<<<<"EOF"
    - "-t"
    - "#{prepost1_hours}:00:00"
    - "-n"
    - "#{gpu1_cores}"
    - "--mem"
    - "#{gpu1_memory}G"
EOF
  elsif queue == "gpu2"
    str<<<<"EOF"
    - "-t"
    - "#{prepost2_hours}:00:00"
    - "-n"
    - "#{gpu2_cores}"
    - "--mem"
    - "#{gpu2_memory}G"
EOF
  elsif queue == "mem1"
    str<<<<"EOF"
    - "-t"
    - "#{prepost1_hours}:00:00"
    - "-n"
    - "#{mem1_cores}"
    - "--mem"
    - "#{mem1_memory}G"
EOF
  elsif queue == "mem2"
    str<<<<"EOF"
    - "-t"
    - "#{prepost2_hours}:00:00"
    - "-n"
    - "#{mem2_cores}"
    - "--mem"
    - "#{mem2_memory}G"
EOF
  elsif queue == "ondemand-reserved"
    str<<<<"EOF"
    - "-t"
    - "#{reserved_hours}:00:00"
    - "-n"
    - "#{reserved_cores}"
    - "--mem"
    - "#{reserved_memory}G"
EOF
  end

  return str
end

def submit_native_prepost_gpu(queue, prepost1_hours, gpu1_cores, gpu1_memory, prepost2_hours,
                              gpu2_cores, gpu2_memory)
  return submit_native_prepost(queue, prepost1_hours, gpu1_cores, gpu1_memory, prepost2_hours,
                               gpu2_cores, gpu2_memory, -1, -1, -1, -1, -1, -1, -1)
end

def submit_native(cluster, queue, fugaku_small_hours, fugaku_small_free_hours, fugaku_small_nodes,
                  fugaku_small_procs, fugaku_large_hours, fugaku_large_free_hours, fugaku_large_nodes,
                  fugaku_large_procs, group, volume, mode, prepost1_hours, gpu1_cores, gpu1_memory,
                  prepost2_hours, gpu2_cores, gpu2_memory, mem1_cores, mem1_memory, mem2_cores,
                  mem2_memory, reserved_hours, reserved_cores, reserved_memory)
  if cluster == "fugaku"
    return submit_native_fugaku(queue, fugaku_small_hours, fugaku_small_free_hours, fugaku_small_nodes,
                                fugaku_small_procs, fugaku_large_hours, fugaku_large_free_hours,
                                fugaku_large_nodes, fugaku_large_procs, group, volume, mode)
  elsif cluster == "prepost"
    return submit_native_prepost(queue, prepost1_hours, gpu1_cores, gpu1_memory, prepost2_hours,
                                 gpu2_cores, gpu2_memory, mem1_cores, mem1_memory, mem2_cores,
                                 mem2_memory, reserved_hours, reserved_cores, reserved_memory)
  end
end

def setting_singularity(name)
  <<"EOF"
    export SINGULARITYENV_XDG_DATA_HOME=${HOME}/ondemand/#{name}/`arch`
    export SINGULARITYENV_TMPDIR=${SINGULARITYENV_XDG_DATA_HOME}/tmp
    export SINGULARITYENV_XDG_RUNTIME_DIR=${SINGULARITYENV_TMPDIR}
    export SINGULARITY_BINDPATH=/data,/work,/sys,/var/opt,/usr/share/Modules,/etc/profile.d/zFJSVlangload.sh,/2ndfs
    mkdir -p $SINGULARITYENV_TMPDIR
    NV_OPTION=""
    CUDA_PATH=/usr/local/cuda
    if [ -e $CUDA_PATH ]; then
        NV_OPTION="--nv"
        CUDA_REAL_PATH=`readlink -f /usr/local/cuda`
        export SINGULARITY_BINDPATH=$SINGULARITY_BINDPATH,$CUDA_REAL_PATH:$CUDA_PATH
        export SINGULARITYENV_PATH=$PATH:$CUDA_PATH/bin
        export SINGULARITYENV_LD_LIBRARY_PATH=$CUDA_PATH/lib64:$LD_LIBRARY_PATH
    fi

    for i in `ls -l /opt | grep ^d | awk '{print $9}'`; do
        export SINGULARITY_BINDPATH=$SINGULARITY_BINDPATH,/opt/$i
    done
    for i in `ls -1 / | grep ^vol`; do
      export SINGULARITY_BINDPATH=$SINGULARITY_BINDPATH,/$i
    done
    for i in /lib64/liblustreapi.so /run/psv; do
      [ -e $i ] && export SINGULARITY_BINDPATH=$SINGULARITY_BINDPATH,$i
    done
    [ -e /usr/bin/xospastop ] && export SINGULARITY_BINDPATH=$SINGULARITY_BINDPATH,/usr/bin/xospastop

    if [ #{name} = "remote_desktop" ]; then
      if [ `arch` = aarch64 ]; then
        IMAGE=#{REMOTE_DESKTOP_AARCH64}
      else
        IMAGE=#{REMOTE_DESKTOP_X86_64}
      fi
    elif [ #{name} = "jupyter" ]; then
      if [ `arch` = aarch64 ]; then
        IMAGE=#{JUPYTER_AARCH64}
      else
        IMAGE=#{JUPYTER_X86_64}
      fi
    elif [ #{name} = "rstudio" ]; then
      if [ `arch` = aarch64 ]; then
        IMAGE=#{RSTUDIO_AARCH64}
      else
        IMAGE=#{RSTUDIO_X86_64}
      fi
    elif [ #{name} = "vscode" ]; then
      if [ `arch` = aarch64 ]; then
        IMAGE=#{VSCODE_AARCH64}
      else
        IMAGE=#{VSCODE_X86_64}
      fi
    fi
EOF
end

def submit_vnc(staged_root)
  str =<<"EOF"
  template: "vnc"
  websockify_cmd: '/usr/bin/websockify'
  script_wrapper: |
    cat << "CTRSCRIPT" > #{staged_root}/container.sh
    #!/usr/bin/env bash
    export PATH="$PATH:/opt/TurboVNC/bin"
    export PATH="$PATH:/opt/ParaView/bin"
    export PATH="$PATH:/opt/visit/bin"
    export PATH="$PATH:/vol0004/apps/avs_xp851/bin/linux_64_el8"
    export XP_LICENSE_SERVER=fn01sv02
    export PATH="$PATH:/opt/xcrysden/bin"
    export PATH="$PATH:/usr/local/vesta"
    export PATH="$PATH:/opt/smokeview"
    export PATH="$PATH:/opt/ovito/bin"
    export PATH="$PATH:/usr/local/C-TOOLS062"
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/qt-4.8.6/lib"
    export PATH="$PATH:/usr/local/pymol-2.5.0/bin"
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/pymol-2.5.0/lib64"
    export PATH="$PATH:/opt/ImageJ"
    %s
    CTRSCRIPT

    cd ${HOME}
    #{setting_singularity("remote_desktop")}

    chmod +x #{staged_root}/container.sh
    singularity run ${NV_OPTION} ${IMAGE} #{staged_root}/container.sh
EOF
end

def submit_env(threads, app_name = "", version = "")
  str =<<"EOF"
#!/usr/bin/env bash
    set -e
    . /vol0004/apps/oss/spack/share/spack/setup-env.sh
EOF

  if version == "" # app_name is hash
    str << "    spack load /#{app_name}\n"
  else
    str << "    spack load #{app_name}@#{version}\n"
  end
  
  if threads != 0
    return str << "    export OMP_NUM_THREADS=#{threads}"
  else
    return str
  end
end

def submit_llio_exec_file(queue, nodes, procs, exec_file)
  return if queue != "large" and queue != "large-free"
  
  if nodes.to_i >= LLIO_LBOUND_NODES or procs.to_i >= LLIO_LBOUND_PROCS
    return "/usr/bin/llio_transfer " + "`which " + exec_file + "`"
  end
end

def submit_llio(queue, flag, target) # target is an input file or a working directory
  return if queue != "large" and queue != "large-free"
  
  if flag == "input_file"
    return "/usr/bin/llio_transfer " + target
  elsif flag == "directrory_where_input_file_exists"
    return "/home/system/tool/dir_transfer " + File.dirname(target)
  elsif flag == "working_dir"
    return "/home/system/tool/dir_transfer " + target
  end
end
