require 'fileutils'
CACHE_DIR = "/system/ood/app/"

############
App = Struct.new(:file, :path)

app = []
app.push(App.new("quantum_espresso73", "/vol0004/apps/opt/qe-7.3/bin"))
app.push(App.new("quantum_espresso72", "/vol0004/apps/opt/qe-7.2/bin"))
app.push(App.new("quantum_espresso71", "/vol0004/apps/opt/qe-7.1/bin"))
app.push(App.new("ab2-4", "/vol0004/apps/opt/SPACK-Feb2023-ABINIT-MP-VER2-REV4/bin"))
app.push(App.new("ab1-22", "/vol0004/apps/opt/SPACK-Feb2023-ABINIT-MP-VER1-REV22/bin"))
app.push(App.new("openmx39", "/vol0004/apps/oss/spack-v0.19/opt/spack/linux-rhel8-a64fx/fj-4.8.1/openmx-3.9-j52bvdtvorjy2stvpf7ve2ygxogwjw4n/bin/"))
app.push(App.new("modylas110", "/vol0004/apps/oss/spack-v0.21/opt/spack/linux-rhel8-a64fx/fj-4.10.0/modylas-new-1.1.0-qpbwc72nrq36nszxjpwhhbwjcmgbob33/bin/"))
app.push(App.new("fugaku-frontistr_master", "/vol0004/apps/oss/spack-v0.19/opt/spack/linux-rhel8-a64fx/fj-4.8.1/fugaku-frontistr-master-rqgydh3e5t6ckad7qkjmujzuepde7qza/bin"))
#############

FileUtils.mkdir_p(CACHE_DIR)
app.each do |a|
  bins = []
  a.path.split(":").each do |d|
    d = d + '/' unless d[-1] == '/'
    Dir.foreach(d) do |x|
      bins.push(x) if File.file?(d + x)
    end
  end

  # Create cache
  f = File.open(CACHE_DIR + a.file, 'w')
  f.write(Marshal.dump(bins.sort()))
  f.close()
end
