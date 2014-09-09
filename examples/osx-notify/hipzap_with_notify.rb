#!/usr/bin/env ruby

require 'bundler/setup'
require 'yaml'
require 'optparse'
require 'hipzap'
require 'terminal-notifier'

KEYCHAIN_SERVICE = 'HipZap'
CONFIG_FILES = [ 'hipzap.conf', '.hipzap.conf', '~/.hipzap.conf', ]

class RendererWithNotify < HipZap::Renderer::Colorful
  def render_room_message(params)
    if ! params[:replay] && @hl_re && params[:body] =~ @hl_re
      TerminalNotifier.notify(params[:body], :title => 'HipZap', :subtitle => params[:sender_nick].to_s + '@' + params[:room_name].to_s)
    end

    super
  end

  def render_dm(params)
    if @hl_re && params[:body] =~ @hl_re
      TerminalNotifier.notify(params[:body], :title => 'HipZap', :subtitle => params[:sender_name].to_s + '@' + params[:room_name].to_s)
    end

    super
  end
end

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

HipZap::Engine.new(config: config, renderer: RendererWithNotify.new(config)).run
