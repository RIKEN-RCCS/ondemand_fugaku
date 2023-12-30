# coding: utf-8
require 'fileutils'
require 'date'
require 'csv'

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
EXCLUDED_GROUPS        = ["f-op", "fugaku", "oss-adm"] # "Group names starting with "isv" are deleted in the code.
SYS_OOD_DIR            = "/system/ood/"
ACC_DIR                = SYS_OOD_DIR + "accounting/"
ACC_GROUP_DIR          = ACC_DIR + "group/"
ACC_HOME_DIR           = ACC_DIR + "home/"
APP_CACHE_DIR          = SYS_OOD_DIR + "app/"
Resource_info          = Struct.new(:limit, :usage, :avail, :rate)
Disk_info              = Struct.new(:volume, :limit, :usage, :avail, :rate)
NOT_DEFINED            = -1
NOT_USED               = -1
$attr                  = ""

def get_group_dirs()
  info = []
  `groups`.split.each do |g|
    file = ACC_GROUP_DIR + g + "/disk.csv"
    if File.exist?(file)
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
    file = ACC_GROUP_DIR + g + "/free_queue.dat"
    if File.exist?(file)
      File.open(file, 'r') do |l|
        return true if l.gets.chomp == "ON"
      end
    end
  end

  return false
end

def output_queue(option, value, cluster, elmts)
  tmp = "      - [ \"" + option + "\", \"" + value + "\", data-set-cluster: " + cluster + ",\n"
  
  elmts.each_with_index do |e, i|
    if i != elmts.length - 1
      tmp << "          data-hide-" + e + ": true,\n"
    else
      tmp << "          data-hide-" + e + ": true ]\n"
    end
  end
  
  return tmp
end

def form_queue(name, tmp_fugaku_queue = [])
  hide_elmts  = ["fugaku-group", "fugaku-small-hours", "fugaku-small-free-hours", "fugaku-small-nodes", "fugaku-small-procs"]
  hide_elmts += ["fugaku-large-hours", "fugaku-large-free-hours", "fugaku-large-nodes", "fugaku-large-procs", "fugaku-llio"]
  hide_elmts += ["prepost1-hours", "prepost2-hours", "reserved-hours", "gpus-per-node"]
  hide_elmts += ["gpu1-cores", "gpu2-cores", "mem1-cores", "mem2-cores", "reserved-cores"]
  hide_elmts += ["gpu1-memory", "gpu2-memory", "mem1-memory", "mem2-memory", "reserved-memory", "fugaku-mode"]

  tmp_fugaku_queue.each do |i|
    ii = i.gsub("_", "-")
    hide_elmts += ["#{ii}-hours", "#{ii}-nodes", "#{ii}-procs"]
  end
  
  show_elmts_small      = ["fugaku-small-hours",      "fugaku-small-nodes", "fugaku-small-procs", "fugaku-group", "fugaku-mode"]
  show_elmts_small_free = ["fugaku-small-free-hours", "fugaku-small-nodes", "fugaku-small-procs", "fugaku-group", "fugaku-mode"]
  show_elmts_large      = ["fugaku-large-hours",      "fugaku-large-nodes", "fugaku-large-procs", "fugaku-group", "fugaku-mode", "fugaku-llio"]
  show_elmts_large_free = ["fugaku-large-hours-free", "fugaku-large-nodes", "fugaku-large-procs", "fugaku-group", "fugaku-mode", "fugaku-llio"]
  show_elmts_gpu1       = ["prepost1-hours", "gpu1-cores", "gpu1-memory", "gpus-per-node"]
  show_elmts_gpu2       = ["prepost2-hours", "gpu2-cores", "gpu2-memory", "gpus-per-node"]
  show_elmts_mem1       = ["prepost1-hours", "mem1-cores", "mem1-memory"]
  show_elmts_mem2       = ["prepost2-hours", "mem2-cores", "mem2-memory"]
  show_elmts_reserverd  = ["reserved-hours", "reserved-cores", "reserved-memory"]
  
  $attr <<<<"EOF"
  queue:
    label: Queue
    widget: select
    options:
