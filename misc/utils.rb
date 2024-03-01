# coding: utf-8
require 'fileutils'
require 'date'
require 'csv'
require 'time'

FUGAKU_PT_AUG_START    = '2023-08-01 15:00'
FUGAKU_PT_AUG_END      = '2023-08-31 15:00'
FUGAKU_PT_FEB_START    = '2024-02-05 15:00'
FUGAKU_PT_FEB_END      = '2024-03-11 15:00'
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
Resource_info          = Struct.new(:limit, :usage, :avail, :ratio)
Disk_info              = Struct.new(:volume, :limit, :usage, :avail, :ratio)
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

def _form_fugaku_group()
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

  return "  - fugaku_group\n"
end

def _form_hours(name, min = NOT_DEFINED, max = NOT_DEFINED)
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
  elsif name == "fugaku_cd_portal"
    min = 1   if min == NOT_DEFINED
    max = 720 if max == NOT_DEFINED
  elsif name == "fugaku_pt_aug" or name == "fugaku_pt_feb"
    min = 1   if min == NOT_DEFINED
    max = 24  if max == NOT_DEFINED
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
  return "  - #{name}_hours\n"
end

def _form_nodes(name, min = NOT_DEFINED, max = NOT_DEFINED)
  if name == "fugaku_small"
    min = 1     if min == NOT_DEFINED
    max = 384   if max == NOT_DEFINED
  elsif name == "fugaku_large"
    min = 385   if min == NOT_DEFINED
    max = 12288 if max == NOT_DEFINED
  elsif name == "fugaku_cd_portal"
    min = 1     if min == NOT_DEFINED
    max = 48    if max == NOT_DEFINED
  elsif name == "fugaku_pt_aug" or name == "fugaku_pt_feb"
    min = 1     if min == NOT_DEFINED
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
  return "  - #{name}_nodes\n"
end

def _form_procs(name, min = NOT_DEFINED, max = NOT_DEFINED)
  if name == "fugaku_small"
    min = 1          if min == NOT_DEFINED
    max = 384 * 48   if max == NOT_DEFINED
  elsif name == "fugaku_large"
    min = 385        if min == NOT_DEFINED
    max = 12288 * 48 if max == NOT_DEFINED
  elsif name == "fugaku_cd_portal"
    min = 1          if min == NOT_DEFINED
    max = 48 * 48    if max == NOT_DEFINED
  elsif name == "fugaku_pt_aug" or name == "fugaku_pt_feb"
    min = 1          if min == NOT_DEFINED
    max = 12288 * 48 if max == NOT_DEFINED
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
  return "  - #{name}_procs\n"
end

def _form_cores(name, min = NOT_DEFINED, max = NOT_DEFINED)
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
  return "  - #{name}_cores\n"
end

def _form_memory(name, min = NOT_DEFINED, max = NOT_DEFINED)
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
  return "  - #{name}_memory\n"
end

def _form_fugaku_mode()
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
  return "  - fugaku_mode\n"
end

def _form_fugaku_threads(help = "Number of threads x Total number of processes <= Number of nodes x 48.")
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
  return "  - fugaku_threads\n"
end

def _form_fugaku_statistical_info()
  $attr <<<<"EOF"
  fugaku_statistical_info:
    label: Output statistical information
    widget: select
    options:
    - ["(none)", "none"]
    - ["-s : Output the statistical information", "-s"]
    - ["-S : Output the statistical information containing the node information", "-S"]
EOF
  return "  - fugaku_statistical_info\n"
end

def check_cd_portal()
  return `groups`.split.include?("ra022310")
end

def dashboard_get_fugaku_point(group)
  file = ACC_GROUP_DIR + group + "/fugaku_pt.dat"
  return File.exist?(file)? num_with_commas(File.read(file).chomp) : "0"
end

def check_fugaku_pt_period(month)
  if month == "Aug"
    return Time.now.between?(Time.parse(FUGAKU_PT_AUG_START), Time.parse(FUGAKU_PT_AUG_END))
  elsif month == "Feb"
    return Time.now.between?(Time.parse(FUGAKU_PT_FEB_START), Time.parse(FUGAKU_PT_FEB_END))
  else
    return false
  end
end

def get_fugaku_pt_resource(month, group, w_commas = true)
  file = ACC_GROUP_DIR + group + "/resource.csv"
  if File.exist?(file)
    CSV.foreach(file) do |row|
      if    row[0] == "RESOURCE_GROUP" and row[1] == "pt-Aug" and month == "Aug"
        return (w_commas)? num_with_commas(row[2].to_i/3600) : row[2].to_i/3600
      elsif row[0] == "RESOURCE_GROUP" and row[1] == "pt-Feb" and month == "Feb"
        return (w_commas)? num_with_commas(row[2].to_i/3600) : row[2].to_i/3600
      end
    end
  end
  
  return -1 # for debug
