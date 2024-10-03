require 'io/console'
require_relative '../lib/vtparser'

#
# Example for how to switch to raw mode to output infos about each keypress
#
STDIN.raw do |io|

  parser = VTParser.new do |action, ch, intermediate_chars, params|

    puts "  New VTParser action: #{action}, ch: #{ch.inspect}, ch0x: #{ch.ord.to_s(16)}, intermediate_chars: #{intermediate_chars}, params: #{params}\r\n"
    
    parser.to_key(action, ch, intermediate_chars, params) do |event|

      puts "    Keyevent: #{event.to_sym.inspect} #{event.inspect}\r\n"
      exit(1) if event.to_sym == :ctrl_c
    
    end
  end

  loop do
    ch = $stdin.getch
    
    puts "Getch: #{ch.inspect}\r\n"
    parser.parse ch
  end
end