EOF

  free_queue_available = check_free_queue()
  if name == "fugaku_small_and_prepost"
    $attr << output_queue("fugaku-small",       "small",      "fugaku",  hide_elmts - show_elmts_small)
    $attr << output_queue("fugaku-small-free",  "small-free", "fugaku",  hide_elmts - show_elmts_small_free) if free_queue_available
    $attr << output_queue("prepost-gpu1",       "gpu1",       "prepost", hide_elmts - show_elmts_gpu1)
    $attr << output_queue("prepost-gpu2",       "gpu2",       "prepost", hide_elmts - show_elmts_gpu2)
    $attr << output_queue("prepost-mem1",       "mem1",       "prepost", hide_elmts - show_elmts_mem1)
    $attr << output_queue("prepost-mem2",       "mem2",       "prepost", hide_elmts - show_elmts_mem2)
    $attr << output_queue("prepost-ondemand-reserved", "ondemand-reserved", "prepost", hide_elmts - show_elmts_reserverd)
  elsif name == "fugaku_small"
    $attr << output_queue("fugaku-small",       "small",      "fugaku",  hide_elmts - show_elmts_small)
    $attr << output_queue("fugaku-small-free",  "small-free", "fugaku",  hide_elmts - show_elmts_small_free) if free_queue_available
  elsif name == "fugaku_small_and_large"
    $attr << output_queue("fugaku-small",       "small",      "fugaku",  hide_elmts - show_elmts_small)
    $attr << output_queue("fugaku-small-free",  "small-free", "fugaku",  hide_elmts - show_elmts_small_free) if free_queue_available
    $attr << output_queue("fugaku-large",       "large",      "fugaku",  hide_elmts - show_elmts_large)
    $attr << output_queue("fugaku-large-large", "large",      "fugaku",  hide_elmts - show_elmts_large_free) if free_queue_available
  elsif name == "prepost"
    $attr << output_queue("prepost-gpu1",       "gpu1",       "prepost", hide_elmts - show_elmts_gpu1)
    $attr << output_queue("prepost-gpu2",       "gpu2",       "prepost", hide_elmts - show_elmts_gpu2)
    $attr << output_queue("prepost-mem1",       "mem1",       "prepost", hide_elmts - show_elmts_mem1)
    $attr << output_queue("prepost-mem2",       "mem2",       "prepost", hide_elmts - show_elmts_mem2)
    $attr << output_queue("prepost-ondemand-reserved", "ondemand-reserved", "prepost", hide_elmts - show_elmts_reserverd)
  elsif name == "gpu"
    $attr << output_queue("prepost-gpu1",       "gpu1",       "prepost", hide_elmts - show_elmts_gpu1)
    $attr << output_queue("prepost-gpu2",       "gpu2",       "prepost", hide_elmts - show_elmts_gpu2)
  elsif name == "workflow"
    $attr << output_queue("prepost-ondemand-reserved", "ondemand-reserved", "prepost", hide_elmts - show_elmts_reserverd)
    $attr << output_queue("prepost-gpu1",       "gpu1",       "prepost", hide_elmts - show_elmts_gpu1)
    $attr << output_queue("prepost-gpu2",       "gpu2",       "prepost", hide_elmts - show_elmts_gpu2)
    $attr << output_queue("prepost-mem1",       "mem1",       "prepost", hide_elmts - show_elmts_mem1)
    $attr << output_queue("prepost-mem2",       "mem2",       "prepost", hide_elmts - show_elmts_mem2)
  else name == "all"
    $attr << output_queue("fugaku-small",       "small",      "fugaku",  hide_elmts - show_elmts_small)
    $attr << output_queue("fugaku-small-free",  "small-free", "fugaku",  hide_elmts - show_elmts_small_free) if free_queue_available
    $attr << output_queue("fugaku-large",       "large",      "fugaku",  hide_elmts - show_elmts_large)
    $attr << output_queue("fugaku-large-large", "large",      "fugaku",  hide_elmts - show_elmts_large_free) if free_queue_available
    $attr << output_queue("prepost-gpu1",       "gpu1",       "prepost", hide_elmts - show_elmts_gpu1)
    $attr << output_queue("prepost-gpu2",       "gpu2",       "prepost", hide_elmts - show_elmts_gpu2)
    $attr << output_queue("prepost-mem1",       "mem1",       "prepost", hide_elmts - show_elmts_mem1)
    $attr << output_queue("prepost-mem2",       "mem2",       "prepost", hide_elmts - show_elmts_mem2)
    $attr << output_queue("prepost-ondemand-reserved", "ondemand-reserved", "prepost", hide_elmts -show_elmts_reserverd)
  end

  tmp_fugaku_queue.each do |i|
    ii = i.gsub("_", "-")
    $attr << output_queue(i, i, "fugaku", hide_elmts - ["#{ii}-hours", "#{ii}-nodes", "#{ii}-procs"])
  end

  return "- queue"
