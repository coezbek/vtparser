# spec/vtparser_spec.rb

require 'rspec'
require_relative '../lib/vtparser.rb'  # Adjust the path as necessary

RSpec.describe VTParser do
  let(:output) { '' }
  let(:parser) do
    VTParser.new do |action, ch, intermediate_chars, params|

      # puts "action: #{action}, ch: #{ch}, intermediate_chars: #{parser_instance.intermediate_chars}, params: #{parser_instance.params}"
      
      output << VTParser::to_ansi(action, ch, intermediate_chars, params)
  
    end
  end

  describe 'Parsing ANSI color codes' do
    it 'parses foreground color code (red)' do
      input = "\e[31mHello World\e[0m"
      parser.parse(input)
      expect(output).to eq(input)
    end

    it 'parses background color code (green background)' do
      input = "\e[42mHello World\e[0m"
      parser.parse(input)
      expect(output).to eq(input)
    end

    it 'parses bold text' do
      input = "\e[1mBold Text\e[0m"
      parser.parse(input)
      expect(output).to eq(input)
    end

    it 'parses multiple attributes' do
      input = "\e[1;31mBold Red Text\e[0m"
      parser.parse(input)
      expect(output).to eq(input)
    end
  end

  describe 'Parsing cursor movement codes' do
    it 'parses cursor up' do
      input = "\e[2A"  # Move cursor up 2 lines
      parser.parse(input)
      expect(output).to eq(input)
    end

    it 'parses cursor down' do
      input = "\e[3B"  # Move cursor down 3 lines
      parser.parse(input)
      expect(output).to eq(input)
    end

    it 'parses cursor forward' do
      input = "\e[5C"  # Move cursor forward 5 columns
      parser.parse(input)
      expect(output).to eq(input)
    end

    it 'parses cursor backward' do
      input = "\e[4D"  # Move cursor backward 4 columns
      parser.parse(input)
      expect(output).to eq(input)
    end

    it 'parses cursor position' do
      input = "\e[10;20H"  # Move cursor to row 10, column 20
      parser.parse(input)
      expect(output).to eq(input)
    end

    it 'parses save and restore cursor position' do
      input = "\e7Saved Position\e8Restored Position"
      parser.parse(input)
      expect(output).to eq(input)
    end
  end

  describe 'Parsing line clear codes' do
    it 'parses clear to end of line' do
      input = "Line Content\e[K"
      parser.parse(input)
      expect(output).to eq(input)
    end

    it 'parses clear from beginning to cursor' do
      input = "Line Content\e[1K"
      parser.parse(input)
      expect(output).to eq(input)
    end

    it 'parses clear entire line' do
      input = "Line Content\e[2K"
      parser.parse(input)
      expect(output).to eq(input)
    end
  end

  describe 'Parsing screen clear codes' do
    it 'parses clear screen' do
      input = "\e[2J"
      parser.parse(input)
      expect(output).to eq(input)
    end

    it 'parses clear from cursor to end of screen' do
      input = "\e[J"
      parser.parse(input)
      expect(output).to eq(input)
    end

    it 'parses clear from cursor to beginning of screen' do
      input = "\e[1J"
      parser.parse(input)
      expect(output).to eq(input)
    end
  end

  describe 'Parsing OSC sequences' do
    it 'parses set window title' do
      input = "\e]0;My Window Title\x07"
      parser.parse(input)
      expect(output).to eq(input)
    end

    it 'parses set icon name' do
      input = "\e]1;My Icon Name\x07"
      parser.parse(input)
      expect(output).to eq(input)
    end
  end

  describe 'Parsing ESC sequences' do
    it 'parses device control string' do
      input = "\x1bP$q\"q\x1b\\" # "\ePThis is a DCS\e\\"
      parser.parse(input)
      expect(output).to eq(input)
    end

    it 'parses string terminator' do
      input = "\e\\"
      parser.parse(input)
      expect(output).to eq(input)
    end

    it 'parses start of string' do
      input = "\e]"
      parser.parse(input)
      expect(output).to eq(input)
    end
  end

  describe 'Parsing Unicode characters' do
    it 'parses basic multilingual plane characters' do
      input = "Hello, 世界"  # "Hello, World" in Chinese
      parser.parse(input)
      expect(output).to eq(input)
    end

    it 'parses extended characters' do
      input = "Currency: €"  # Euro sign
      parser.parse(input)
      expect(output).to eq(input)
    end

    it 'parses emoji characters' do
      input = "Emoji: 😀🎉"
      parser.parse(input)
      expect(output).to eq(input)
    end

    it 'parses combining characters' do
      input = "Combining: áö"  # 'a' with acute, 'o' with diaeresis
      parser.parse(input)
      expect(output).to eq(input)
    end
  end

  describe 'Mixed content' do
    it 'parses text with escape sequences and Unicode characters' do
      input = "\e[1;34mBlue Bold Text\e[0m and normal text with unicode 😀"
      parser.parse(input)
      expect(output).to eq(input)
    end

    it 'parses multiple escape sequences in text' do
      input = "\e[31mRed\e[0m, \e[32mGreen\e[0m, \e[34mBlue\e[0m"
      parser.parse(input)
      expect(output).to eq(input)
    end

    it 'parses cursor movements and text' do
      input = "Line1\e[2AUp Two Lines\e[2BDown Two Lines"
      parser.parse(input)
      expect(output).to eq(input)
    end
  end
end
