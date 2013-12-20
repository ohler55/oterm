
require 'socket'

module OTerm

  class Server

    attr_accessor :acceptThread
    attr_accessor :stop
    attr_accessor :listeners
    attr_accessor :debug

    def initialize(executor, port=6060, debug=false)
      @debug = debug
      @stop = false
      @listeners = []
      @acceptThread = Thread.start() do
        server = TCPServer.new(port)
        while !stop do
          Thread.start(server.accept()) do |con|
            @listeners << Listener.new(self, con, executor)
          end
        end
      end
    end

    def shutdown()
      @acceptThread.exit()
    end

    def remove_listener(listener)
      @listeners.delete(listener)
    end

  end # Server
end # OTerm
