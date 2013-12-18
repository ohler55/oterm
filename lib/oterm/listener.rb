
module OTerm

  class Listener

    attr_accessor :server
    attr_accessor :con
    attr_accessor :executor
    attr_accessor :buf
    attr_accessor :history
    attr_accessor :hp # history pointer
    attr_accessor :out
    attr_accessor :debug

    def initialize(server, con, executor)
      @debug = server.debug()
      @server = server
      @con = con
      @executor = executor
      @buf = ""
      @history = []
      @hp = 0
      @out = Output.new(con)
      @echo = false
      @done = false

      greeting = executor.greeting()
      @out.pl(greeting) if nil != greeting

      # initiate negotiations for single character mode and no echo
      @out.p(Telnet.msg(Telnet::DO, Telnet::SGA) + Telnet.msg(Telnet::DO, Telnet::ECHO))

      out.prompt()
      while !@done
        line = con.recv(100)
        begin
          len = line.size()
          break if 0 == len
          if @debug
            # TBD better display of line with hex, length, and ascii with control characters replaced
            line.each_byte { |x| print("#{x} ") }
            puts "[#{line.size()}]"
          end
          # determine input type (telnet command, char mode, line mode)
          o0 = line[0].ord()
          case o0
          when 255 # telnet command
            process_telnet_cmd(line)
          when 27 # escape, vt100 sequence
            vt100_cmd(line)
          when 13 # new line
            @hp = 0
            cmd = buf.strip()
            if 0 == cmd.size()
              @out.pl()
              @out.prompt()
              next
            end
            @buf = ""
            @out.pl()
            @history << cmd if 0 < cmd.size() && (0 == @history.size() || @history[-1] != cmd)
            executor.execute(cmd, self)
            @out.prompt()
          when 0..12, 14..26, 28..31, 127 # other control character
            process_ctrl_cmd(o0)
          when 63 # ?
            @hp = 0
            @executor.help(self)
            update_cmd(0)
          else
            if 1 == len || (2 == len && "\000" == line[1]) # single char mode
              @hp = 0
              @out.pc(line[0])
              @buf << line[0]
            else # line mode
            end
          end
        rescue Exception => e
          # TBD change to output to a logger instead
          puts "** #{e.class}: #{e.message}"
        end
      end
    end

    def process_telnet_cmd(line)
      reply = ''
      Telnet.parse(line).each do |v,f|
        case f
        when Telnet::ECHO
          case v
          when Telnet::WILL
            @echo = false
            reply += Telnet.msg(Telnet::WONT, f)
          when Telnet::WONT
            @echo = true
            reply += Telnet.msg(Telnet::WILL, f)
          end
        when Telnet::SGA
          case v
          when Telnet::WILL
            reply += Telnet.msg(Telnet::WILL, f)
          when Telnet::WONT
            reply += Telnet.msg(Telnet::WONT, f)
          end
        end
      end
      @con.print(reply) if 0 < reply.size
    end

    def vt100_cmd(line)
    end

    def process_ctrl_cmd(o)
      case o
      when 4
        @con.close()
        @done = true
      when 8, 127 # backspace or delete
        @hp = 0
        if 0 < @buf.size()
          @buf.chop!()
          @out.p("\x08 \x08")
        end
      when 9 # tab
        @hp = 0
        # TBD completions
      when 14 # ^n
        if 0 < @hp && @hp <= @history.size()
          @hp -= 1
          blen = @buf.size()
          if 0 == @hp
            @buf = ""
          else
            @buf = @history[-@hp]
          end
          update_cmd(blen)
        end
      when 16 # ^p
        if @hp < @history.size()
          @hp += 1
          blen = @buf.size()
          @buf = @history[-@hp]
          update_cmd(blen)
        end
      end
    end

    def update_cmd(blen)
      @out.cr()
      @out.prompt()
      @out.p(@buf)
      # erase to end of line and come back
      if @buf.size() < blen
        dif = blen - @buf.size()
        @out.p(' ' * dif + "\b" * dif)
      end
    end

  end # Listener
end # OTerm
