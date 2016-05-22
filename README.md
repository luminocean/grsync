# grsync

A tool to synchronize local and remote git repositories' code.

# why

Imagine you are developing a project which requires complicated dependencies like databases, third party plugins and other systems' API. All of them make your project hard to develop and test since you are unlikely to run it on your local machine.

One feasible way is to develop and test on your server with all issues resolved. Of course you can mount remote server's disks onto your local machine, write some code and run your tests right on the server but the performance of those mounted disks probably would drive you crazy.

So the approach grsync takes is try to apply all changes you've make on the local git repository to the remote one. Although these two repositories are (and have to be) same project and on the same branch, they may have different code changed. So all grsync do is to sync remote repository to your local one making all your local changes easily available on the remote side.

# how grsync works

Simple. Diff the local git repository and apply all changes on the remote git repository (and a hard reset is done before apply to avoid weird state).

# usage

Options:
```
  -l, --local=<s>     local source git repository(e.g. /path/to/repo)
  -r, --remote=<s>    remote destination git repository(e.g.
                      username@host:/path/to/repo)
  -p, --passwd=<s>    password for ssh login
  -o, --port=<i>      port for ssh login (default: 22)
  -s, --save          save this synchronization link
  -h, --help          Show this message
```

Example:
`grsync --local /home/tom/myproj --remote allen@remotehost:/projects/myproj --passwd hellowld`

The command above synchronizes remote `allen@remotehost:/projects/myproj` to local `/home/tom/myproj`.
