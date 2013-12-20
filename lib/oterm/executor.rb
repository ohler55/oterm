
module OTerm

  class Executor

    def initialize()
      @cmds = {}
      register('help', self, :help, '[<command>] this help screen or help on a command',
               %|Show help on a specific command or a list of all commands if a specific command is not specified.|)
      register('shutdown', self, :shutdown, 'shuts down the application',
               %|Shuts down the application.|)
      register('close', self, :close, 'closes the connection',
               %|Closes the connection to the application.|)
    end

    def greeting()
      nil
    end

    def execute(cmd, listener)
      name, args = cmd.split(' ', 2)
      c = @cmds[name]
      if nil == c
        listener.out.pl("#{name} is not a valid command")
        return
      end
      c.target.send(c.op, listener, args)
    end

    def help(listener, arg=nil)
      listener.out.pl()
      if nil != arg
        c = @cmds[arg]
        if nil != c
          listener.out.pl("#{arg} - #{c.summary}")
          c.desc.each do |line|
            listener.out.pl("  #{line}")
          end
          return
        end
      end
      max = 1
      @cmds.each do |name,cmd|
        max = name.size if max < name.size
      end
      @cmds.each do |name,cmd|
        listener.out.pl("  %1$*2$s - %3$s" % [name, -max, cmd.desc])
      end
    end

    def close(listener, args)
      listener.out.pl("Closing connection")
      listener.close()
    end

    def shutdown(listener, args)
      listener.out.pl("Shutting down")
      listener.server.shutdown()
    end

    def register(cmd, target, op, summary, desc)
      @cmds[cmd] = Cmd.new(target, op, summary, desc)
    end

    class Cmd
      attr_accessor :target
      attr_accessor :op
      attr_accessor :summary
      attr_accessor :desc

      def initialize(target, op, summary, desc)
        @target = target
        @op = op
        @summary = summary
        @desc = desc.split("\n")
      end
    end # Cmd

  end # Executor
end # OTerm
