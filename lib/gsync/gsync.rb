require 'open3'

module GSync
    class Syncer
        # * +ssh+ - ssh object used for issuing commands
        # * +local_path+ - source of the sync link which should be a path of a directory on local machine
        # * +remote_path+ - destination of the sync link which should be a path of a directory on remote machine
        def initialize(ssh, local_path, remote_path)
            @ssh = ssh
            @local_path = local_path # existence should be checked before
            @remote_path = remote_path # existence remains to be checked
        end

        # sync remote git repository with the local one
        def sync
            check_remote_valid
            check_git_repo

            output = @ssh.exec! 'hostname'
            puts output
        end

        private

        # check whether both local and remote directory are git repositories
        # otherwise actions follow will definitely fail
        def check_git_repo
            # check local dir
            old_wd = `pwd`
            stdout, stderr = Open3.popen3("cd #{@local_path} && git status")[1..2]
            `cd #{old_wd}` # go back first

            unless /^On branch/ =~ stdout.gets and stderr.gets.nil?
                raise NotGitRepoException, "local path #{@local_path} is not a git repository"
            end

            # check remote dir
            valid = true
            @ssh.exec!("old_wd=$(pwd);cd #{@remote_path};git status;cd $old_wd") do |ch, stream, data|
                case stream
                    when :stdout
                        valid = false unless data =~ /^On branch/
                    when :stderr
                        valid = false unless (data.nil? or data == '')
                end
            end
            unless valid
                raise NotGitRepoException, "remote path #{@remote_path} is not a git repository"
            end
        end

        # check whether the remote path is valid
        def check_remote_valid
            @ssh.exec!("ls #{@remote_path}") do |ch, stream, data|
                if stream == :stderr and not data.nil?
                    raise RemotePathInvalidException, "remote path #{@remote_path} not found"
                end
            end
        end
    end

    class RemotePathInvalidException < Exception; end
    class NotGitRepoException < Exception; end
end