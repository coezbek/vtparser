#!/usr/bin/env ruby

#
# This script outputs alternating red and green text to demonstrate the color-swapping functionality.
#

# ANSI escape sequences for colors
COLOR_RED = "\e[31m"
COLOR_GREEN = "\e[32m"
RESET_COLOR = "\e[0m"

# Infinite loop to print red and green text alternately
loop do
  print "\r#{COLOR_RED}This is red text#{RESET_COLOR}    "
  sleep 1
  print "\r#{COLOR_GREEN}This is green text#{RESET_COLOR}"
  sleep 1
end
