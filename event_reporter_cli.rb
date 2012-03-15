require './event_reporter'
require 'readline'
require 'yaml'

class EventReporterCli
  EXIT_COMMANDS = [:quit, :exit, :q, :e]
  AUTOCOMPLETE_COMMANDS = [
    'queue', 'print', 'load',
    'save', 'clear', 'help',
    'count', 'find', 'add find',
    'subtract find'
  ].sort

  attr_accessor :em

  def initialize
    setup_autocomplete()

    self.em = EventReporter.new()
    at_exit { save_history }
  end

  def run
    load_history

    puts "\nEnter a command (autocomplete & command line history works)"
    while line = readline_with_hist_management.strip
      break if EXIT_COMMANDS.include?(line.to_sym)
      self.em.route_command(line)
    end

    puts 'Good Bye :)'
  end

  private

  def readline_with_hist_management
    line = Readline.readline('> ', true)
    return nil if line.nil?
    if line =~ /^\s*$/ or Readline::HISTORY.to_a[-2] == line
      Readline::HISTORY.pop
    end
    line
  end

  def setup_autocomplete
    comp = proc { |s| AUTOCOMPLETE_COMMANDS.grep( /^#{Regexp.escape(s)}/ ) }

    Readline.completion_append_character = " "
    Readline.completion_proc = comp
  end

  def save_history
    File.open(".history", "w") { |f| f << YAML.dump(Readline::HISTORY.to_a) }
  end

  def load_history
    commands = YAML.load(File.open('.history')) if File.exists?('.history')
    commands.each { |c| Readline::HISTORY.push(c) } if commands
  end

end

cli = EventReporterCli.new()
cli.run()