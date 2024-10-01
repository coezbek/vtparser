require 'pty'
require "tty-prompt" # for winsize call below
require 'rainbow/refinement' # for colorizing output
using Rainbow
require_relative '../lib/vtparser'

# Get the command from ARGV
command = ARGV.join(' ')
if command.empty?
  puts "Usage: ruby indent_cli.rb '<command>'"
  exit 1
end

line_indent = '   ▐  '.yellow
first_line = true
parser = VTParser.new do |action, ch, intermediate_chars, params|
  print line_indent if first_line
  first_line = false

  to_output = VTParser::to_ansi(action, ch, intermediate_chars, params)

  case action
  when :print, :execute, :put, :osc_put
    if ch == "\n" || ch == "\r"
      print ch
      print line_indent
      next
    end
  when :csi_dispatch
    if to_output == "\e[2K"
      print "\e[2K"
      print line_indent
      next
    else
      if ch == 'G'
        # puts "to_output: #{to_output.inspect} action: #{action} ch: #{ch.inspect}"
        # && parser.params.size == 1
        print "\e[#{parser.params[0] + 6}G"

        next
      end
    end
  end

  print to_output
end

begin
  PTY.spawn(command) do |stdout_and_stderr, stdin, pid|

    Thread.new do     
      while pid != nil
        stdin.write(STDIN.readpartial(1024)) # Requires user to press enter!
      end
    rescue => e
      puts "Error: #{e}"
      exit(0)
    end

    begin
      stdout_and_stderr.winsize = $stdout.winsize

      stdout_and_stderr.each_char do |char|

        parser.parse(char)

      end
    rescue Errno::EIO
      # End of output
    end

    # Wait for the child process to exit
    Process.wait(pid)
    pid = nil
    exit_status = $?.exitstatus
    result = exit_status == 0

    # Clear the line, reset the cursor to the start of the line
    print "\e[2K\e[1G"
  end

rescue PTY::ChildExited => e
  puts "The child process exited: #{e}"
end