require 'set'

#
# Logic taken from vidarh/keyboard_map gem
#
# https://github.com/vidarh/keyboard_map
#
# See examples/keymap.rb for usage
#

class KeyEvent
  attr_reader :modifiers, :key, :args

  def initialize(key, *modifiers, args: nil)
    @key = key
    @args = args
    @modifiers = modifiers.map(&:to_sym).to_set
  end

  def to_s
    (modifiers.to_a.sort << key).join('_')
  end

  def to_sym
    to_s.to_sym
  end

  def ==(other)
    case other
    when KeyEvent
      self.modifiers == other.modifiers && self.key == other.key
    when Symbol
      self.to_sym == other
    else
      self.to_s == other
    end
  end
end

module Keymap

  SINGLE_KEY_EVENT = {
    "\t" => :tab,
    "\r" => :enter,
    "\n" => :enter,
    "\u007F" => :backspace
  }.freeze

  CSI_BASIC_MAP = {
    "A" => :up,
    "B" => :down,
    "C" => :right,
    "D" => :left,
    "E" => :keypad_5,
    "F" => :end,
    "H" => :home,
  }.freeze

  CSI_TILDE_MAP = {
    "1"  => :home,
    "2"  => :insert,
    "3"  => :delete,
    "4"  => :end,
    "5"  => :page_up,
    "6"  => :page_down,
    "15" => :f5,
    "17" => :f6,
    "18" => :f7,
    "19" => :f8,
    "20" => :f9,
    "21" => :f10,
    "23" => :f11,
    "24" => :f12,
  }.freeze

  SS3_KEY_MAP = {
    "P" => :f1,
    "Q" => :f2,
    "R" => :f3,
    "S" => :f4,
  }.freeze
  
  def map_modifiers(mod)
    return [] if mod.nil? || mod < 2
    modifiers = []
    mod = mod - 1  # Subtract 1 to align with modifier bits
    modifiers << :shift if mod & 1 != 0
    modifiers << :alt   if mod & 2 != 0
    modifiers << :ctrl  if mod & 4 != 0
    modifiers
  end

  def to_key(action, ch, intermediate_chars, params, &block)

    case action
    when :execute, :print, :ignore
      # Control characters (e.g., Ctrl+C)
      key = map_control_character(ch)
      yield key if key
    #when :print, :ignore
      # Regular printable characters
      #yield KeyEvent.new(ch)
    when :esc_dispatch
      # ESC sequences without intermediates
      if intermediate_chars == ''
        key = process_esc_sequence(ch)
        yield key if key
      else
        # Handle other ESC sequences if necessary
      end
    when :csi_dispatch
      key = process_csi_sequence(params, intermediate_chars, ch)
      yield key if key
    when :collect, :param, :clear
      # Handled internally; no action needed here
    else
      # Handle other actions if necessary
    end
  end

  def map_control_character(ch)
    if SINGLE_KEY_EVENT.key?(ch)
      return KeyEvent.new(SINGLE_KEY_EVENT[ch])
    elsif ch.ord.between?(0x01, 0x1A)
      # Ctrl+A to Ctrl+Z
      key = (ch.ord + 96).chr
      return KeyEvent.new(key, :ctrl)
    else
      return KeyEvent.new(ch)
    end
  end

  def process_esc_sequence(final_char)
    case final_char
    when 'Z'
      # Shift+Tab
      return KeyEvent.new(:tab, :shift)
    when "\e"
      # Double ESC
      return KeyEvent.new(:esc)
    else
      # Meta key (Alt) combinations
      if final_char.ord.between?(0x20, 0x7E)
        return KeyEvent.new(final_char, :meta)
      else
        # Handle other ESC sequences if necessary
      end
    end
  end

  def process_csi_sequence(params, intermediate_chars, final_char)
    key = nil
    modifiers = []
    params = params.map(&:to_i)

    if intermediate_chars == ''
      if final_char == '~'
        # Sequences like ESC [ 1 ~
        key = CSI_TILDE_MAP[params[0].to_s]
        modifiers = map_modifiers(params[1]) if params.size > 1
      else
        # Sequences like ESC [ A
        key = CSI_BASIC_MAP[final_char]
        modifiers = map_modifiers(params[0]) if params.size > 0
      end
    else
      # Handle intermediates if necessary
    end

    if key
      return KeyEvent.new(key, *modifiers)
    else
      # Handle unrecognized sequences
    end
  end

end