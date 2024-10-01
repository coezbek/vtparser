#!/usr/bin/env ruby

#
# Helper script to be used to demonstrate `indent_cli.rb`
# 

# See: https://github.com/sindresorhus/cli-spinners/blob/main/spinners.json
frames = [
  "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"
]
interval = 0.08 # 80 milliseconds

# Infinite loop to display the animation until interrupted
loop do
  frames.each do |frame|
    print "\r  #{frame}  " # "\r" moves the cursor back to the start of the line
    sleep(interval)
  end
end
