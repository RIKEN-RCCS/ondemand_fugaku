require 'yaml'
require 'fileutils'

set :erb, :escape_html => true

SAVE_FILE   = Dir.home + "/ondemand/gakunin_rdm.yml"
RDM_API_URL = "https://api.rdm.nii.ac.jp/v2/"

helpers do
  def dashboard_title
    "Open OnDemand"
  end

  def dashboard_url
    "/pun/sys/dashboard/"
  end

  def title
    "GakuNin RDM"
  end
end

def gakunin_exec(params)
  FileUtils.touch(SAVE_FILE)
  FileUtils.chmod(0600, SAVE_FILE)
  data = open(SAVE_FILE, 'r') { |f| YAML.load(f) }
  data = Hash.new if data.nil?
  
  if params != nil then
    if params['act'] == 'mount' then
      unless system("mount | grep #{params['mount_path']}") then
        system("env RDM_API_URL=#{RDM_API_URL} RDM_NODE_ID=#{params['rdm_node_id']} RDM_TOKEN=#{params['rdm_token']} MOUNT_PATH=#{params['mount_path']} /usr/local/sbin/rdmfs_mount.sh &> /dev/null &")
        system("sleep 1")
        d = Hash.new
        d['rdm_node_id'] = params['rdm_node_id']
        d['rdm_token']   = params['rdm_token']
        data[params['mount_path']] = d
        open(SAVE_FILE, 'w') {|f| YAML.dump(data, f) }
      end
    elsif params['act'] == 'unmount' then
      system("fusermount3 -u #{params['mount_path']}")
    elsif params['act'] == 'delete' then
      data.delete(params['mount_path'])
      open(SAVE_FILE, 'w') {|f| YAML.dump(data, f) }
    end
  end
  
  data.each do |k, v|
    # Check if it is mounted correctly
    unless system("ls #{k}") then
      system("fusermount3 -u #{k}")
    end
    real_path = `readlink -f #{k}`.strip
    data[k]['available_action'] = system("mount | grep #{real_path}")? 'unmount' : 'mount'
  end
  
  return data
end

# Define a route at the root '/' of the app.
get '/' do
  @data = gakunin_exec(nil)

  # Render the view
  erb :index
end

post '/' do
  @data = gakunin_exec(params)

  # Render the view
  erb :index
end
