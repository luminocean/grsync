# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'grsync/version'

Gem::Specification.new do |spec|
    spec.name          = 'grsync'
    spec.version       = GRSync::VERSION
    spec.authors       = ['luminocean']
    spec.email         = ['luminocean@foxmail.com']

    spec.summary       = 'A tool to synchronize local and remote git repositories\' code'
    spec.files         = `git ls-files`.split("\n")
    spec.bindir        = 'bin'
    spec.executables   = ['grsync']
    spec.require_paths = ['lib']
    spec.license       = 'MIT'
    spec.homepage      = 'https://github.com/luminocean/grsync'

    spec.add_dependency 'trollop', '~> 2.1'
    spec.add_dependency 'net-ssh', '~> 3.1'
    spec.add_dependency 'log4r', '~> 1.1'
    spec.add_dependency 'bundler', '~> 1.10'
end
