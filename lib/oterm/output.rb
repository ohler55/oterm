
module OTerm

  class Output
    attr_accessor :con

    def initialize(con)
      @con = con
    end

    def prompt()
      @con.print('> ')
    end

    def p(str)
      @con.print(str)
    end

    def pc(c)
      @con.putc(c)
    end

    def pl(line='')
      @con.puts(line + "\r")
    end

    def cr()
      @con.print("\r")
    end

  end # Output
end # OTerm

