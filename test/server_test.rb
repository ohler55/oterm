#!/usr/bin/env ruby
# encoding: UTF-8

# Ubuntu does not accept arguments to ruby when called using env. To get warnings to show up the -w options is
# required. That can be set in the RUBYOPT environment variable.
# export RUBYOPT=-w

$VERBOSE = true

$: << File.join(File.dirname(__FILE__), "../lib")

require 'oterm'

class Ex < OTerm::Executor

  def initialize()
    super()
    register('box', self, :box, 'draws a box',
             %|Draws a box at the location described with the dimensions given.
> box <inset> <height> <width>|)
  end

  def greeting()
    "Hello!"
  end

  def box(listener, args)
    o = listener.out
    x = 20
    h = 4
    w = 20
    cy, _ = o.get_cursor()
    (h - cy + 1).times { listener.out.pl() } if cy <= h
    cy, _ = o.get_cursor()
    o.save_cursor()
    o.set_colors(OTerm::VT100::RED, nil)
    o.frame(cy - h, x, h, w)
    o.restore_cursor()
    puts "*** screen size: #{o.screen_size}"
  end

end # Ex

executor = Ex.new()

server = OTerm::Server.new(executor, 6060, true)
server.acceptThread.join()
