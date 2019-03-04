require "optparse"
require "bundler/gem_tasks"

task :run do
  ARGV.shift
  sh "ruby -Ilib bin/octopoll " + ARGV.join(" ")
end
