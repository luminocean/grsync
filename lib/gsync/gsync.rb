module GSync
    class Syncer
        # Syncer initializer
        # * +ssh+ - ssh object used for issuing commands
        # * +local_path+ - source of the sync link which should be a directory path on local machine
        # * +remote_path+ - destination of the sync link which should be a directory path on remote machine
        def initialize(ssh, local_path, remote_path)
            @ssh = ssh
            @local_path = local_path # existence should be checked before
            @remote_path = remote_path # existence remains to be checked
        end

        # sync remote git repository with the local one
        def sync
            cd_remote_path
            check_git_repo

            output = exec("hostname")
            puts output
        end

        private

        # shortcut for @ssh.exec!
        def exec(command)
            @ssh.exec! command
        end

        # check whether both local and remote directory are git repositories
        # otherwise actions follow will definitely fail
        def check_git_repo
            # check local dir
            cwd = `pwd`
            test_result = `cd #{@local_path} && git status`
            # TODO: regex validation
        end

        # cd into the remote path
        # return true the remote path is valid otherwise false
        def cd_remote_path
            test_result = exec("cd #{@remote_path}")
            # succeeded cd should return empty string
            # failed cd result would looks something like: [bash: line 0: cd: /ppo: No such file or directory]
            if test_result != ''
                raise RemotePathInvalidException, "remote path #{@remote_path} invalid"
            end
        end
    end

    class RemotePathInvalidException < Exception; end
    class NotGitRepoException < Exception; end
end