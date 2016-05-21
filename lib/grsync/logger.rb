require 'log4r'
include Log4r

$Log = Logger.new STDOUT
$Log.level = Logger::DEBUG
$Log.formatter = proc do |severity, datetime, progname, msg|
    "[#{severity}] #{datetime} #{progname}: #{msg}\n"
end