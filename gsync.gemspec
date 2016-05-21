# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gsync/version'

Gem::Specification.new do |spec|
    spec.name          = 'gsync'
    spec.version       = GSync::VERSION
    spec.authors       = ['luminocean']
    spec.email         = ['luminocean@foxmail.com']

    spec.summary       = 'development code synchronization tool'
    spec.files         = `git ls-files`.split("\n")
    spec.bindir        = 'bin'
    spec.executables   = ['gsync']
    spec.require_paths = ['lib']
    spec.license       = 'MIT'
    spec.homepage      = 'https://github.com/luminocean/gsync'

    spec.add_dependency 'trollop', '~> 2.1'
    spec.add_dependency 'net-ssh', '~> 3.1'
    spec.add_dependency 'log4r', '~> 1.1'

    spec.add_development_dependency 'bundler', '~> 1.10'
end
