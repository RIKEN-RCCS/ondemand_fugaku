# coding: utf-8
IMAGE_AARCH64 = "/home/apps/singularity/ondemand/ubi810_aarch64.sif"
IMAGE_X86_64  = "/home/apps/singularity/ondemand/ubi810_x86_64.sif"
EXCLUDED_GROUPS = ["f-op", "fugaku", "oss-adm", "trial"]

def get_groups()
  groups = `groups`.split - EXCLUDED_GROUPS
  groups.delete_if { |i| i.start_with?("isv") }

  return groups
end

def get_favorites_dirs()
  user = ENV['USER']
  favorites_dirs = [Dir.home]
  
  get_groups().each do |group|
    ["/data", "/share", "/2ndfs"].each do |base|
      dir_user  = File.join(base, group, user)
      dir_group = File.join(base, group)

      if File.directory?(dir_user)
        favorites_dirs << dir_user
      elsif File.directory?(dir_group)
        favorites_dirs << dir_group
      end
    end
  end

  return favorites_dirs
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
    [ -e /var/lib/slurm     ] && export SINGULARITY_BINDPATH=$SINGULARITY_BINDPATH,/var/lib/slurm
    [ -e /var/run/munge     ] && export SINGULARITY_BINDPATH=$SINGULARITY_BINDPATH,/var/run/munge

    if [ `arch` = aarch64 ]; then
      IMAGE=#{IMAGE_AARCH64}
    else
      IMAGE=#{IMAGE_X86_64}
    fi
EOF
end

def output_xfce(prepost_gpus)
  <<"EOF"
#!/usr/bin/env bash
  
cd ${HOME}
  
# Ensure that the user's configured login shell is used
export SHELL="$(getent passwd $USER | cut -d: -f7)"
  
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
for service in "pulseaudio" "rhsm-icon" "spice-vdagent" "tracker-extract" "tracker-miner-apps" "tracker-miner-user-guides" "xfce4-power-manager" "xfce-polkit"; do
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
  sed -i '/^CommandLoginShell=/{h;s/=.*/=TRUE/};${x;/^$/{s//CommandLoginShell=TRUE/;H};x}' "${TERM_CONFIG}"
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
[ -d /usr/local/cuda ] && { [ "#{prepost_gpus}" = "1_VGL" ] || [ "#{prepost_gpus}" = "2_VGL" ]; } && _VIRTUALGL="vglrun -d egl"
EOF
end

def submit_vnc(staged_root)
  <<"EOF"
  template: "vnc"
  websockify_cmd: '/usr/bin/websockify'
  script_wrapper: |
    cat << "CTRSCRIPT" > #{staged_root}/container.sh
    #!/usr/bin/env bash
    unset PYTHONPATH
    export PATH="$PATH:/opt/TurboVNC/bin"
    export PATH="$PATH:/opt/ParaView/bin"
    export PATH="$PATH:/opt/visit/bin"
    export PATH="$PATH:/vol0004/apps/avs_xp851/bin/linux_64_el8"
    export XP_LICENSE_SERVER=fn01sv02
    export PATH="$PATH:/opt/xcrysden/bin"
    export PATH="$PATH:/usr/local/vesta"
    export PATH="$PATH:/opt/smokeview"
    export PATH="$PATH:/opt/ovito/bin"
    export PATH="$PATH:/opt/molden/bin"
    export PATH="$PATH:/usr/local/C-TOOLS062"
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/qt-4.8.6/lib"
    export PATH="$PATH:/usr/local/pymol-2.5.0/bin"
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/pymol-2.5.0/lib64"
    export PATH="$PATH:/opt/ImageJ"
    export PATH="$PATH:/opt/grads/bin"
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/grads/lib"
    export GAUDPT=/opt/grads/udpt
    export GADDIR=/opt/grads/data
    %s
    CTRSCRIPT
    
    #{setting_singularity("desktop")}
    
    chmod +x #{staged_root}/container.sh
    /bin/singularity run ${NV_OPTION} ${IMAGE} #{staged_root}/container.sh
EOF
end

def base_script(job_name, email)
  script = ""
  script << "  job_name: #{job_name}\n" unless job_name.empty?

  unless email.empty?
    script << "  email: #{email}\n"
    script << "  email_on_started: true\n"
  end
  script << "  native:\n"
  
  script
end

def submit_script_prepost(job_name, prepost_queue, prepost_hours, prepost_cores,
                          prepost_memory, prepost_gpus, email, nodelist = "not_specified")

  script = base_script(job_name, email)
  script << "  - -p\n"
  script << "  - #{prepost_queue}\n"
  script << "  - --time=#{prepost_hours}:00:00\n"
  script << "  - --ntasks=#{prepost_cores}\n"
  script << "  - --mem=#{prepost_memory}G\n"
  script << "  - --nodelist=#{nodelist}\n" if nodelist != "not_specified"

  if %w[gpu1 gpu2].include?(prepost_queue)
    if prepost_gpus == "1" || prepost_gpus == "1_VGL"
      script << "  - --gpus-per-node=1\n"
    elsif prepost_gpus == "2" || prepost_gpus == "2_VGL"
      script << "  - --gpus-per-node=2\n"
    end
  end

  script
end

def submit_script_both(job_name, system, fugaku_group, fugaku_queue, fugaku_hours, fugaku_nodes,
                       fugaku_procs, fugaku_mode, prepost_queue, prepost_hours, prepost_cores,
                       prepost_memory, prepost_gpus, email)
  
  script = base_script(job_name, email)

  case system
  when "Fugaku"
    script << "  - -g #{fugaku_group}\n"
    script << "  - -L rscgrp=#{fugaku_queue}\n"
    script << "  - -L elapse=#{fugaku_hours}:00:00,node=#{fugaku_nodes} --mpi proc=#{fugaku_procs}\n"
    script << "  - --no-check-directory\n"
    script << "  - -x PJM_LLIO_GFSCACHE=/vol0002:/vol0003:/vol0004:/vol0005:/vol0006\n"
    script << case fugaku_mode
              when "Boost-Eco"
                "  - -L freq=2200,eco_state=2\n"
              when "Normal"
                "  - -L freq=2000,eco_state=0\n"
              when "Eco"
                "  - -L freq=2000,eco_state=2\n"
              when "Boost"
                "  - -L freq=2200,eco_state=0\n"
              else
                ""
              end
  when "Prepost"
    # job_name and email are already set in base_script(job_name, email).
    script << submit_script_prepost("", prepost_queue, prepost_hours, prepost_cores, prepost_memory, prepost_gpus, "")
  end

  script
end
