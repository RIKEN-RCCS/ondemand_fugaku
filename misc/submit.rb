SINGULARITY_DIR        = "/home/apps/singularity/ondemand/"
REMOTE_DESKTOP_AARCH64 = SINGULARITY_DIR + "remote_desktop_ubi87_aarch64.sif"
REMOTE_DESKTOP_X86_64  = SINGULARITY_DIR + "remote_desktop_ubi86_x86_64.sif"
JUPYTER_AARCH64        = SINGULARITY_DIR + "jupyter_ubi87_aarch64.sif"
JUPYTER_X86_64         = SINGULARITY_DIR + "jupyter_ubi86_x86_64.sif"
RSTUDIO_AARCH64        = SINGULARITY_DIR + "rstudio_ubi87_aarch64.sif"
RSTUDIO_X86_64         = SINGULARITY_DIR + "rstudio_ubi86_x86_64.sif"
VSCODE_AARCH64         = SINGULARITY_DIR + "vscode_ubi87_aarch64.sif"
VSCODE_X86_64          = SINGULARITY_DIR + "vscode_ubi86_x86_64.sif"

def submit_gpus_per_node(queue, gpus_per_node)
  return "gpus_per_node: #{gpus_per_node}" if queue == "gpu1" or queue == "gpu2"
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

def submit_native_fugaku(fugaku_hours, fugaku_nodes, fugaku_procs, group, volume, mode)
  str = "native:\n"
  str << "    - \"-L elapse=#{fugaku_hours}:00:00,node=#{fugaku_nodes},jobenv=singularity --mpi proc=#{fugaku_procs} --no-check-directory -g #{group}"

  # volume == "" is set when a group with no data/share directory defined (e.g. rist-a) is set.
  if volume == "/vol0004" or volume == ""
    str << " -x PJM_LLIO_GFSCACHE=/vol0004"
  else
    str << " -x PJM_LLIO_GFSCACHE=/vol0004:#{volume}"
  end
  
  if mode == "Boost"
    str << " -L freq=2200"
  elsif mode == "Eco"
    str << " -L eco_state=2"
  elsif mode == "Boost + Eco"
    str << " -L freq=2200,eco_state=2"
  end

  return str + "\""
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

def submit_native_prepost_core1(queue, prepost1_hours, gpu1_memory, prepost2_hours, gpu2_memory,
                                mem1_memory, mem2_memory, reserved_hours, reserved_memory)
  return submit_native_prepost(queue, prepost1_hours, 1, gpu1_memory, prepost2_hours, 1, gpu2_memory,
                               1, mem1_memory, 1, mem2_memory, reserved_hours, 1, reserved_memory)
end

def submit_native(cluster, fugaku_hours, fugaku_nodes, fugaku_procs, group, volume, mode,
                  queue, prepost1_hours, gpu1_cores, gpu1_memory, prepost2_hours,
                  gpu2_cores, gpu2_memory, mem1_cores, mem1_memory, mem2_cores,
                  mem2_memory, reserved_hours, reserved_cores, reserved_memory)
  if cluster == "fugaku"
    return submit_native_fugaku(fugaku_hours, fugaku_nodes, fugaku_procs, group, volume, mode)
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
    %s
    CTRSCRIPT

    cd ${HOME}
    #{setting_singularity("remote_desktop")}

    chmod +x #{staged_root}/container.sh
    singularity run ${NV_OPTION} ${IMAGE} #{staged_root}/container.sh
EOF
end

def submit_env(threads, app_name, version)
<<"EOF"
#!/usr/bin/env bash
    export OMP_NUM_THREADS=#{threads}
    . /vol0004/apps/oss/spack/share/spack/setup-env.sh
    spack load #{app_name}@#{version}
EOF
end
