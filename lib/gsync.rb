#! /usr/bin/env ruby

require 'bundler/setup'
require 'net/ssh'
require 'trollop'

require_relative 'gsync/logger'
require_relative 'gsync/gsync'

# a sample command of gsync is like:
# ./gsync
#   --local ~/document/myrepo
#   --remote username@localhost:/home/username/myrepo
#   --passwd barabara
#   --port 2222

module GSync
    # execution entrance
    if __FILE__ == $0
        # parse arguments
        opts = Trollop::options do
            opt :local, 'local source git repository(e.g. /path/to/repo)', :type => :string
            opt :remote, 'remote destination git repository(e.g. username@host:/path/to/repo)', :type => :string
            opt :passwd, 'password for ssh login', :type => :string
            opt :port, 'port for ssh login', :default => 22
            opt :save, 'save this synchronization link'
        end

        local = opts[:local]
        remote_full = opts[:remote] # location with username, host and path

        # since save feature is unimplemented
        # both local and remote option have to be specified for an explicit synchronization
        Trollop::die :local, 'must be specified' if local.nil?
        Trollop::die :remote, 'must be specified' if remote_full.nil?

        # local dir must exist
        # always check existence asap
        unless Dir.exist?(File.expand_path(local))
            $Log.error "Local directory #{local} doesn't exist"
            abort
        end

        # extract remote, user_name and host from dest_full
        login_str, remote = remote_full.split ':'
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
                syncer = GSync::Syncer.new ssh, local, remote
                syncer.sync
            end
        rescue Net::SSH::AuthenticationFailed
            login_info = {
                host: host,
                user_name: user_name,
                port: port,
                passwd: passwd
            }
            $Log.error "Authentication failed. Please check whether the following login information is correct: #{login_info}"
            abort
        rescue Exception => ex
            $Log.error "#{ex.class.name} -- #{ex}"
            abort
        end
    end
end


