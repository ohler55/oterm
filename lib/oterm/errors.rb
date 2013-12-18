
module OTerm
  # 
  class CommandError < Exception
    def initialize(cmd)
      super("#{cmd} is not a valid command")
    end
  end # CommandError

end # OTerm
