require "os"

module Octopoll
  class Watcher
    attr_reader :interval, :repo

    def initialize(token, repo, interval)
      @interval = interval
      @states = {}
      @poll = Octopoll::Poll.new(token)
      @repo = repo
      @initialized = false
    end

    def watch
      while true
        watch_once
      end
    end

    def watch_once
      time = Time.now
      puts "Running at #{time}"

      results = @poll.poll repo
      results.each do |r|
        puts r.to_s
        transition r
      end

      @initialized = true

      sleep @interval
    end

    private

    def transition(result)
      if not @states.has_key? result.number
        @states[result.number] = :pending
      end

      new_state = result.state

      if @initialized
        if @states[result.number] == :pending
          case new_state
          when :success
            notify_success result
          when :failure
            notify_failure result
          when :error
            notify_failure result
          end
        else
          if new_state == :pending
            notify_pending result
          end
        end
      end

      @states[result.number] = new_state
    end

    def notify_handler(result, message, state)
      title = "CI build #{message}"
      message = "##{result.number}: #{result.title}\nAt #{result.date}"
      notify(title, message, state)
    end

    def notify_success(result)
      notify_handler(result, "succeeded", :success)
    end

    def notify_failure(result)
      notify_handler(result, "failed", :failure)
    end

    def notify_pending(result)
      notify_handler(result, "is now pending", :pending)
    end

    def notify(title, message, state)
      if OS.linux?
        `notify-send "#{title}" "#{message}" --urgency #{state_urgency(state)} --expire-time 120000`
      else
        puts "#{title} -- #{message}".send(Octopoll.color(state))
      end
    end

    def state_urgency(state)
      case state
      when :success
        "normal"
      when :failure
        "critical"
      when :error
        "critical"
      else
        "low"
      end
    end
  end
end
