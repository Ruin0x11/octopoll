require "octopoll/version"
require "octopoll/poll"
require "octopoll/watcher"
require "gpgme"
require "byebug"

module Octopoll
  class Error < StandardError; end

  def self.run(token_file, repo, interval)
    crypto = GPGME::Crypto.new
    token = crypto.decrypt File.open(token_file)
    watcher = Octopoll::Watcher.new(token.to_s, repo, interval)
    watcher.watch
    nil
  end
end
