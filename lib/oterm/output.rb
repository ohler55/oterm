
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
      str = str.gsub("\n", "\n\r")
      @con.print(str)
    end

    def pc(c)
      @con.putc(c)
    end

    def pl(line='')
      line = line.gsub("\n", "\n\r")
      @con.puts(line + "\r")
    end

    def cr()
      @con.print("\r")
    end

  end # Output
end # OTerm

