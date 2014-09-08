#!/usr/bin/env ruby

require 'bundler/setup'
require 'yaml'
require 'optparse'
require 'hipzap'
require 'keychain'

KEYCHAIN_SERVICE = 'HipZap'
CONFIG_FILES = [ 'hipzap.conf', '.hipzap.conf', '~/.hipzap.conf', ]

config_file = nil
opt_params = {}
opt = OptionParser.new do |opt|
  opt.version = HipZap::VERSION
  opt.on('-f', '--config=FILE', 'specify config file') { |v| config_file = v }
  opt.on('--debug', 'show debug log') { |v| opt_params['debug'] = v }
end

begin
  opt.parse!(ARGV)
rescue OptionParser::ParseError => e
  STDERR.puts "Error: #{e}"
  STDERR.puts opt
  exit 1
end

if config_file
  begin
    params = YAML.load_file(config_file)
  rescue Errno::ENOENT
    STDERR.puts "Error: config file '#{config_file}' not found"
    STDERR.puts opt
    exit 1
  end
else
  CONFIG_FILES.each do |filename|
    begin
      params = YAML.load_file(File.expand_path(filename))
      break
    rescue Errno::ENOENT
      next
    end
  end

  unless params
    STDERR.puts "Error: config file not found"
    STDERR.puts opt
  end
end

config = HipZap::Config.new(params.merge(opt_params))

unless config['jid']
  STDERR.puts "Error: jid not specified."
  exit 1
end

pw = Keychain.generic_passwords.where( service: KEYCHAIN_SERVICE, account: config['jid'] ).first
unless pw
  STDERR.puts "Error: password not registered in keychain."
  exit 1
end

config['password'] = pw.password

HipZap::Colorful.new(config).run
