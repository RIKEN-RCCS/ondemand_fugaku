require 'fileutils'
CACHE_DIR = "/system/ood/app/"

############
App = Struct.new(:file, :path)

app = []
app.push(App.new("quantum_espresso72", "/vol0004/apps/opt/qe-7.2/bin"))
app.push(App.new("quantum_espresso71", "/vol0004/apps/opt/qe-7.1/bin"))
app.push(App.new("quantum_espresso68", "/vol0004/apps/opt/qe-6.8/bin"))
app.push(App.new("quantum_espresso67", "/vol0004/apps/opt/qe-6.7/bin"))
#app.push(App.new("quantum_espresso66", "/vol0004/apps/oss/spack-v0.19/opt/spack/linux-rhel8-a64fx/fj-4.8.1/quantum-espresso-6.6-d2bgjxrq6wj4so7wehupzvqkg5u7nk7y/bin/"))
#app.push(App.new("quantum_espresso65", "/vol0004/apps/oss/spack-v0.19/opt/spack/linux-rhel8-a64fx/fj-4.8.1/quantum-espresso-6.5-as6kxmc5wvgscu2xqlsfb6akkbjzf3fz/bin/"))
app.push(App.new("ab2-4", "/vol0004/apps/opt/SPACK-Feb2023-ABINIT-MP-VER2-REV4/bin"))
app.push(App.new("ab1-22", "/vol0004/apps/opt/SPACK-Feb2023-ABINIT-MP-VER1-REV22/bin"))
app.push(App.new("openmx39", "/vol0004/apps/oss/spack-v0.19/opt/spack/linux-rhel8-a64fx/fj-4.8.1/openmx-3.9-j52bvdtvorjy2stvpf7ve2ygxogwjw4n/bin/"))
app.push(App.new("modylas110b", "/vol0004/apps/oss/spack-v0.19/opt/spack/linux-rhel8-a64fx/fj-4.8.1/modylas-new-1.1.0b-sjr6ygmvjq32hkctieja7j6wgl3d7l7p/bin/"))
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