end

def check_fugaku_pt(month)
  return false unless check_fugaku_pt_period(month)
    
  `groups`.split.each do |g|
    return true if get_fugaku_pt_resource(month, g, false) > 0
  end

  return false
end

def form_queue(name, enable_fugaku_threads = true, added_fugaku_queues = [])
  hide_elmts  = ["fugaku-small-hours",     "fugaku-small-nodes",     "fugaku-small-procs", "fugaku-small-free-hours"]
  hide_elmts += ["fugaku-large-hours",     "fugaku-large-nodes",     "fugaku-large-procs", "fugaku-large-free-hours"]
  hide_elmts += ["fugaku-cd-portal-hours", "fugaku-cd-portal-nodes", "fugaku-cd-portal-procs"]
  hide_elmts += ["fugaku-pt-aug-hours",    "fugaku-pt-aug-nodes",    "fugaku-pt-aug-procs"]
  hide_elmts += ["fugaku-pt-feb-hours",    "fugaku-pt-feb-nodes",    "fugaku-pt-feb-procs"]
  hide_elmts += ["fugaku-group", "fugaku-statistical-info", "fugaku-llio", "fugaku-mode"]
  hide_elmts += ["prepost1-hours", "prepost2-hours", "reserved-hours", "gpus-per-node"]
  hide_elmts += ["gpu1-cores",  "gpu2-cores",  "mem1-cores",  "mem2-cores",  "reserved-cores"]
  hide_elmts += ["gpu1-memory", "gpu2-memory", "mem1-memory", "mem2-memory", "reserved-memory"]

  added_fugaku_queues.each do |i|
    ii = i.gsub("_", "-")
    hide_elmts += ["#{ii}-hours", "#{ii}-nodes", "#{ii}-procs"]
  end
  
  show_elmts_small      = ["fugaku-small-hours",      "fugaku-small-nodes",     "fugaku-small-procs",     "fugaku-group", "fugaku-mode", "fugaku-statistical-info"]
  show_elmts_small_free = ["fugaku-small-free-hours", "fugaku-small-nodes",     "fugaku-small-procs",     "fugaku-group", "fugaku-mode", "fugaku-statistical-info"]
  show_elmts_large      = ["fugaku-large-hours",      "fugaku-large-nodes",     "fugaku-large-procs",     "fugaku-group", "fugaku-mode", "fugaku-statistical-info", "fugaku-llio"]
  show_elmts_large_free = ["fugaku-large-hours-free", "fugaku-large-nodes",     "fugaku-large-procs",     "fugaku-group", "fugaku-mode", "fugaku-statistical-info", "fugaku-llio"]
  show_elmts_cd_portal  = ["fugaku-cd-portal-hours",  "fugaku-cd-portal-nodes", "fugaku-cd-portal-procs", "fugaku-group", "fugaku-mode", "fugaku-statistical-info"]
  show_elmts_pt_aug     = ["fugaku-pt-aug-hours",     "fugaku-pt-aug-nodes",    "fugaku-pt-aug-procs",    "fugaku-group", "fugaku-mode", "fugaku-statistical-info", "fugaku-llio"]
  show_elmts_pt_feb     = ["fugaku-pt-feb-hours",     "fugaku-pt-feb-nodes",    "fugaku-pt-feb-procs",    "fugaku-group", "fugaku-mode", "fugaku-statistical-info", "fugaku-llio"]
  show_elmts_gpu1       = ["prepost1-hours", "gpu1-cores", "gpu1-memory", "gpus-per-node"]
  show_elmts_gpu2       = ["prepost2-hours", "gpu2-cores", "gpu2-memory", "gpus-per-node"]
  show_elmts_mem1       = ["prepost1-hours", "mem1-cores", "mem1-memory"]
  show_elmts_mem2       = ["prepost2-hours", "mem2-cores", "mem2-memory"]
  show_elmts_reserverd  = ["reserved-hours", "reserved-cores", "reserved-memory"]

  ret =  "  - cluster\n"
  ret << "  - queue\n"

  $attr <<<<"EOF"
  cluster:
    widget: hidden_field
  queue:
    label: Queue
    widget: select
    options:
