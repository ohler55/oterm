
module OTerm

  class Telnet
    IAC = 255.chr

    # verbs
    WILL = 251.chr
    WONT = 252.chr
    DO   = 253.chr
    DONT = 254.chr

    # features
    BIN  = 0.chr
    ECHO = 1.chr
    SGA  = 3.chr # one character at a time

    def self.msg(verb, feature)
      [IAC, verb, feature].join('')
    end

    def self.parse(line)
      msgs = []
      v = nil
      line.each_char do |c|
        if nil == v
          v = c unless IAC == c
        else
          msgs << [v, c]
          v = nil
        end
      end
      msgs
    end

  end # Telnet
end # OTerm
