#!/usr/bin/env ruby

require 'optparse'
require 'yaml'

options = {
  local: []
}

# Parse options
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: ssher [options] host\nWhere host is a full hostname or a shortcut defined in .ssh/shortcuts. Options not recognised by SSHer will be passed to SSH.\n"

  opts.on("--local x,y,z", Array, "Ports on server to forward to local") do |list|
    options[:local] = list
  end

  # No argument, shows at tail.  This will print an options summary.
  # Try it and see!
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end

ssh_arguments = []
begin
  optparse.parse! ARGV
rescue OptionParser::InvalidOption => e
  # Ensure unrecognised arguments are saved to be passed to SSH later.
  e.recover ARGV
  ssh_arguments << ARGV.shift
  ssh_arguments << ARGV.shift if ARGV.size>0 and ARGV.first[0..0]!='-'
  retry
end

# We need 1 argument left over
if ARGV.length != 1
  puts optparse
  exit
end

host = ARGV[0]
user = nil
if host.include? "@"
  user = host[0..host.index("@")]
  host = host[host.index("@")+1..-1]
end

shortcuts_file = File.join Dir.home, ".ssh", "shortcuts"

# Check the shortcuts file if it exists.
if File.exists? shortcuts_file
  shortcuts = YAML.load(File.open(shortcuts_file).read)
else
  shortcuts = {}
end

# Attempt to find hostname in shortcuts
host = shortcuts[host] if shortcuts[host]

options[:local].each do |port|
  ssh_arguments << "-L#{port}:127.0.0.1:#{port}"
end

command = "ssh #{ssh_arguments.join(" ")} #{user}#{host}"

puts "Executing #{command}"

exec command
