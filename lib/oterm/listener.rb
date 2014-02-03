
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
      @server = server
      @con = con
      @executor = executor
      @buf = ''
      @kill_buf = nil
      @history = []
      @hp = 0
      @out = Output.new(con)
      @col = 0
      @echo = false
      @done = false

      greeting = executor.greeting()
      @out.pl(greeting) unless greeting.nil?

      # initiate negotiations for single character mode and no echo
      @out.p(Telnet.msg(Telnet::DO, Telnet::SGA) + Telnet.msg(Telnet::DO, Telnet::ECHO))

      out.prompt()
      until @done
        line = con.recv(100)
        begin
          len = line.size()
          break if 0 == len
          if server.debug()
            line.each_byte { |x| print("#{x} ") }
            plain = line.gsub(/./) { |c| c.ord < 32 || 127 <= c.ord  ? '*' : c }
            puts "[#{line.size()}] #{plain}"
          end
          # determine input type (telnet command, char mode, line mode)
          o0 = line[0].ord()
          case o0
          when 255 # telnet command
            process_telnet_cmd(line)
          when 27 # escape, vt100 sequence
            vt100_cmd(line)
          when 13 # new line
            exec_cmd(@buf)
          when 0..12, 14..26, 28..31, 127 # other control character
            process_ctrl_cmd(o0)
          else
            if 1 == len || (2 == len && "\000" == line[1] || "\r" != line[-1]) # single char mode
              @hp = 0
              if "\000" == line[1]
                insert(line[0])
              else
                insert(line)
              end
            else # line mode
              exec_cmd(line)
            end
          end
        rescue Exception => e
          puts "#{e.class}: #{e.message}"
          e.backtrace.each { |bline| puts '  ' + bline }
        end
      end
    end

    def close()
      @done = true
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
      if 0 < reply.size
        @con.print(reply)
      else
        # Done negotiating with telnet. Initiate negotiation for vt100 ANSI support.
        @out.identify()
      end
    end

    def vt100_cmd(line)
      # Possible arrow key.
      if 3 == line.size() && '[' == line[1]
        case line[2]
        when 'A' # up arrow
          history_back()
        when 'B' # down arrow
          history_forward()
        when 'C' # right arrow
          move_col(1)
        when 'D' # left arrow
          move_col(-1)
        end
      end
    end

    def exec_cmd(cmd)
      @hp = 0
      cmd.strip!()
      if 0 == cmd.size()
        @out.pl()
        @out.prompt()
        @col = 0
        return
      end
      @buf = ""
      @out.pl()
      @history << cmd if 0 < cmd.size() && (0 == @history.size() || @history[-1] != cmd)
      executor.execute(cmd, self)
      @out.prompt()
      @col = 0
    end

    def process_ctrl_cmd(o)
      case o
      when 1 # ^a
        move_col(-@col)
      when 2 # ^b
        move_col(-1)
      when 4 # ^d
        @hp = 0
        if @col < @buf.size 
          @col += 1
          delete_char()
        end
      when 5 # ^e
        move_col(@buf.size() - @col)
      when 6 # ^f
        move_col(1)
      when 8, 127 # backspace or delete
        @hp = 0
        delete_char()
      when 9 # tab
        @hp = 0
        @executor.tab(@buf, self)
      when 11 # ^k
        @hp = 0
        if @col < @buf.size()
          @kill_buf = @buf[@col..-1]
          blen = @buf.size()
          @buf = @buf[0...@col]
          update_cmd(blen)
        end
      when 14 # ^n
        history_forward()
      when 16 # ^p
        history_back()
      when 21 # ^u
        @hp -= 1
        @buf = ''
      when 25 # ^y
        insert(@kill_buf)
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
      @col = @buf.size
    end

    def move_col(dif)
      if 0 > dif
        while 0 > dif && 0 < @col
          @col -= 1
          @out.p("\b")
          dif += 1
        end
      else
        max = @buf.size
        while 0 < dif && @col < max
          @out.p(@buf[@col])
          @col += 1
          dif -= 1
        end
      end
    end

    def history_back()
      if @hp < @history.size()
        @hp += 1
        blen = @buf.size()
        @buf = @history[-@hp]
        update_cmd(blen)
      end
    end

    def history_forward()
      if 0 < @hp && @hp <= @history.size()
        @hp -= 1
        blen = @buf.size()
        if 0 == @hp
          @buf = ''
        else
          @buf = @history[-@hp]
        end
        update_cmd(blen)
      end
    end

    def insert(str)
      # TBD be smarter with vt100
      if 0 == @col
        @buf = str + @buf
        @out.p("\r")
        @out.prompt()
        @out.p(@buf)
        @out.p("\r")
        @out.prompt()
        @out.p(@buf[0...str.size])
      elsif @buf.size <= @col
        @buf << str
        @out.p(str)
        @col = @buf.size
      else
        @buf = @buf[0...@col] + str + @buf[@col..-1]
        @out.p("\r")
        @out.prompt()
        @out.p(@buf)
        @out.p("\r")
        @out.prompt()
        @out.p(@buf[0...@col + str.size])
      end
      @col += str.size
    end

    def delete_char()
      return if 0 == @col || 0 == @buf.size
      if @buf.size <= @col
        @buf.chop!()
        @out.p("\x08 \x08")
      else
        @buf = @buf[0...@col - 1] + @buf[@col..-1]
        @out.p("\r")
        @out.prompt()
        @out.p(@buf)
        @out.p(" \r")
        @out.prompt()
        @out.p(@buf[0...@col - 1])
      end
      @col -= 1
    end

  end # Listener
end # OTerm