EOF

  enable_free_queue = check_free_queue()
  enable_cd_portal  = check_cd_portal()
  enable_pt_aug     = check_fugaku_pt("Aug")
  enable_pt_feb     = check_fugaku_pt("Feb")
  if name == "fugaku_small_and_prepost"
    $attr << output_queue("fugaku-small",      "small",      "fugaku",  hide_elmts - show_elmts_small)
    $attr << output_queue("fugaku-small-free", "small-free", "fugaku",  hide_elmts - show_elmts_small_free) if enable_free_queue
    $attr << output_queue("fugaku-cd-portal",  "cd-portal",  "fugaku",  hide_elmts - show_elmts_cd_portal)  if enable_cd_portal
    $attr << output_queue("fugaku-pt-Aug",     "pt-Aug",     "fugaku",  hide_elmts - show_elmts_pt_aug)     if enable_pt_aug
    $attr << output_queue("fugaku-pt-Feb",     "pt-Feb",     "fugaku",  hide_elmts - show_elmts_pt_feb)     if enable_pt_feb
    added_fugaku_queues.each do |i|
      ii = i.gsub("_", "-")
      $attr << output_queue(i, i, "fugaku", hide_elmts - ["#{ii}-hours", "#{ii}-nodes", "#{ii}-procs"])
    end
    $attr << output_queue("prepost-gpu1",      "gpu1",       "prepost", hide_elmts - show_elmts_gpu1)
    $attr << output_queue("prepost-gpu2",      "gpu2",       "prepost", hide_elmts - show_elmts_gpu2)
    $attr << output_queue("prepost-mem1",      "mem1",       "prepost", hide_elmts - show_elmts_mem1)
    $attr << output_queue("prepost-mem2",      "mem2",       "prepost", hide_elmts - show_elmts_mem2)
    $attr << output_queue("prepost-ondemand-reserved", "ondemand-reserved", "prepost", hide_elmts - show_elmts_reserverd)
    ret << _form_fugaku_group()
    ret << _form_hours("fugaku_small")
    ret << _form_hours("fugaku_small_free")
    ret << _form_nodes("fugaku_small")
    ret << _form_procs("fugaku_small")
    ret << _form_hours("fugaku_cd_portal")
    ret << _form_nodes("fugaku_cd_portal")
    ret << _form_procs("fugaku_cd_portal")
    ret << _form_hours("fugaku_pt_aug")
    ret << _form_nodes("fugaku_pt_aug")
    ret << _form_procs("fugaku_pt_aug")
    ret << _form_hours("fugaku_pt_feb")
    ret << _form_nodes("fugaku_pt_feb")
    ret << _form_procs("fugaku_pt_feb")
    ret << _form_hours("prepost1")
    ret << _form_hours("prepost2")
    ret << _form_hours("reserved")
    ret << _form_cores("gpu1")
    ret << _form_cores("gpu2")
    ret << _form_cores("mem1")
    ret << _form_cores("mem2")
    ret << _form_cores("reserved")
    ret << _form_memory("gpu1")
    ret << _form_memory("gpu2")
    ret << _form_memory("mem1")
    ret << _form_memory("mem2")
    ret << _form_memory("reserved")
    ret << _form_fugaku_threads() if enable_fugaku_threads
    ret << _form_fugaku_mode()
    ret << _form_fugaku_statistical_info()
  elsif name == "fugaku_small"
    $attr << output_queue("fugaku-small",      "small",      "fugaku", hide_elmts - show_elmts_small)
    $attr << output_queue("fugaku-small-free", "small-free", "fugaku", hide_elmts - show_elmts_small_free) if enable_free_queue
    $attr << output_queue("fugaku-cd-portal",  "cd-portal",  "fugaku", hide_elmts - show_elmts_cd_portal)  if enable_cd_portal
    $attr << output_queue("fugaku-pt-Aug",     "pt-Aug",     "fugaku", hide_elmts - show_elmts_pt_aug)     if enable_pt_aug
    $attr << output_queue("fugaku-pt-Feb",     "pt-Feb",     "fugaku", hide_elmts - show_elmts_pt_feb)     if enable_pt_feb
    added_fugaku_queues.each do |i|
      ii = i.gsub("_", "-")
      $attr << output_queue(i, i, "fugaku", hide_elmts - ["#{ii}-hours", "#{ii}-nodes", "#{ii}-procs"])
    end
    ret << _form_fugaku_group()
    ret << _form_hours("fugaku_small")
    ret << _form_hours("fugaku_small_free")
    ret << _form_nodes("fugaku_small")
    ret << _form_procs("fugaku_small")
    ret << _form_hours("fugaku_cd_portal")
    ret << _form_nodes("fugaku_cd_portal")
    ret << _form_procs("fugaku_cd_portal")
    ret << _form_hours("fugaku_pt_aug")
    ret << _form_nodes("fugaku_pt_aug")
    ret << _form_procs("fugaku_pt_aug")
    ret << _form_hours("fugaku_pt_feb")
    ret << _form_nodes("fugaku_pt_feb")
    ret << _form_procs("fugaku_pt_feb")
    ret << _form_fugaku_threads() if enable_fugaku_threads
    ret << _form_fugaku_mode()
    ret << _form_fugaku_statistical_info()
  elsif name == "fugaku_single"
    $attr << output_queue("fugaku-small",      "small",      "fugaku", hide_elmts - show_elmts_small)
    $attr << output_queue("fugaku-small-free", "small-free", "fugaku", hide_elmts - show_elmts_small_free) if enable_free_queue
    $attr << output_queue("fugaku-cd-portal",  "cd-portal",  "fugaku", hide_elmts - show_elmts_cd_portal)  if enable_cd_portal
    $attr << output_queue("fugaku-pt-Aug",     "pt-Aug",     "fugaku", hide_elmts - show_elmts_pt_aug)     if enable_pt_aug
    $attr << output_queue("fugaku-pt-Feb",     "pt-Feb",     "fugaku", hide_elmts - show_elmts_pt_feb)     if enable_pt_feb
    added_fugaku_queues.each do |i|
      ii = i.gsub("_", "-")
      $attr << output_queue(i, i, "fugaku", hide_elmts - ["#{ii}-hours", "#{ii}-nodes", "#{ii}-procs"])
    end
    ret << _form_fugaku_group()
    ret << _form_hours("fugaku_small")
    ret << _form_hours("fugaku_small_free")
    ret << _form_hours("fugaku_pt_aug")
    ret << _form_hours("fugaku_pt_feb")
    ret << _form_fugaku_threads("") if enable_fugaku_threads
    ret << _form_fugaku_mode()
    ret << _form_fugaku_statistical_info()
  elsif name == "fugaku_single_and_prepost"
    $attr << output_queue("fugaku-small",      "small",      "fugaku",  hide_elmts - show_elmts_small)
    $attr << output_queue("fugaku-small-free", "small-free", "fugaku",  hide_elmts - show_elmts_small_free) if enable_free_queue
    $attr << output_queue("fugaku-cd-portal",  "cd-portal",  "fugaku",  hide_elmts - show_elmts_cd_portal)  if enable_cd_portal
    $attr << output_queue("fugaku-pt-Aug",     "pt-Aug",     "fugaku",  hide_elmts - show_elmts_pt_aug)     if enable_pt_aug
    $attr << output_queue("fugaku-pt-Feb",     "pt-Feb",     "fugaku",  hide_elmts - show_elmts_pt_feb)     if enable_pt_feb
    added_fugaku_queues.each do |i|
      ii = i.gsub("_", "-")
      $attr << output_queue(i, i, "fugaku", hide_elmts - ["#{ii}-hours", "#{ii}-nodes", "#{ii}-procs"])
    end
    $attr << output_queue("prepost-gpu1",      "gpu1",       "prepost", hide_elmts - show_elmts_gpu1)
    $attr << output_queue("prepost-gpu2",      "gpu2",       "prepost", hide_elmts - show_elmts_gpu2)
    $attr << output_queue("prepost-mem1",      "mem1",       "prepost", hide_elmts - show_elmts_mem1)
    $attr << output_queue("prepost-mem2",      "mem2",       "prepost", hide_elmts - show_elmts_mem2)
    $attr << output_queue("prepost-ondemand-reserved", "ondemand-reserved", "prepost", hide_elmts - show_elmts_reserverd)
    ret << _form_fugaku_group()
    ret << _form_hours("fugaku_small")
    ret << _form_hours("fugaku_small_free")
    ret << _form_hours("fugaku_cd_portal")
    ret << _form_hours("fugaku_pt_aug")
    ret << _form_hours("fugaku_pt_feb")
    ret << _form_hours("prepost1")
    ret << _form_hours("prepost2")
    ret << _form_hours("reserved")
    ret << _form_cores("gpu1")
    ret << _form_cores("gpu2")
    ret << _form_cores("mem1")
    ret << _form_cores("mem2")
    ret << _form_cores("reserved")
    ret << _form_memory("gpu1")
    ret << _form_memory("gpu2")
    ret << _form_memory("mem1")
    ret << _form_memory("mem2")
    ret << _form_memory("reserved")
    ret << _form_fugaku_threads("") if enable_fugaku_threads
    ret << _form_fugaku_mode()
    ret << _form_fugaku_statistical_info()
  elsif name == "fugaku_small_and_large"
    $attr << output_queue("fugaku-small",      "small",      "fugaku", hide_elmts - show_elmts_small)
    $attr << output_queue("fugaku-small-free", "small-free", "fugaku", hide_elmts - show_elmts_small_free) if enable_free_queue
    $attr << output_queue("fugaku-large",      "large",      "fugaku", hide_elmts - show_elmts_large)
    $attr << output_queue("fugaku-large-free", "large-free", "fugaku", hide_elmts - show_elmts_large_free) if enable_free_queue
    $attr << output_queue("fugaku-cd-portal",  "cd-portal",  "fugaku", hide_elmts - show_elmts_cd_portal)  if enable_cd_portal
    $attr << output_queue("fugaku-pt-Aug",     "pt-Aug",     "fugaku", hide_elmts - show_elmts_pt_aug)     if enable_pt_aug
    $attr << output_queue("fugaku-pt-Feb",     "pt-Feb",     "fugaku", hide_elmts - show_elmts_pt_feb)     if enable_pt_feb
    added_fugaku_queues.each do |i|
      ii = i.gsub("_", "-")
      $attr << output_queue(i, i, "fugaku", hide_elmts - ["#{ii}-hours", "#{ii}-nodes", "#{ii}-procs"])
    end
    ret << _form_fugaku_group()
    ret << _form_hours("fugaku_small")
    ret << _form_hours("fugaku_small_free")
    ret << _form_nodes("fugaku_small")
    ret << _form_procs("fugaku_small")
    ret << _form_hours("fugaku_large")
    ret << _form_hours("fugaku_large_free")
    ret << _form_nodes("fugaku_large")
    ret << _form_procs("fugaku_large")
    ret << _form_hours("fugaku_cd_portal")
    ret << _form_nodes("fugaku_cd_portal")
    ret << _form_procs("fugaku_cd_portal")
    ret << _form_hours("fugaku_pt_aug")
    ret << _form_nodes("fugaku_pt_aug")
    ret << _form_procs("fugaku_pt_aug")
    ret << _form_hours("fugaku_pt_feb")
    ret << _form_nodes("fugaku_pt_feb")
    ret << _form_procs("fugaku_pt_feb")
    ret << _form_fugaku_threads() if enable_fugaku_threads
    ret << _form_fugaku_mode()
    ret << _form_fugaku_statistical_info()
  elsif name == "prepost"
    $attr << output_queue("prepost-gpu1", "gpu1", "prepost", hide_elmts - show_elmts_gpu1)
    $attr << output_queue("prepost-gpu2", "gpu2", "prepost", hide_elmts - show_elmts_gpu2)
    $attr << output_queue("prepost-mem1", "mem1", "prepost", hide_elmts - show_elmts_mem1)
    $attr << output_queue("prepost-mem2", "mem2", "prepost", hide_elmts - show_elmts_mem2)
    $attr << output_queue("prepost-ondemand-reserved", "ondemand-reserved", "prepost", hide_elmts - show_elmts_reserverd)
    ret << _form_hours("prepost1")
    ret << _form_hours("prepost2")
    ret << _form_hours("reserved")
    ret << _form_cores("gpu1")
    ret << _form_cores("gpu2")
    ret << _form_cores("mem1")
    ret << _form_cores("mem2")
    ret << _form_cores("reserved")
    ret << _form_memory("gpu1")
    ret << _form_memory("gpu2")
    ret << _form_memory("mem1")
    ret << _form_memory("mem2")
    ret << _form_memory("reserved")
  elsif name == "gpu"
    $attr << output_queue("prepost-gpu1", "gpu1", "prepost", hide_elmts - show_elmts_gpu1)
    $attr << output_queue("prepost-gpu2", "gpu2", "prepost", hide_elmts - show_elmts_gpu2)
    ret << _form_hours("prepost1")
    ret << _form_hours("prepost2")
    ret << _form_cores("gpu1")
    ret << _form_cores("gpu2")
    ret << _form_memory("gpu1", 10)
    ret << _form_memory("gpu2", 10)
  elsif name == "workflow"
    $attr << output_queue("prepost-ondemand-reserved", "ondemand-reserved", "prepost", hide_elmts - show_elmts_reserverd)
    $attr << output_queue("prepost-gpu1", "gpu1", "prepost", hide_elmts - show_elmts_gpu1)
    $attr << output_queue("prepost-gpu2", "gpu2", "prepost", hide_elmts - show_elmts_gpu2)
    $attr << output_queue("prepost-mem1", "mem1", "prepost", hide_elmts - show_elmts_mem1)
    $attr << output_queue("prepost-mem2", "mem2", "prepost", hide_elmts - show_elmts_mem2)
    ret << _form_hours("prepost1")
    ret << _form_hours("prepost2")
    ret << _form_hours("reserved")
    ret << _form_cores("gpu1", 2, 8)
    ret << _form_cores("gpu2", 2, 8)
    ret << _form_cores("mem1", 2, 8)
    ret << _form_cores("mem2", 2, 8)
    ret << _form_cores("reserved", 2, 8)
    ret << _form_memory("gpu1", 8, 32)
    ret << _form_memory("gpu2", 8, 32)
    ret << _form_memory("mem1", 8, 32)
    ret << _form_memory("mem2", 8, 32)
    ret << _form_memory("reserved", 8, 32)
  else name == "all"
    $attr << output_queue("fugaku-small",      "small",      "fugaku",  hide_elmts - show_elmts_small)
    $attr << output_queue("fugaku-small-free", "small-free", "fugaku",  hide_elmts - show_elmts_small_free) if enable_free_queue
    $attr << output_queue("fugaku-large",      "large",      "fugaku",  hide_elmts - show_elmts_large)
    $attr << output_queue("fugaku-large-free", "large-free", "fugaku",  hide_elmts - show_elmts_large_free) if enable_free_queue
    $attr << output_queue("fugaku-cd-portal",  "cd-portal",  "fugaku",  hide_elmts - show_elmts_cd_portal)  if enable_cd_portal
    $attr << output_queue("fugaku-pt-Aug",     "pt-Aug",     "fugaku",  hide_elmts - show_elmts_pt_aug)     if enable_pt_aug
    $attr << output_queue("fugaku-pt-Feb",     "pt-Feb",     "fugaku",  hide_elmts - show_elmts_pt_feb)     if enable_pt_feb
    added_fugaku_queues.each do |i|
      ii = i.gsub("_", "-")
      $attr << output_queue(i, i, "fugaku", hide_elmts - ["#{ii}-hours", "#{ii}-nodes", "#{ii}-procs"])
    end
    $attr << output_queue("prepost-gpu1",      "gpu1",       "prepost", hide_elmts - show_elmts_gpu1)
    $attr << output_queue("prepost-gpu2",      "gpu2",       "prepost", hide_elmts - show_elmts_gpu2)
    $attr << output_queue("prepost-mem1",      "mem1",       "prepost", hide_elmts - show_elmts_mem1)
    $attr << output_queue("prepost-mem2",      "mem2",       "prepost", hide_elmts - show_elmts_mem2)
    $attr << output_queue("prepost-ondemand-reserved", "ondemand-reserved", "prepost", hide_elmts -show_elmts_reserverd)
    ret << _form_fugaku_group()
    ret << _form_hours("fugaku_small")
    ret << _form_hours("fugaku_small_free")
    ret << _form_nodes("fugaku_small")
    ret << _form_procs("fugaku_small")
    ret << _form_hours("fugaku_large")
    ret << _form_hours("fugaku_large_free")
    ret << _form_nodes("fugaku_large")
    ret << _form_procs("fugaku_large")
    ret << _form_hours("fugaku_cd_portal")
    ret << _form_nodes("fugaku_cd_portal")
    ret << _form_procs("fugaku_cd_portal")
    ret << _form_hours("fugaku_pt_aug")
    ret << _form_nodes("fugaku_pt_aug")
    ret << _form_procs("fugaku_pt_aug")
    ret << _form_hours("fugaku_pt_feb")
    ret << _form_nodes("fugaku_pt_feb")
    ret << _form_procs("fugaku_pt_feb")
    ret << _form_hours("prepost1")
    ret << _form_hours("prepost2")
    ret << _form_hours("reserved")
    ret << _form_cores("gpu1")
    ret << _form_cores("gpu2")
    ret << _form_cores("mem1")
    ret << _form_cores("mem2")
    ret << _form_cores("reserved")
    ret << _form_memory("gpu1")
    ret << _form_memory("gpu2")
    ret << _form_memory("mem1")
    ret << _form_memory("mem2")
    ret << _form_memory("reserved")
    ret << _form_fugaku_threads() if enable_fugaku_threads
    ret << _form_fugaku_mode()
    ret << _form_fugaku_statistical_info()
  end
  
  return ret
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
    return "  - gpus_per_node"
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
  return "  - nodelist"
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
  return "  - #{item}"
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

  return "  - version"
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

  return "  - exec_" + version.delete(".-")
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

  return "  - input_file"
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

  return "  - #{item}"
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

  return "  - input_file_" + prefix
