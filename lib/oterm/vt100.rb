
module OTerm

  class VT100
    ESC = 27.chr
    MAX_DIM = 9999

    # graphic font characters
    BLANK = '_'
    DIAMOND = '`'
    CHECKER = 'a'
    HT = 'b'
    FF = 'c'
    CR = 'd'
    LF = 'e'
    DEGREE = 'f'
    PLUS_MINUS = 'g'
    NL = 'h'
    VT = 'i'
    LOW_RIGHT = 'j'
    UP_RIGHT = 'k'
    UP_LEFT = 'l'
    LOW_LEFT = 'm'
    CROSS = 'n'
    DASH1 = 'o'
    DASH3 = 'p'
    DASH5 = 'q'
    DASH7 = 'r'
    DASH9 = 's'
    LEFT_T = 't'
    RIGHT_T = 'u'
    LOW_T = 'v'
    UP_T = 'w'
    BAR = 'x'
    LTE = 'y'
    GTE = 'z'
    PI = '{'
    NE = '|'
    DOT = '~'

    # colors
    BLACK = 30
    RED = 31
    GREEN = 32
    YELLOW = 33
    BLUE = 34
    MAGENTA = 35
    CYAN = 36
    WHITE = 37

    attr_accessor :con

    def initialize(con)
      @con = con
      @is_vt100 = false
    end

    def is_vt100?()
      return @is_vt100
    end

    def identify()
      @con.print("\x1b[c")
      # expect: ^[[?1;<n>0c
      rx = /^\x1b\[\?1;.+c/
      m = recv_wait(10, 1.0, rx)
      # Don't care about the type, just that the reply is valid for a vt100.
      @is_vt100 = nil != m
    end

    def get_cursor()
      v, h = 0, 0
      if @is_vt100
        @con.print("\x1b[6n")
        # expect: ^[<v>;<h>R
        rx = /^\x1b\[(\d+);(\d+)R/
        m = recv_wait(16, 1.0, rx)
        v, h = m.captures.map { |s| s.to_i }
      end
      return v, h
    end

    # Move cursor to screen location v, h.
    def set_cursor(v, h)
      @con.print("\x1b[#{v};#{h}H") if @is_vt100
    end

    # Save cursor position and attributes.
    def save_cursor()
      @con.print("\x1b7") if @is_vt100
    end

    # Restore cursor position and attributes.
    def restore_cursor()
      @con.print("\x1b8") if @is_vt100
    end

    # Reset terminal to initial state.
    def reset()
      @con.print("\x1bc") if @is_vt100
    end

    def graphic_font()
      @con.print("\x1b(2") if @is_vt100
    end

    def default_font()
      # TBD allow to set to specific character set for original terminal, for now US font
      @con.print("\x1b(B") if @is_vt100
    end

    def clear_screen()
      @con.print("\x1b[2J") if @is_vt100
    end

    def clear_line()
      @con.print("\x1b[2K") if @is_vt100
    end

    def clear_to_end()
      @con.print("\x1b[0K") if @is_vt100
    end

    def clear_to_start()
      @con.print("\x1b[1K") if @is_vt100
    end

    def relative_origin()
      @con.print("\x1b[?6h") if @is_vt100
    end

    def absolute_origin()
      @con.print("\x1b[?6l") if @is_vt100
    end

    def attrs_off()
      @con.print("\x1b[m") if @is_vt100
    end

    def bold()
      @con.print("\x1b[1m") if @is_vt100
    end

    def dim()
      @con.print("\x1b[2m") if @is_vt100
    end

    def underline()
      @con.print("\x1b[4m") if @is_vt100
    end

    def blink()
      @con.print("\x1b[5m") if @is_vt100
    end

    def reverse()
      @con.print("\x1b[7m") if @is_vt100
    end

    def invisible()
      @con.print("\x1b[8m") if @is_vt100
    end

    def big_top()
      @con.print("\x1b#3") if @is_vt100
    end

    def big_bottom()
      @con.print("\x1b#4") if @is_vt100
    end

    def narrow()
      @con.print("\x1b#5") if @is_vt100
    end

    def wide()
      @con.print("\x1b#6") if @is_vt100
    end

    def set_colors(fg, bg)
      return unless @is_vt100
      if nil == fg
        if nil != bg
          bg += 10
          @con.print("\x1b[#{bg}m")
        end
      else
        if nil != bg
          bg += 10
          @con.print("\x1b[#{fg};#{bg}m")
        else
          @con.print("\x1b[#{fg}m")
        end
      end
    end

    def up(n)
      @con.print("\x1b[#{n}A") if @is_vt100
    end

    def down(n)
      @con.print("\x1b[#{n}B") if @is_vt100
    end

    def left(n)
      @con.print("\x1b[#{n}D") if @is_vt100
    end

    def right(n)
      @con.print("\x1b[#{n}C") if @is_vt100
    end

    def home()
      @con.print("\x1b[H") if @is_vt100
    end

    def scroll(n)
      return unless @is_vt100
      if 0 > n
        n = -n
        n.times { @con.print("\x1b[D") }
      elsif 0 < n
        n.times { @con.print("\x1b[M") }
      end
    end

    def screen_size()
      save_cursor()
      set_cursor(MAX_DIM, MAX_DIM)
      h, w = get_cursor()
      restore_cursor()
      return h, w
    end

    def frame(y, x, h, w)
      return if 2 > h || 2 > w
      graphic_font()
      set_cursor(y, x)
      @con.print(UP_LEFT + DASH5 * (w - 2) + UP_RIGHT)
      (h - 2).times do |i|
        i += 1
        set_cursor(y + i, x)
        @con.print(BAR)
        set_cursor(y + i, x + w - 1)
        @con.print(BAR)
      end
      set_cursor(y + h - 1, x)
      @con.print(LOW_LEFT + DASH5 * (w - 2) + LOW_RIGHT)
      default_font()
    end

    def recv_wait(max, timeout, pat)
      giveup = Time.now + timeout
      reply = ''
      begin
        while nil == pat.match(reply)
          # just peek incase the string is not what we want
          reply = @con.recv_nonblock(max, Socket::MSG_PEEK)

          # DEBUG
          # reply.each_byte { |x| print("#{x} ") }
          # plain = reply.gsub(/./) { |c| c.ord < 32 || 127 <= c.ord  ? '*' : c }
          # puts "[#{reply.size()}] #{plain}"

        end
      rescue IO::WaitReadable
        now = Time.now
        if now < giveup
          IO.select([@con], [], [], giveup - now)
          retry
        end
      end
      m = pat.match(reply)
      if nil != m
        # There was a match so read the characters we already peeked.
        cnt = m.to_s().size
        if 0 < cnt
          @con.recv_nonblock(cnt)
        end
      end
      m
    end

  end # VT100
end # OTerm
