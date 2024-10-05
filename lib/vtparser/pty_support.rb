#
# This module can only be included in class which has a parse method to receive the next character read.
# 
module PtySupport

#
# Spawn the given command using PTY::spawn, connect pipes and calls parse for each character read.
#
# Caution: While this command is running, STDIN will be in raw mode.
#
# If a block is given, it will be called for each character read, and the character 
# will be replaced by the block's return value. If nil is returned by block, the character will be dropped. 
#
def spawn(command, &block)

  begin
    PTY.spawn(command) do |stdout_and_stderr, stdin, pid|

      # Input Thread
      input_thread = Thread.new do

        STDIN.raw do |io|
          loop do
            break if pid.nil?
            begin
              if io.wait_readable(0.1)
                data = io.read_nonblock(1024)
                stdin.write data
              end
            rescue IO::WaitReadable
              # No input available right now
            rescue EOFError
              break
            rescue Errno::EIO
              break
            end
          end
        end
      end

      # Pipe stdout and stderr to the parser
      begin

        begin
          winsize = $stdout.winsize
        rescue Errno::ENOTTY
          winsize = [0, 120] # Default to 120 columns
        end
        # Ensure the child process has the proper window size, because 
        #  - tools such as yarn use it to identify tty mode
        #  - some tools use it to determine the width of the terminal for formatting
        stdout_and_stderr.winsize = winsize
        
        stdout_and_stderr.each_char do |char|

          char = block.call(char) if block_given?
          next if char.nil?
          
          # puts Action.inspect_char(char) + "\r\n"  
          # Pass to parser
          parse(char)

        end
      rescue Errno::EIO
        # End of output
      end

      # Wait for the child process to exit
      Process.wait(pid)
      pid = nil
      input_thread.join
      return exit_status = $?.exitstatus

  end

  rescue PTY::ChildExited => e
    puts "The child process exited: #{e}"
  end
end

end