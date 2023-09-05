require 'yaml'
require 'fileutils'
GFARM_CONF = Dir.home + "/.gfarm2rc"
SAVE_FILE  = Dir.home + "/ondemand/hpci.yml"
HPCI_URL   = "portal.hpci.nii.ac.jp"

class Command
  def exec(params)
    # Encrypted communication settings
    unless File.exist?(GFARM_CONF) then
      File.open(GFARM_CONF, 'w') {|f|
      	f.write("auth enable gsi *\n")
	f.write("auth disable gsi_auth *\n")
      }
    end
    
    FileUtils.touch(SAVE_FILE)
    data = open(SAVE_FILE, 'r') { |f| YAML.load(f) }
    data = Hash.new if data == false
    
    if params != nil then
      if params['act'] == 'mount' then
        system("echo #{params['pass']} | myproxy-logon -s #{HPCI_URL} -l #{params['hpci_id']} -t #{params['time']} -S")
        mount_path = []
        IO.popen("mount.hpci | grep 'Mount GfarmFS on' | grep #{params['hpci_id']} | awk '{print $4}'") do |io|
          io.each_line do |line|
            mount_path << line.chomp
          end
        end

        data.delete(params['hpci_id'])
        d = Hash.new
        d['mount_path'] = mount_path
        d['hpci_id']    = params['hpci_id']
        d['time']       = params['time']
        d['pass']       = params['pass']
        data[params['hpci_id']] = d
        open(SAVE_FILE, 'w') {|f| YAML.dump(data, f) }
      elsif params['act'] == 'unmount' then
        system("umount.hpci")
      elsif params['act'] == 'delete' then
        data.delete(params['hpci_id'])
        open(SAVE_FILE, 'w') {|f| YAML.dump(data, f) }
      end
    end

    data.each do |k, v|
      data[k]['act'] = system("mount | grep #{data[k]['mount_path'][0]}")? 'unmount' : 'mount'
    end

    [data, nil]
  end
end
