#! /usr/bin/env ruby

require 'bundler/setup'
require 'net/ssh'
require 'trollop'

require_relative 'gsync/logger'
require_relative 'gsync/gsync'

# a sample command of gsync is like:
# ./gsync
#   --source ~/document/myrepo
#   --destination username@localhost:/home/username/myrepo
#   --passwd barabara
#   --port 2222

module GSync
    # execution entrance
    if __FILE__ == $0
        # parse arguments
        opts = Trollop::options do
            opt :src, 'source git repository', :type => :string
            opt :dest, 'synchronization destination', :type => :string
            opt :passwd, 'password for ssh login', :type => :string
            opt :port, 'port for ssh login', :default => 22
            opt :save, 'save this synchronization link'
        end

        src = opts[:src]
        dest_full = opts[:dest] # location with username, host and path

        # since save feature is unimplemented
        # both src and dest option have to be specified for an explicit link
        Trollop::die :src, 'must be specified' if src.nil?
        Trollop::die :dest, 'must be specified' if dest_full.nil?

        # src dir must exist
        # always check existence asap
        unless Dir.exist?(src)
            $Log.error "Source directory #{src} doesn't exist"
            abort
        end

        # extract dest, user_name and host from dest_full
        login_str, dest = dest_full.split ':'
        if login_str.split('@').size == 2
            user_name, host = login_str.split('@')
        else
            host = login_str
            user_name = nil
        end

        # optional options for login
        passwd = opts[:passwd] || ''
        port = opts[:port]

        # ssh login
        begin
            Net::SSH.start(host, user_name, :password => passwd, :port => port) do |ssh|
                syncer = GSync::Syncer.new ssh, src, dest
                syncer.sync
            end
        rescue Net::SSH::AuthenticationFailed
            login_info = {
                user_name: user_name,
                port: port,
                passwd: passwd
            }
            $Log.error "Authentication failed. Please check whether the following login information is correct: #{login_info}"
            abort
        rescue Exception => ex
            $Log.error "#{ex}"
            abort
        end
    end
end


