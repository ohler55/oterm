#!/usr/bin/env ruby
# encoding: UTF-8

# Ubuntu does not accept arguments to ruby when called using env. To get warnings to show up the -w options is
# required. That can be set in the RUBYOPT environment variable.
# export RUBYOPT=-w

$VERBOSE = true

$: << File.join(File.dirname(__FILE__), "../lib")

require 'oterm'

class Ex < OTerm::Executor

  def greeting()
    "Hello!"
  end

end # Ex

executor = Ex.new()

server = OTerm::Server.new(executor, 6060, true)
server.acceptThread.join()
