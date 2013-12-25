
module OTerm

  class Output < VT100
    def initialize(con)
      super(con)
    end

    def prompt()
      dim()
      @con.print("\r> ")
      attrs_off()
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