end

def form_output_file(required = true, memo = "")
  memo = "(" + memo + ")" if memo != ""
  
  $attr <<<<"EOF"
  output_file:
    label: Output file #{memo}
    required: #{required.to_s}
EOF
  return "  - output_file"
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
  
  return "  - " + item
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
  return "  - fugaku_llio"
end

def form_options(memo = "")
  $attr <<<<"EOF"
  options:
    label: Options (#{memo})
    widget: text_field
EOF
  return "  - options"
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

  return "  - commands"
end

def form_session_name()
  $attr <<<<"EOF"
  session_name:
    label: Session name
    required: true
EOF
  return "  - session_name"
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

  return "  - email"
end

def form_desktop()
  $attr <<<<"EOF"
  desktop: xfce
EOF
  return "  - desktop"
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

  return "  - #{item}"
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
        ratio = ((usage * 100) / limit).round
        return Resource_info.new(num_with_commas(limit), num_with_commas(usage), num_with_commas(avail), ratio)
      end
    end
  end

  return nil
end

def get_resource_limit(group_name)
  tmp = dashboard_resource(group_name)
  return tmp != nil ? tmp[0].gsub(",", "") : nil
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
        ratio  = ((usage * 100) / limit).round
        info.push(Disk_info.new(volume, num_with_commas(limit), num_with_commas(usage), num_with_commas(avail), ratio))
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
      ratio  = ((usage * 100) / limit).round
      return Disk_info.new(volume, num_with_commas(limit), num_with_commas(usage), num_with_commas(avail), ratio)
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

def ratio(a, b, limit = NOT_USED)
  if b.to_i == 0
    return 0
  else
    if limit != NOT_USED
      v = (a.to_f * 100/ b.to_f)
      return (v < limit)? v.truncate(2) : limit
    else
      return (a.to_f * 100/ b.to_f).truncate(2)
    end
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

def submit_job_name(name)
  return "  job_name: #{name}"
end

def submit_queue_name(name)
  return "  queue_name: #{name}"
end

def submit_gpus_per_node(queue, gpus_per_node)
  return if queue != "gpu1" and queue != "gpu2"

  if gpus_per_node == "0"
    return "  gpus_per_node: 0"
  elsif gpus_per_node == "1" or gpus_per_node == "1_VGL"
    return "  gpus_per_node: 1"
  elsif gpus_per_node == "2" or gpus_per_node == "2_VGL"
    return "  gpus_per_node: 2"
  end
end

def submit_email(email = "", only_start = true)
  if email != ""
    str = "  email: #{email}\n  email_on_started: true\n"
    if only_start
      return str
    else
      return str << "  email_on_terminated: true\n"
    end
  end
end

def submit_added_fugaku_queues(keys = [])
  return NOT_USED if keys == []

  queues = {}
  keys.each do |k|
    k = k.gsub("-", "_")
    queues[k] = {
      "procs" => send("#{k}_procs"),
      "nodes" => send("#{k}_nodes"),
      "hours" => send("#{k}_hours")
    }
  end

  return queues
end

def submit_hours(queue, fugaku_small_hours, fugaku_small_free_hours, fugaku_large_hours, fugaku_large_free_hours,
                 fugaku_cd_portal_hours, fugaku_pt_aug_hours, fugaku_pt_feb_hours, prepost1_hours, prepost2_hours, reserved_hours)

  return fugaku_small_hours      if queue == "small"
  return fugaku_small_free_hours if queue == "small-free"
  return fugaku_large_hours      if queue == "large"
  return fugaku_large_free_hours if queue == "large-free"
  return fugaku_cd_portal_hours  if queue == "cd-portal"
  return fugaku_pt_aug_hours     if queue == "pt-Aug"
  return fugaku_pt_feb_hours     if queue == "pt-Feb"
  return prepost1_hours          if queue == "gpu1" or queue == "mem1"
  return prepost2_hours          if queue == "gpu2" or queue == "mem2"
  return reserved_hours          if queue == "ondemand-reserved"

  return -1 # for debug
end

def submit_nodes(queue, fugaku_small_nodes, fugaku_large_nodes, fugaku_cd_portal_nodes, fugaku_pt_aug_nodes, fugaku_pt_feb_nodes)

  return fugaku_small_nodes     if queue == "small" or queue == "small-free"
  return fugaku_large_nodes     if queue == "large" or queue == "large-free"
  return fugaku_cd_portal_nodes if queue == "cd-portal"
  return fugaku_pt_aug_nodes    if queue == "pt-Aug"
  return fugaku_pt_feb_nodes    if queue == "pt-Feb"

  return -1 # for debug
end

def submit_procs(queue, fugaku_small_procs, fugaku_large_procs, fugaku_cd_portal_procs, fugaku_pt_aug_procs, fugaku_pt_feb_procs)

  return fugaku_small_procs     if queue == "small" or queue == "small-free"
  return fugaku_large_procs     if queue == "large" or queue == "large-free"
  return fugaku_cd_portal_procs if queue == "cd-portal"
  return fugaku_pt_aug_procs    if queue == "pt-Aug"
  return fugaku_pt_feb_procs    if queue == "pt-Feb"

  return -1 # for debug
end

def submit_cores(queue, gpu1_cores, gpu2_cores, mem1_cores, mem2_cores, reserved_cores)

  return gpu1_cores     if queue == "gpu1"
  return gpu2_cores     if queue == "gpu2"
  return mem1_cores     if queue == "mem1"
  return mem2_cores     if queue == "mem2"
  return reserved_cores if queue == "ondemand-reserved"

  return -1 # for debug
end

def submit_memory(queue, gpu1_memory, gpu2_memory, mem1_memory, mem2_memory, reserved_memory)

  return gpu1_memory     if queue == "gpu1"
  return gpu2_memory     if queue == "gpu2"
  return mem1_memory     if queue == "mem1"
  return mem2_memory     if queue == "mem2"
  return reserved_memory if queue == "ondemand-reserved"

  return -1 # for debug
end

def _submit_native_fugaku(queue, hours, nodes, procs, fugaku_group, fugaku_mode, fugaku_statistical_info,
                          fugaku_statistical_path, added_fugaku_queues, added_options)
  ret = "  native:\n"
  if queue == "small" or queue == "small-free" or queue == "large" or queue == "large-free" or queue == "cd-portal" or queue == "pt-Aug" or queue == "pt-Feb"
    ret << "    - -L elapse=#{hours}:00:00,node=#{nodes},jobenv=singularity --mpi proc=#{procs}\n"
  else # For added_fugaku_queues
    # q1 = {"procs" => q1_procs, "nodes" => q1_nodes, "hours" => q1_hours}
    # q2 = {"procs" => q2_procs, "nodes" => q2_nodes, "hours" => q2_hours}
    # added_fugaku_queues = {"q1" => q1, "q2" => q2}

    _queue = queue.gsub("-", "_")
    _hours = added_fugaku_queues[_queue]["hours"]
    _nodes = added_fugaku_queues[_queue]["nodes"]
    _procs = added_fugaku_queues[_queue]["procs"]
    ret << "    - -L elapse=#{_hours}:00:00,node=#{_nodes},jobenv=singularity --mpi proc=#{_procs}\n"
  end
  
  ret << "    - --no-check-directory\n"
  ret << "    - -g #{fugaku_group}\n"
  ret << "    - -x PJM_LLIO_GFSCACHE=/vol0002:/vol0003:/vol0004:/vol0005:/vol0006\n"

  if fugaku_mode == "Boost"
    ret << "    - -L freq=2200\n"
  elsif fugaku_mode == "Eco"
    ret << "    -  -L eco_state=2\n"
  elsif fugaku_mode == "Boost + Eco"
    ret << "    -  -L freq=2200,eco_state=2\n"
  end

  if fugaku_statistical_info == "-s" || fugaku_statistical_info == "-S"
    fugaku_statistical_path = ENV['HOME'] if fugaku_statistical_path == ""
    dir  = File.file?(fugaku_statistical_path) ? File.dirname(fugaku_statistical_path) : fugaku_statistical_path
    file = dir[-1] == '/' ? dir + "%n.%j.stats" : dir + "/%n.%j.stats"
    ret << "    - #{fugaku_statistical_info} --spath #{file}\n"
  end
  
  ret << "    - " + added_options + "\n" if added_options != NOT_USED

  return ret
end

def _submit_native_prepost(queue, hours, cores, memory, nodelist)
  ret =<<"EOF"
  native:
    - "-t"
    - "#{hours}:00:00"
    - "-n"
    - "#{cores}"
    - "--mem"
    - "#{memory}G"
EOF

  ret << "    - \"--nodelist=#{nodelist}\n\"" if nodelist != NOT_USED

  return ret
end

def submit_native(queue, hours, nodes, procs, cores, memory, fugaku_group, fugaku_mode,
                  fugaku_statistical_info, fugaku_statistical_path, nodelist, added_fugaku_queues, added_options)
  if queue == "small" or queue == "small-free" or queue == "large" or queue == "large-free" or queue == "cd-portal" or queue == "pt-Aug" or queue == "pt-Feb" or added_fugaku_queues != NOT_USED
    return _submit_native_fugaku(queue, hours, nodes, procs, fugaku_group, fugaku_mode, fugaku_statistical_info,
                                fugaku_statistical_path, added_fugaku_queues, added_options)
  else
    return _submit_native_prepost(queue, hours, cores, memory, nodelist)
  end
end

def submit_memory(queue, gpu1_memory, gpu2_memory, mem1_memory, mem2_memory, reserved_memory)
  
  return gpu1_memory     if queue == "gpu1"
  return gpu2_memory     if queue == "gpu2"
  return mem1_memory     if queue == "mem1"
  return mem2_memory     if queue == "mem2"
  return reserved_memory if queue == "ondemand-reserved"

  return -1 # for debug
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
