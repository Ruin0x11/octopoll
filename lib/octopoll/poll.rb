require "octokit"
require "colorize"

module Octopoll
  PollResult = Struct.new(:sha, :state, :description, :date)

  PollOverview = Struct.new(:title, :number, :results) do
    def to_s
      s = "##{number} #{title} ".send(Octopoll.color(state))

      bits = results.map { |k, r| Octopoll.bit(r.state) }.join + "\n"
      s << bits

      results.filter { |k, r| r.state == :failure or r.state == :error }.each do |context, r|
        s << "#{context} -- #{r.description} #{r.sha}\n".send(Octopoll.color(r.state))
      end

      s
    end

    def state
      result = :success
      result = :pending if results.any? { |k, r| r.state == :pending }
      result = :failure if results.any? { |k, r| r.state == :failure or r.state == :error }
      result
    end

    def date
      results.map { |k, r| r.date }.max
    end
  end

  def self.bit(state)
    bit = case state
    when :failure
      "F"
    when :error
      "E"
    when :pending
      "P"
    when :success
      "."
    else
      "?"
    end
    bit.send(Octopoll.color(state))
  end

  def self.color(state)
    case state
    when :failure
      :red
    when :error
      :red
    when :pending
      :yellow
    when :success
      :green
    else
      :blue
    end
  end

  class Poll
    attr_reader :token

    def initialize(token)
      @token = token
    end

    def poll(repo_id)
      overviews = []
      prs = client.pull_requests repo_id, state: :open
      prs.each do |pr|
        results = {}
        commits = client.pull_request_commits repo_id, pr.number
        sha = commits.last.sha
        statuses = client.statuses repo_id, sha
        statuses.each do |status|
          add = false
          date = status.updated_at

          if results.has_key? status.context
            add = date > results[status.context].date
          else
            add = true
          end

          if add
            results[status.context] = PollResult.new(sha, status.state.to_sym, status.description, date)
          end
        end
        overviews << PollOverview.new(pr.title, pr.number, results)
      end

      overviews
    end

    private

    def client
      @_client ||= Octokit::Client.new(bearer_token: token, auto_paginate: true)
    end
  end
end
