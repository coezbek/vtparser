#!/usr/bin/env ruby

#
# Helper script to be used to demonstrate `indent_cli.rb`. It displays a full-width animated progress bar.
# 

require 'ruby-progressbar'

# Hide the cursor
print "\e[?25l"

loop do
  progressbar = ProgressBar.create
  99.times { 
    progressbar.increment 
    sleep 0.02
  }
  print "\r"
end
