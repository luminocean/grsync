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
            reset_remote_repo

            diff_text = local_diff
            apply_diff_to_remote diff_text

            # output = @ssh.exec! 'hostname'
            # puts output
        end

        private

        # checkout all files from HEAD to flush all changes made in remote repo
        # thus new git apply can be applied safely :)
        def reset_remote_repo
            @ssh.exec! "cd #{@remote_path} && git reset --hard" do |ch, stream, data|
                if stream == :stderr and data.to_s != '' # check for nil or ''
                    raise GitResetException, "reset failed: #{data}"
                end
            end
        end

        def apply_diff_to_remote(diff_text)
            # be careful, string in ruby may not be used safely in shell directly
            # so here's a conversion
            echoable_text = Shellwords.escape diff_text

            result = @ssh.exec! "cd #{@remote_path} && echo #{echoable_text} | git apply -"
            # diff fails if something other than empty string returns
            raise GitDiffApplyException, "apply failed: #{result}" if result != ''
        end

        # diff the local git repository and returns the diff text for later use
        def local_diff
            `cd #{@local_path} && git diff HEAD`
        end

        # check the followings:
        # 1. whether both local and remote directory are git repositories
        # 2. whether their branches are matched
        def check_git_repo
            # check local dir

            # use Open3 in order to get stderr output from child process
            # `` syntax only returns stdout output which is not enough

            # since command are all executed in newly spawned child processes so there's no need to record old dir path
            stdout, stderr = Open3.popen3("cd #{@local_path} && git status")[1..2]

            local_branch_name = stdout.gets.to_s.match(/^On branch ([^\s]+)/)[1]
            unless local_branch_name
                raise GitRepoException, "local path #{@local_path} is not a git repository"
            end

            # check remote dir
            valid = true
            remote_branch_name = ''
            @ssh.exec!("cd #{@remote_path} && git status") do |ch, stream, data|
                case stream
                    when :stdout
                        valid = false unless (remote_branch_name = data.match(/^On branch ([^\s]+)/)[1])
                    when :stderr
                        valid = false unless (data.nil? or data == '')
                end
            end
            unless valid
                raise GitRepoException, "remote path #{@remote_path} is not a git repository"
            end

            # check match
            if local_branch_name != remote_branch_name
                raise GitRepoException, "local branch(#{local_branch_name}) and remote branch(#{remote_branch_name}) don't match"
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
    class GitRepoException < Exception; end
    class GitDiffApplyException < Exception; end
    class GitResetException < Exception; end
end