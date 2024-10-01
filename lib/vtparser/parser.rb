class VTParser
  attr_reader :intermediate_chars, :params

  def initialize(&block)
    @callback = block
    @state = :GROUND
    @intermediate_chars = ''
    @params = []
    @ignore_flagged = false
    initialize_states
    build_state_transitions
  end

  def parse(data)
    data.each_char do |ch|
      # ch = byte.chr
      do_state_change(ch)
    end
  end

  def initialize_states
    @states = {
      :GROUND => {
        (0x00..0x17) => :execute,
        0x19 => :execute,
        (0x1c..0x1f) => :execute,
        (0x20..0x7f) => :print,
      },
      :ESCAPE => {
        :on_entry => :clear,
        (0x00..0x17) => :execute,
        0x19 => :execute,
        (0x1c..0x1f) => :execute,
        0x7f => :ignore,
        (0x20..0x2f) => [:collect, :ESCAPE_INTERMEDIATE],
        (0x30..0x4f) => [:esc_dispatch, :GROUND],
        (0x51..0x57) => [:esc_dispatch, :GROUND],
        0x59 => [:esc_dispatch, :GROUND],
        0x5a => [:esc_dispatch, :GROUND],
        0x5c => [:esc_dispatch, :GROUND],
        (0x60..0x7e) => [:esc_dispatch, :GROUND],
        0x5b => :CSI_ENTRY,
        0x5d => :OSC_STRING,
        0x50 => :DCS_ENTRY,
        0x58 => :SOS_PM_APC_STRING,
        0x5e => :SOS_PM_APC_STRING,
        0x5f => :SOS_PM_APC_STRING,
      },
      :ESCAPE_INTERMEDIATE => {
        (0x00..0x17) => :execute,
        0x19 => :execute,
        (0x1c..0x1f) => :execute,
        (0x20..0x2f) => :collect,
        0x7f => :ignore,
        (0x30..0x7e) => [:esc_dispatch, :GROUND],
      },
      :CSI_ENTRY => {
        :on_entry => :clear,
        (0x00..0x17) => :execute,
        0x19 => :execute,
        (0x1c..0x1f) => :execute,
        0x7f => :ignore,
        (0x20..0x2f) => [:collect, :CSI_INTERMEDIATE],
        0x3a => :CSI_IGNORE,
        (0x30..0x39) => [:param, :CSI_PARAM],
        0x3b => [:param, :CSI_PARAM],
        (0x3c..0x3f) => [:collect, :CSI_PARAM],
        (0x40..0x7e) => [:csi_dispatch, :GROUND],
      },
      :CSI_PARAM => {
        (0x00..0x17) => :execute,
        0x19 => :execute,
        (0x1c..0x1f) => :execute,
        (0x30..0x39) => :param,
        0x3b => :param,
        0x7f => :ignore,
        0x3a => :CSI_IGNORE,
        (0x3c..0x3f) => :CSI_IGNORE,
        (0x20..0x2f) => [:collect, :CSI_INTERMEDIATE],
        (0x40..0x7e) => [:csi_dispatch, :GROUND],
      },
      :CSI_INTERMEDIATE => {
        (0x00..0x17) => :execute,
        0x19 => :execute,
        (0x1c..0x1f) => :execute,
        (0x20..0x2f) => :collect,
        0x7f => :ignore,
        (0x30..0x3f) => :CSI_IGNORE,
        (0x40..0x7e) => [:csi_dispatch, :GROUND],
      },
      :CSI_IGNORE => {
        (0x00..0x17) => :execute,
        0x19 => :execute,
        (0x1c..0x1f) => :execute,
        (0x20..0x7f) => :ignore,
      },
      :DCS_ENTRY => {
        :on_entry => :clear,
        (0x00..0x17) => :ignore,
        0x19 => :ignore,
        (0x1c..0x1f) => :ignore,
        0x7f => :ignore,
        0x3a => :DCS_IGNORE,
        (0x20..0x2f) => [:collect, :DCS_INTERMEDIATE],
        (0x30..0x39) => [:param, :DCS_PARAM],
        0x3b => [:param, :DCS_PARAM],
        (0x3c..0x3f) => [:collect, :DCS_PARAM],
        (0x40..0x7e) => [:collect, :DCS_PASSTHROUGH], # Changed CÖ so that the final character is collected
      },
      :DCS_PARAM => {
        (0x00..0x17) => :ignore,
        0x19 => :ignore,
        (0x1c..0x1f) => :ignore,
        (0x30..0x39) => :param,
        0x3b => :param,
        0x7f => :ignore,
        0x3a => :DCS_IGNORE,
        (0x3c..0x3f) => :DCS_IGNORE,
        (0x20..0x2f) => [:collect, :DCS_INTERMEDIATE],
        (0x40..0x7e) => [:collect, :DCS_PASSTHROUGH], # Changed CÖ so that the final character is collected
      },
      :DCS_INTERMEDIATE => {
        (0x00..0x17) => :ignore,
        0x19 => :ignore,
        (0x1c..0x1f) => :ignore,
        (0x20..0x2f) => :collect,
        0x7f => :ignore,
        (0x30..0x3f) => :DCS_IGNORE,
        (0x40..0x7e) => [:collect, :DCS_PASSTHROUGH], # Changed CÖ so that the final character is collected
      },
      :DCS_PASSTHROUGH => {
        :on_entry => :hook,
        (0x00..0x17) => :put,
        0x19 => :put,
        (0x1c..0x1f) => :put,
        (0x20..0x7e) => :put,
        0x7f => :ignore,
        :on_exit => :unhook,
      },
      :DCS_IGNORE => {
        (0x00..0x17) => :ignore,
        0x19 => :ignore,
        (0x1c..0x1f) => :ignore,
        (0x20..0x7f) => :ignore,
      },
      :OSC_STRING => {
        :on_entry => :osc_start,
        (0x00..0x17) => :ignore,
        0x19 => :ignore,
        (0x1c..0x1f) => :ignore,
        (0x20..0x7f) => :osc_put,
        :on_exit => :osc_end,
      },
      :SOS_PM_APC_STRING => {
        (0x00..0x17) => :ignore,
        0x19 => :ignore,
        (0x1c..0x1f) => :ignore,
        (0x20..0x7f) => :ignore,
      },
    }

    @anywhere_transitions = {
      0x18 => [:execute, :GROUND],
      0x1a => [:execute, :GROUND],
      (0x80..0x8f) => [:execute, :GROUND],
      (0x91..0x97) => [:execute, :GROUND],
      0x99 => [:execute, :GROUND],
      0x9a => [:execute, :GROUND],
      0x9c => :GROUND,
      0x1b => :ESCAPE,
      0x98 => :SOS_PM_APC_STRING,
      0x9e => :SOS_PM_APC_STRING,
      0x9f => :SOS_PM_APC_STRING,
      0x90 => :DCS_ENTRY,
      0x9d => :OSC_STRING,
      0x9b => :CSI_ENTRY,
    }
  end

  def build_state_transitions
    @state_transitions = {}
    @states.each do |state, transitions|
      expanded_transitions = expand_transitions(transitions)
      anywhere_transitions = expand_transitions(@anywhere_transitions)
      merged_transitions = anywhere_transitions.merge(expanded_transitions) { |_, _, newval| newval }
      on_entry = merged_transitions.delete(:on_entry)
      on_exit = merged_transitions.delete(:on_exit)
      @state_transitions[state] = {
        transitions: merged_transitions,
        on_entry: on_entry,
        on_exit: on_exit,
      }
    end
  end

  def expand_transitions(transitions)
    expanded = {}
    transitions.each do |key, value|
      if key.is_a?(Range)
        key.each do |k|
          expanded[k] = value
        end
      else
        expanded[key] = value
      end
    end
    expanded
  end

  def do_state_change(ch)

    state_info = @state_transitions[@state]
    transitions = state_info[:transitions]
    action_state = transitions[ch.ord]

    action, new_state = nil, nil
    
    if action_state
      if action_state.is_a?(Array)
        action = action_state[0]
        new_state = action_state[1]
      else
        if @states.key?(action_state)
          new_state = action_state
        else
          action = action_state
        end
      end
    else
      action = :ignore
    end
    # pp "before_state: #{@state} action_state: #{action_state} - ch: #{ch} ch0x: #{ch.ord.to_s(16)} - action: #{action} - new_state: #{new_state}"
    # pp "action_state: #{action_state} - ch: #{ch}"
    
    if new_state
      on_exit = state_info[:on_exit]
      handle_action(on_exit, nil) if on_exit
    end
      
    handle_action(action, ch) if action
    
    if new_state
      @state = new_state
      new_state_info = @state_transitions[@state]
      on_entry = new_state_info[:on_entry]
      handle_action(on_entry, nil) if on_entry
    end
  end

  def handle_action(action, ch)
    case action
    when :execute, :print, :esc_dispatch, :csi_dispatch, :hook, :put, :unhook, :osc_start, :osc_put, :osc_end
      @callback.call(action, ch, intermediate_chars, params) if @callback
    when :ignore
      # Do nothing
      @callback.call(action, ch, intermediate_chars, params) if @callback 
    when :collect
      unless @ignore_flagged
        @intermediate_chars << ch
      end
    when :param
      if ch == ';'
        @params << 0
      else
        if @params.empty?
          @params << 0
        end
        @params[-1] = @params[-1] * 10 + (ch.ord - '0'.ord)
      end
    when :clear
      @intermediate_chars = ''
      @params = []
      @ignore_flagged = false
    else
      @callback.call(:error, ch, intermediate_chars, params) if @callback
    end
  end

  def self.to_ansi(action, ch, intermediate_chars, params)
      
    case action
    when :print, :execute, :put, :osc_put, :ignore
      # Output the character
      return ch if ch
    when :hook
      return "\eP#{intermediate_chars}"
    when :esc_dispatch
      return "\e#{intermediate_chars}#{ch}"
    when :csi_dispatch
      # Output ESC [ followed by parameters, intermediates, and final character
      return "\e[#{params.join(';')}#{intermediate_chars}#{ch}"
    when :osc_start
      return "\e]"
    when :osc_end
      return "\x07"  # BEL character to end OSC
    when :unhook
      return "" # \e must come from ESCAPE state
    else
      raise "Unknown action: #{action}"
    end

    raise
  end

end