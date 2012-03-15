require 'csv'
require './attendee.rb'
require 'yaml'
require 'json'
require 'ruby-debug'

class EventReporter
  CSV_OPTIONS = {:headers => true, :header_converters => :symbol}
  HEADERS = [:last_name, :first_name, :email_address, :zipcode, :city, :state, 
    :homephone, :street]
  ALLOWED_COMMANDS = [:load, :help, :queue, :find, :add, :subtract]
  attr_accessor :attendees, :queue_attendees, :header_lengths

  def route_command(cmd)
    if cmd
      args = cmd.split(" ")
      method = public_methods(false).grep(/^#{args[0]}$/) if cmd
      method << "undefined_command" if method.length == 0
      self.send(method[0].to_sym, args)
    end
  end

  def load(cmd)
    filename = cmd[1] || "event_attendees.csv"
    if File.exists?(filename)
      self.attendees = load_attendees(CSV.open(filename, CSV_OPTIONS))
    else
      puts "File doesn't exist - '#{filename}'"
    end
  end

  def help(cmd)
    help_for = cmd[1..-1]
    help_for << "general" if help_for.empty?
    details = YAML.load(File.open('help.yaml'))[help_for.join("_")]

    if details
      puts details
    else
      puts "Invalid help command '#{help_for.join(" ")}'"
    end
  end

  def queue(cmd)
    return queue_count() if cmd[1] == "count"
    return queue_clear() if cmd[1] == "clear"
    return queue_print_by(cmd) if cmd[1] == "print" and cmd[2] == "by"
    return queue_print(cmd) if cmd[1] == "print"
    return queue_save(cmd) if cmd[1] == "save"
  end

  def find(cmd)
    attribute = (cmd[1] || "").downcase.to_sym
    value = cmd[2] || ""

    if self.attendees and HEADERS.include?(attribute) and value
      self.queue_attendees = attendees.find_all do |attendee|
        attendee.send(attribute) =~ /^#{value.strip}$/i
      end
    end
  end

  def add(cmd)
    if self.attendees
      temp = self.queue_attendees || []
      find(cmd[1..-1])
      self.queue_attendees = self.queue_attendees | temp
    end
  end

  def subtract(cmd)
    if self.queue_attendees
      temp = self.queue_attendees
      find(cmd[1..-1])
      self.queue_attendees = temp - self.queue_attendees
    end
  end

  private

  def load_attendees(file)
    self.attendees = file.collect { |line| Attendee.new(line) }
  end

  def queue_print(cmd)
    print(self.queue_attendees) if self.queue_attendees
  end

  def queue_print_by(cmd)
    attribute = (cmd[3] || "").to_sym

    if HEADERS.include?(attribute) and self.queue_attendees
      list = self.queue_attendees.sort_by do |x|
        (x.send(attribute) || "").downcase
      end

      print(list)
    end
  end

  def compute_headers_lengths()
    self.header_lengths = {}

    HEADERS.each do |attribute|
      value = attendees.max_by do
        |x| (x.send(attribute).to_s || "").length 
      end
      length = value.send(attribute).to_s.length

      length = attribute.length if length < attribute.length
      self.header_lengths[attribute] = length
    end
  end

  def print_headers()
    headers = ""

    HEADERS.each do |attribute|
      headers += attribute.to_s.gsub("_", " ").upcase
        .ljust(self.header_lengths[attribute]) + " "
    end

    puts headers
  end

  def print(attendees)
    if attendees and attendees.length > 0
      compute_headers_lengths()
      print_headers()

      attendees.each_with_index do |attendee, index|
        items = HEADERS.collect do |attribute|
          "#{(attendee.send(attribute).to_s || "")
            .ljust(self.header_lengths[attribute])}"
        end
        puts items.join(" ")
        get_empty_input() if (index+1) % 10 == 0
      end
    end
  end

  def queue_clear()
    puts self.queue_attendees.clear if self.queue_attendees
  end

  def queue_count()
    puts self.queue_attendees ? self.queue_attendees.count : 0
  end

  def queue_save(cmd)
    filename = cmd[3]
    type = cmd[3].split(".")[-1] || "csv"

    return queue_save_csv(filename) if type == "csv"
  end

  def queue_save_csv(filename)
    self.queue_attendees ||= []
    CSV.open(filename, "wb") do |csv|
      csv << HEADERS.collect { |x| x.to_s }

      queue_attendees.each do |attendee|
        csv << attendee.to_array
      end
    end

    puts "Saved file #{filename}"
  end

  def get_empty_input()
    begin
      system("stty raw -echo")
      input = STDIN.getc
    ensure
      system("stty -raw echo")
    end
  end

  def undefined_command(cmd)
    puts "Invalid command '#{cmd.join(" ")}'"
  end
end

if __FILE__ == $0
  puts "Use the event_reporter_cli.rb to run the file"
end