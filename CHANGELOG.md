## [Unreleased]

## [0.3.0] - 2024-10-05

- Added more examples `colorswap.rb`, `analyze.rb`, `roundtrip.rb`
- Renamed KeyboardEvent to KeyEvent
- Added support for BEL instead of ESC to terminate OSC sequences (xterm uses this)
- Encapsulate action in class Action and added instance methods
- Fixed serialization issue for private mode CSI commands
- Added PtySupport::spawn to easily spawn a command and link stdin/out to the parser
- Switch PTY to `raw` mode to capture keys, disable echo.
- Added support for piping output to files from examples.

## [0.2.0] - 2024-10-03

- Add keyevent handling

## [0.1.0] - 2024-10-01

- Initial release
