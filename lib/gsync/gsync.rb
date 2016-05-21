require 'open3'
require 'shellwords'

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
            # preparation
            check_remote_path_valid
            check_git_repo

            diff_text = local_diff
            # puts diff_text

            apply_diff_to_remote diff_text

            # output = @ssh.exec! 'hostname'
            # puts output
        end

        private

        # TODO: make sure this is called after remote is cleaned
        def apply_diff_to_remote(diff_text)
            # be careful, string in ruby may not be used safely in shell directly
            # so here's a conversion
            echoable_text = Shellwords.escape diff_text

            result = @ssh.exec! "cd #{@remote_path} && echo #{echoable_text} | git apply -"
            # diff fails if something other than empty string returns
            raise DiffApplyException, "apply failed: #{result}" if result != ''
        end

        # diff the local git repository and returns the diff text for later use
        def local_diff
            `cd #{@local_path} && git diff`
        end

        # check whether both local and remote directory are git repositories
        # otherwise actions follow will definitely fail
        def check_git_repo
            # check local dir

            # use Open3 in order to get stderr output from child process
            # `` only returns stdout output which is not enough
            # since command are all executed in newly spawned child processes so there's no need to record old dir path
            stdout, stderr = Open3.popen3("cd #{@local_path} && git status")[1..2]

            unless /^On branch/ =~ stdout.gets and stderr.gets.nil?
                raise NotGitRepoException, "local path #{@local_path} is not a git repository"
            end

            # check remote dir
            valid = true
            @ssh.exec!("cd #{@remote_path} && git status") do |ch, stream, data|
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
        def check_remote_path_valid
            @ssh.exec!("ls #{@remote_path}") do |ch, stream, data|
                if stream == :stderr and not data.nil?
                    raise RemotePathInvalidException, "remote path #{@remote_path} not found"
                end
            end
        end
    end

    class RemotePathInvalidException < Exception; end
    class NotGitRepoException < Exception; end
    class DiffApplyException < Exception; end
end