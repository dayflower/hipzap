require 'bundler/setup'
require 'optparse'
require 'fiddle/import'
require 'keychain'

KEYCHAIN_SERVICE = 'HipZap'

module LibC
  extend Fiddle::Importer
  dlload 'libc.dylib'
  extern 'char *getpass(const char *prompt)'
end

config = {}
banner = "Usage: #{File.basename($0)} [options] <Jabber ID>"
opt = OptionParser.new(banner) do |opt|
  opt.on('-u', '--update', 'update password') { |v| config[:update] = v }
  opt.on('-r', '--remove', 'remove password') { |v| config[:remove] = v }
  opt.on_tail('-h', '--help', 'show this help message') { |v|
    puts opt
    exit
  }
end
begin
  opt.parse!(ARGV)
rescue OptionParser::ParseError => e
  STDERR.puts "Error: #{e}"
  STDERR.puts opt
  exit 1
end

jid = ARGV.shift

unless jid
  STDERR.puts "Error: argument jid required."
  STDERR.puts opt
  exit 1
end

old = Keychain.generic_passwords.where( service: KEYCHAIN_SERVICE, account: jid ).first

if config[:remove]
  old.delete if old
  STDERR.puts "Successfully removed"
  exit
end

if config[:update]
  old.delete if old
end

password = LibC.getpass('Password: ').to_s

begin
  Keychain.generic_passwords.create service: KEYCHAIN_SERVICE, account: jid, password: password
  STDERR.puts "Successfully created (or updated)."
rescue Keychain::DuplicateItemError
  STDERR.puts "Error: already password stored.  use --update flag to overwrite."
  exit 1
end
