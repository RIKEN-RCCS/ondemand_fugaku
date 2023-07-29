require 'yaml'
require 'fileutils'
SAVE_DIR  = Dir.home + "/ondemand/"
SAVE_FILE = SAVE_DIR + "gakunin_rdm.yml"

class Command
  @err = nil
  def exec(params)
    save_flag = false
    FileUtils.touch(SAVE_FILE)

    data = open(SAVE_FILE, 'r') { |f| YAML.load(f) }
    data = Hash.new if data == false

    if params != nil then
      if params['act'] == 'mount' then
        if `mount | grep #{params['mount_path']} | wc -l`.strip == '0' then
          `env RDM_API_URL="https://api.rdm.nii.ac.jp/v2/" RDM_NODE_ID=#{params['rdm_node_id']} RDM_TOKEN=#{params['rdm_token']} MOUNT_PATH=#{params['mount_path']} /usr/local/sbin/rdmfs_mount.sh &> /dev/null &`
          `sleep 1`
          data.delete(params['mount_path'])
          d = Hash.new
          d['rdm_node_id'] = params['rdm_node_id']
          d['rdm_token']   = params['rdm_token']
          data[params['mount_path']] = d
          save_flag = true
        end
      elsif params['act'] == 'unmount' then
        `fusermount3 -u #{params['mount_path']}`
      elsif params['act'] == 'delete' then
        data.delete(params['mount_path'])
        save_flag = true
      end
    end

    if save_flag then
      open(SAVE_FILE, 'w') {|f| YAML.dump(data, f) }
    end

    data.each do |k, v|
      real_path    = `readlink -f #{k}`.strip
      mount_action = `mount | grep #{real_path} | wc -l`.strip == '0' ? 'mount' : 'unmount'
      data[k]['available_action'] = mount_action
    end

    [data, @err]
  end
end
