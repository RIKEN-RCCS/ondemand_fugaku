# coding: utf-8
require 'yaml'
require 'fileutils'
set :erb, :escape_html => true

GFARM_CONF = Dir.home + "/.gfarm2rc"
SAVE_FILE  = Dir.home + "/ondemand/hpci.yml"
JWT_AGENT="jwt-agent -s https://elpis.hpci.nii.ac.jp/ -l"

post '/' do
  # Encrypted communication settings
  unless File.exist?(GFARM_CONF)
    File.open(GFARM_CONF, 'w') { |f| f.write("auth enable sasl_auth *\n") }
  end

  @data = Hash.new
  case params['act']
  when 'mount'
    `echo #{params['pass']} | #{JWT_AGENT} #{params['user']}`
    output = `mount.hpci`
    # The output is "Mount GfarmFS on /tmp/hp120273/hpci003062" or
    # "/tmp/hp120273/hpci003062: already mounted".
    # Extract only the mount path.
    @data['path'] = output.match(/\/tmp\/\S+/)[0].gsub(/:$/, '') if output =~ /\/tmp\/\S+/
    @data['user'] = params['user']
    open(SAVE_FILE, 'w') { |f| YAML.dump(@data, f) }
    @data['next'] = "umount"
  when 'umount'
    `umount.hpci`
    @data = (File.exist?(SAVE_FILE))? open(SAVE_FILE, 'r') { |f| YAML.load(f) } : nil
    @data = nil if @data.empty?
    @data['next'] = "mount" unless @data.nil?
  end
  
  erb :index
end

get '/' do
  if File.exist?(SAVE_FILE)
    @data = open(SAVE_FILE, 'r') { |f| YAML.load(f) }
    unless @data.empty?
      @data['next'] = system("mount | grep #{@data['path']}")? 'umount' : 'mount'
    else
      @data = nil
    end
  else
    @data = nil
  end

  erb :index
end