end

def form_fugaku_group()
  $attr <<<<"EOF"
  fugaku_group:
    label: Group
    widget: select
    options:
EOF
  groups = `groups`.split - EXCLUDED_GROUPS
  groups.delete_if { |i| i.start_with?("isv") }
  groups.each do |n|
    $attr << "      - [\"" + n + "\" , \"" + n + "\"]\n"
  end
  
  return "- fugaku_group"
end

def form_hours(name, min = NOT_DEFINED, max = NOT_DEFINED)
  if name == "fugaku_small"
    min = 1  if min == NOT_DEFINED
    max = 72 if max == NOT_DEFINED
  elsif name == "fugaku_small_free"
    min = 1  if min == NOT_DEFINED
    max = 12 if max == NOT_DEFINED
  elsif name == "fugaku_large"
    min = 1  if min == NOT_DEFINED
    max = 24 if max == NOT_DEFINED
  elsif name == "fugaku_large_free"
    min = 1  if min == NOT_DEFINED
    max = 12 if max == NOT_DEFINED
  elsif name == "prepost1"
    min = 1  if min == NOT_DEFINED
    max = 3  if max == NOT_DEFINED
  elsif name == "prepost2"
    min = 1  if min == NOT_DEFINED
    max = 24  if max == NOT_DEFINED
  elsif name == "reserved"
    min = 1   if min == NOT_DEFINED
    max = 720 if max == NOT_DEFINED
  else
    name = name.gsub("-", "_")
  end
  
  $attr <<<<"EOF"
  #{name}_hours:
    label: Elapsed time (#{min} - #{max} hours)
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
EOF
  return "- #{name}_hours"
end

def form_nodes(name, min = NOT_DEFINED, max = NOT_DEFINED)
  if name == "fugaku_small"
    min = 1     if min == NOT_DEFINED
    max = 384   if max == NOT_DEFINED
  elsif name == "fugaku_large"
    min = 385   if min == NOT_DEFINED
    max = 12288 if max == NOT_DEFINED
  else
    name = name.gsub("-", "_")
  end
  
  $attr <<<<"EOF"
  #{name}_nodes:
    label: Number of nodes (#{min} - #{num_with_commas(max)})
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
EOF
  return "- #{name}_nodes"
end

def form_procs(name, min = NOT_DEFINED, max = NOT_DEFINED)
  if name == "fugaku_small"
    min = 1      if min == NOT_DEFINED
    max = 18432  if max == NOT_DEFINED
  elsif name == "fugaku_large"
    min = 385    if min == NOT_DEFINED
    max = 589824 if max == NOT_DEFINED
  else
    name = name.gsub("-", "_")
  end
  
  $attr <<<<"EOF"
  #{name}_procs:
    label: Total number of processes (#{min} - #{num_with_commas(max)})
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
    help: |
      Total number of processes <= Number of nodes x 48.
EOF
  return "- #{name}_procs"
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

def form_cores(name, min = NOT_DEFINED, max = NOT_DEFINED)
  if name == "gpu1"
    min = 1   if min == NOT_DEFINED
    max = 72  if max == NOT_DEFINED
  elsif name == "gpu2"
    min = 1   if min == NOT_DEFINED
    max = 36  if max == NOT_DEFINED
  elsif name == "mem1"
    min = 1   if min == NOT_DEFINED
    max = 224 if max == NOT_DEFINED
  elsif name == "mem2"
    min = 1   if min == NOT_DEFINED
    max = 56  if max == NOT_DEFINED
  elsif name == "reserved"
    min = 1   if min == NOT_DEFINED
    max = 8   if max == NOT_DEFINED
  end

  $attr <<<<"EOF"
  #{name}_cores:
    label: Number of CPU cores (#{min} - #{num_with_commas(max)})
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
EOF
  return "- #{name}_cores"
end

def form_memory(name, min = NOT_DEFINED, max = NOT_DEFINED)
  if name == "gpu1"
    min = 5    if min == NOT_DEFINED
    max = 186  if max == NOT_DEFINED
  elsif name == "gpu2"
    min = 5    if min == NOT_DEFINED
    max = 93   if max == NOT_DEFINED
  elsif name == "mem1"
    min = 5    if min == NOT_DEFINED
    max = 5020 if max == NOT_DEFINED
  elsif name == "mem2"
    min = 5    if min == NOT_DEFINED
    max = 1500 if max == NOT_DEFINED
  elsif name == "reserved"
    min = 5    if min == NOT_DEFINED
    max = 32   if max == NOT_DEFINED
  end

  $attr <<<<"EOF"
  #{name}_memory:
    label: Required memory (#{min} - #{num_with_commas(max)} GB)
    widget: number_field
    value: #{min}
    min: #{min}
    max: #{max}
    step: 1
    required: true
EOF
  return "- #{name}_memory"
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
    if is_desktop
      $attr << "      - [ \"1 using VirtualGL\", \"1_VGL\" ]\n" if min <= 1 and max >= 1
      $attr << "      - [ \"1\",                 \"1\"     ]\n" if min <= 1 and max >= 1
      $attr << "      - [ \"2 using VirtualGL\", \"2_VGL\" ]\n" if min <= 2 and max >= 2
      $attr << "      - [ \"2\",                 \"2\"     ]\n" if min <= 2 and max >= 2
      $attr << "    help: Option \"using VirtualGL\" means that X rendering is accelerated using GPU.\n"
    else
      if enable_vgl
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

def form_nodelist()
  $attr <<<<"EOF"
  nodelist:
    label: Specified node
    widget: select
    help: This option is useful if you want to fix the MAC address.
    options:
      - [ "(Not specified)", "not_specified" ]
      - [ "pps01",  "pps01",  data-option-for-queue-gpu2: false, data-option-for-queue-mem1: false, data-option-for-queue-mem2: false, data-option-for-queue-ondemand-reserved: false ]
      - [ "pps02",  "pps02",  data-option-for-queue-gpu2: false, data-option-for-queue-mem1: false, data-option-for-queue-mem2: false, data-option-for-queue-ondemand-reserved: false ]
      - [ "pps03",  "pps03",  data-option-for-queue-gpu2: false, data-option-for-queue-mem1: false, data-option-for-queue-mem2: false, data-option-for-queue-ondemand-reserved: false ]
      - [ "pps04",  "pps04",  data-option-for-queue-gpu2: false, data-option-for-queue-mem1: false, data-option-for-queue-mem2: false, data-option-for-queue-ondemand-reserved: false ]
      - [ "pps05",  "pps05",  data-option-for-queue-gpu2: false, data-option-for-queue-mem1: false, data-option-for-queue-mem2: false, data-option-for-queue-ondemand-reserved: false ]
      - [ "pps06",  "pps06",  data-option-for-queue-gpu2: false, data-option-for-queue-mem1: false, data-option-for-queue-mem2: false, data-option-for-queue-ondemand-reserved: false ]
      - [ "pps07",  "pps07",  data-option-for-queue-gpu1: false, data-option-for-queue-mem1: false, data-option-for-queue-mem2: false, data-option-for-queue-ondemand-reserved: false ]
      - [ "pps08",  "pps08",  data-option-for-queue-gpu1: false, data-option-for-queue-mem1: false, data-option-for-queue-mem2: false, data-option-for-queue-ondemand-reserved: false ]
      - [ "ppm01",  "ppm01",  data-option-for-queue-gpu1: false, data-option-for-queue-gpu2: false, data-option-for-queue-mem2: false, data-option-for-queue-ondemand-reserved: false ]
      - [ "ppm02",  "ppm02",  data-option-for-queue-gpu1: false, data-option-for-queue-gpu2: false, data-option-for-queue-mem1: false, data-option-for-queue-ondemand-reserved: false ]
      - [ "ppm03",  "ppm03",  data-option-for-queue-gpu1: false, data-option-for-queue-gpu2: false, data-option-for-queue-mem1: false, data-option-for-queue-ondemand-reserved: false ]
      - [ "wheel1", "wheel1", data-option-for-queue-gpu1: false, data-option-for-queue-gpu2: false, data-option-for-queue-mem1: false, data-option-for-queue-mem2: false ]
      - [ "wheel2", "wheel2", data-option-for-queue-gpu1: false, data-option-for-queue-gpu2: false, data-option-for-queue-mem1: false, data-option-for-queue-mem2: false ]
EOF
  return "- nodelist"
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

def form_fugaku_mode()
  $attr <<<<"EOF"
  fugaku_mode:
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
  return "- fugaku_mode"
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

def form_fugaku_llio(flag, memo = "")
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
  file = ACC_GROUP_DIR + group_name + "/resource.csv"
  return nil unless File.exist?(file)

  period = Date.today.month.between?(4, 9)? "1" : "2"
  
  File.open(file, "r") do |f|
    # Resources in Fugaku are divided into early and late periods.
    # The order is reversed to give priority to the later period.
    f.readlines.reverse_each do |l|
      i = l.split(",")
      if ((i[0] == "SUBTHEMEPERIOD" and i[2] == period) or i[0] == "SUBTHEME") and i[1] == group_name and i[3].to_i != 0
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

def get_resource_limit(group_name)
  return dashboard_resource(group_name)[0].gsub(",", "")
end

def _disk_info(file, group_name)
  return [] unless File.exist?(file)
  
  info = []
  File.open(file, "r") do |f|
    f.each_line do |l|
      i = l.split(",")
      if i[0] == "GROUP" and i[1] == group_name and i[2] != "vol0001"
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

def get_disk_limit(kind, group_name, volume)
  return -1 if volume == "vol0001"

  if kind == "capacity"
    file = ACC_GROUP_DIR + group_name + "/disk.csv"
  else
    file = ACC_GROUP_DIR + group_name + "/inode.csv"
  end
  return -1 unless File.exist?(file)

  File.open(file, "r") do |f|
    f.each_line do |l|
      i = l.split(",")
      return i[3] if i[0] == "GROUP" and i[1] == group_name and i[2] == volume
    end
  end

  return -1
end

def dashboard_disk(group_name)
  file = ACC_GROUP_DIR + group_name + "/disk.csv"
  return _disk_info(file, group_name)
end

def dashboard_inode(group_name)
  file = ACC_GROUP_DIR + group_name + "/inode.csv"
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
  if 0 <= num and num <= 25
    return "green"
  elsif 25 < num and num <= 75
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

  if gpus_per_node == "0"
    return "gpus_per_node: 0"
  elsif gpus_per_node == "1" or gpus_per_node == "1_VGL"
    return "gpus_per_node: 1"
  elsif gpus_per_node == "2" or gpus_per_node == "2_VGL"
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

def submit_tmp_fugaku_queue_info(keys = [])
  queue_info = {}

  keys.each do |key|
    key = key.gsub("-", "_")
    queue_info[key] = {
      "procs" => send("#{key}_procs"),
      "nodes" => send("#{key}_nodes"),
      "hours" => send("#{key}_hours")
    }
  end

  return queue_info
end

def submit_native_fugaku(queue, fugaku_small_hours, fugaku_small_free_hours, fugaku_small_nodes,
                         fugaku_small_procs, fugaku_large_hours, fugaku_large_free_hours, fugaku_large_nodes,
                         fugaku_large_procs, fugaku_group, fugaku_mode, additional_options = "", tmp_fugaku_queue_info = [])
  str = "native:\n"
  if queue == "small"
    str << "    - -L elapse=#{fugaku_small_hours}:00:00,node=#{fugaku_small_nodes},jobenv=singularity --mpi proc=#{fugaku_small_procs}\n"
  elsif queue == "small-free"
    str << "    - -L elapse=#{fugaku_small_free_hours}:00:00,node=#{fugaku_small_nodes},jobenv=singularity --mpi proc=#{fugaku_small_procs}\n"
  elsif queue == "large"
    str << "    - -L elapse=#{fugaku_large_hours}:00:00,node=#{fugaku_large_nodes},jobenv=singularity --mpi proc=#{fugaku_large_procs}\n"
  elsif queue == "large-free"
    str << "    - -L elapse=#{fugaku_large_free_hours}:00:00,node=#{fugaku_large_nodes},jobenv=singularity --mpi proc=#{fugaku_large_procs}\n"
  else # For special queue in tmp_fugaku_queue
    # q1 = {"procs" => q1_procs, "nodes" => q1_nodes, "hours" => q1_hours }
    # q2 = {"procs" => q2_procs, "nodes" => q2_nodes, "hours" => q2_hours }
    # tmp_fugaku_queue_info = {"q1" => q1, "q2" => q2}

    queue = queue.gsub("-", "_")
    hours = tmp_fugaku_queue_info[queue]["hours"]
    nodes = tmp_fugaku_queue_info[queue]["nodes"]
    procs = tmp_fugaku_queue_info[queue]["procs"]
    str << "    - -L elapse=#{hours}:00:00,node=#{nodes},jobenv=singularity --mpi proc=#{procs}\n"
  end
  str << "    - --no-check-directory\n"
  str << "    - -g #{fugaku_group}\n"
  str << "    - -x PJM_LLIO_GFSCACHE=/vol0002:/vol0003:/vol0004:/vol0005:/vol0006\n"

  if fugaku_mode == "Boost"
    str << "    - -L freq=2200\n"
  elsif fugaku_mode == "Eco"
    str << "    -  -L eco_state=2\n"
  elsif fugaku_mode == "Boost + Eco"
    str << "    -  -L freq=2200,eco_state=2\n"
  end

  str << "    - " + additional_options + "\n" if additional_options != ""

  return str
end

def submit_native_fugaku_small(queue, fugaku_small_hours, fugaku_small_free_hours, fugaku_small_nodes, fugaku_small_procs,
                               fugaku_group, fugaku_mode)
  submit_native_fugaku(queue, fugaku_small_hours, fugaku_small_free_hours, fugaku_small_nodes, fugaku_small_procs,
                      NOT_USED, NOT_USED, NOT_USED, NOT_USED, fugaku_group, fugaku_mode)
end

def submit_native_prepost(queue, prepost1_hours, gpu1_cores, gpu1_memory, prepost2_hours,
                          gpu2_cores, gpu2_memory, mem1_cores, mem1_memory, mem2_cores,
                          mem2_memory, reserved_hours, reserved_cores, reserved_memory, nodelist="not_specified")
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

  if queue == "gpu1" or queue == "gpu2" or queue == "mem1" or queue == "mem2"
    if nodelist != "not_specified"
      str << "    - \"--nodelist=#{nodelist}\n\""
    end
  end
  
  return str
end

def submit_native_prepost_gpu(queue, prepost1_hours, gpu1_cores, gpu1_memory, prepost2_hours,
                              gpu2_cores, gpu2_memory)
  return submit_native_prepost(queue, prepost1_hours, gpu1_cores, gpu1_memory, prepost2_hours,
                               gpu2_cores, gpu2_memory, NOT_USED, NOT_USED, NOT_USED, NOT_USED,
                               NOT_USED, NOT_USED, NOT_USED)
end

def submit_native(cluster, queue, fugaku_small_hours, fugaku_small_free_hours, fugaku_small_nodes,
                  fugaku_small_procs, fugaku_large_hours, fugaku_large_free_hours, fugaku_large_nodes,
                  fugaku_large_procs, fugaku_group, fugaku_mode, prepost1_hours, gpu1_cores, gpu1_memory,
                  prepost2_hours, gpu2_cores, gpu2_memory, mem1_cores, mem1_memory, mem2_cores,
                  mem2_memory, reserved_hours, reserved_cores, reserved_memory, additional_options = "",
                  tmp_fugaku_queue_info = [])
  if cluster == "fugaku"
    return submit_native_fugaku(queue, fugaku_small_hours, fugaku_small_free_hours, fugaku_small_nodes,
                                fugaku_small_procs, fugaku_large_hours, fugaku_large_free_hours,
                                fugaku_large_nodes, fugaku_large_procs, fugaku_group, fugaku_mode, additional_options, tmp_fugaku_queue_info)
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

def submit_fugaku_llio_exec_file(queue, nodes, procs, exec_file)
  return if queue != "large" and queue != "large-free"
  
  if nodes.to_i >= LLIO_LBOUND_NODES or procs.to_i >= LLIO_LBOUND_PROCS
    return "/usr/bin/llio_transfer " + "`which " + exec_file + "`"
  end
end

def submit_fugaku_llio(queue, flag, target) # target is an input file or a working directory
  return if queue != "large" and queue != "large-free"
  
  if flag == "input_file"
    return "/usr/bin/llio_transfer " + target
  elsif flag == "directrory_where_input_file_exists"
    return "/home/system/tool/dir_transfer " + File.dirname(target)
  elsif flag == "working_dir"
    return "/home/system/tool/dir_transfer " + target
  end
end
