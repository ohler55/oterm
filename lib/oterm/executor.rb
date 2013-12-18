
module OTerm

  class Executor

    def initialize()

    end

    def greeting()
      nil
    end

    def execute(cmd, listener)
      listener.out.pl("#{cmd} is not a valid command")
    end

    def help(listener)
      listener.out.pl()
      listener.out.pl("there is no help for you")
    end

  end # Executor
end # OTerm


