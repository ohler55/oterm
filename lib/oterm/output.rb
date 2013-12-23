
module OTerm

  class Output < VT100
    def initialize(con)
      super(con)
    end

    def prompt()
      @con.print("\r> ")
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

