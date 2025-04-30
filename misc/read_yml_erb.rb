# coding: utf-8
require "yaml"
require "erb"

file_path = ARGV[0]
if file_path.nil? || !File.exist?(file_path)
  puts "Not found: #{file_path}"
  exit 1
end

data = YAML.load(ERB.new(File.read(file_path), trim_mode: '-').result(binding))
puts YAML.dump(data)
