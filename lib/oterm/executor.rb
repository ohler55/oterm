
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
      register('history', self, :history, 'shows command history',
               %|Shows history of commands..|)
    end

    def greeting()
      nil
    end

    def execute(cmd, listener)
      name, args = cmd.split(' ', 2)
      c = @cmds[name]
      if c.nil?
        missing(cmd, listener)
        return
      end
      c.target.send(c.op, listener, args)
    end

    def help(listener, arg=nil)
      listener.out.pl()
      if !arg.nil?
        c = @cmds[arg]
        if !c.nil?
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
        listener.out.pl("  %1$*2$s - %3$s" % [name, -max, cmd.summary])
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

    def history(listener, args)
      i = 1
      listener.history.each do |cmd|
        listener.out.pl("%3d: %s" % [i, cmd])
        i += 1
      end
    end

    # This evaluates cmd as a Ruby expression. This is great for debugging but
    # not a wise move for a public interface. To hide this just create a methid
    # with the same name in the subclass of this one.
    def missing(cmd, listener)
      begin
        result = "#{eval(cmd)}".split("\n")
      rescue Exception => e
        result = ["#{e.class}: #{e.message}"]
        e.backtrace.each do |line|
          break if line.include?('oterm/executor.rb')
          result << "\t" + line
        end
      end
      result.each do |line|
        listener.out.pl(line)
      end
    end

    def tab(cmd, listener)
      comp = []
      @cmds.each_key do |name|
        comp << name if name.start_with?(cmd)
      end
      return if 0 == comp.size

      if 1 == comp.size
        listener.move_col(1000)
        listener.insert(comp[0][listener.buf.size..-1])
        listener.out.prompt()
        listener.out.p(listener.buf)
      else
        listener.out.pl()
        comp.each do |name|
          listener.out.pl(name)
        end
        best = best_completion(cmd, comp)
        if best == cmd
          listener.update_cmd(0)
        else
          listener.move_col(1000)
          listener.insert(best[listener.buf.size..-1])
          listener.out.prompt()
          listener.out.p(listener.buf)
        end
      end
    end

    def register(cmd, target, op, summary, desc)
      @cmds[cmd] = Cmd.new(target, op, summary, desc)
    end

    def best_completion(pre, names)
      plen = pre.size
      # Must make a copy as pre is not frozen.
      pre = String.new(pre)
      target = names[0]
      names = names[1..-1]
      for i in plen..target.size
        c = target[i]
        names.each do |n|
          return pre unless c == n[i]
        end
        pre << c
      end
      pre
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
        if desc.nil?
          @desc = summary
        else
          @desc = desc.split("\n")
        end
      end
    end # Cmd

  end # Executor
end # OTerm
