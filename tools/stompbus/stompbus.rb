require "stomp"
require "json"
require 'io/console' # for reading password without echo
require 'timeout' # to avoid freezes waiting for user input

class STOMPBus

  def initialize(**opts)
  # load the configuration
    opts["port"] = 61613
    opts["ssl"] = false
    opts = self.class.load_cred_env_vars(opts)
    opts = self.class.get_args(opts)
    # config file should be in format
    # {
    #   "login": "",
    #   "passcode": "",
    #   "queue": "",
    #   "host": "",
    #   "port": ""
    # }
    if opts["conf_file"]
      config_json_hash = self.class.read_json_file_as_hash(opts["conf_file"])
      opts = opts.merge(config_json_hash)
    end

    # check if we have all the required options
    self.class.check_opts(opts)
    @opts = opts
  end

  # will publish the provided message to the queue
  def publish
    # load the message
    msg = load_message()
    credentials = populate_credentials()
    client = Stomp::Client.new(credentials)
    msg["body"] = msg["body"].to_json unless msg["body"].kind_of?(String)
    client.publish(@opts["queue"], msg["body"], msg["header"])
  end

  # yield [msg] return true if you want message printed to console
  def subscribe()
    credentials = populate_credentials()
    client = Stomp::Client.new(credentials)

    client.subscribe(@opts["queue"]) do |msg|
      if block_given?
        yield(msg)
      else
        STOMPBus.print_msg(msg)
      end
    end

    begin
      puts "Press ctrl + c to exit...\n\n"
      loop do
        sleep(100)
      end
    rescue Interrupt
    ensure
      puts "\nclosing connection!\n"
    end
  end

  def self.print_msg(msg)
      puts "------------------------------"
      puts "\nHeaders:\n\n"
      puts msg.headers.to_json
      puts "\nBody:\n\n"
      puts msg.body
      puts "------------------------------"
  end

  def self.show_help()
    puts '
This script will send message to a configured STOMP queue. The script can be configured to the correct values through ENV vars, script arguments or a config file.
The message consists of two parts the message body (the message body is required) and the message header (header if not specified will be send empty). The message header
and body can be provided to the script as ENV var (STOMP_MESSAGE_BODY, STOMP_MESSAGE_HEADER), script arguments or a message json file. The user and passcode for the queue
can NOT be provided to the script as a parameter. Should be provided as a ENV var or in the conf file.

publish.rb <arguments> <message_body> (ENV var STOMP_MESSAGE_BODY)

Arguments:
--help - displays help
--host=<host> - STOMP server (ENV var STOMP_BUS_HOST)
--port=<port_number> - port of the STOMP server (if not defined default port 61613 is used, ENV var STOMP_BUS_PORT)
--message_file=<file_path> - the path to json file with the message to be send. The structure of the file has to have to
json keys body and header: {"header": {}, "body": {}}
--conf_file=<file_path> - the path to json file with the STOMP bus credentials and config.
--queue=<queue_name> - the queue you want to send the message (in format /path/to/queue, ENV var STOMP_BUS_QUEUE)
--message_header=<message_header> - provide message header (ENV var STOMP_MESSAGE_HEADER)'
  end


  # method checks if all required options are in place
  def self.check_opts(opts)
    req_opts_keys = ["host", "port", "ssl", "queue"]
    miss_opts_keys = []

    miss_opts_keys = req_opts_keys - opts.keys
    if miss_opts_keys.count > 0
      raise "Your configuration is missing following options: #{miss_opts_keys.join(", ")} Run the script with --help argument for help"
    end
  end

  def populate_credentials()
    unless @opts["login"]
      Timeout::timeout(120) {
        STDERR.puts "STOMP username (timeout in 2 minutes): "
        @opts["login"] = STDIN.gets.chomp
      }
    end
    unless @opts["passcode"]
        STDERR.puts "STOMP Password: "
        @opts["passcode"] = STDIN.noecho(&:gets).chomp
    end

    credentials = {:hosts => [{}], :connect_timeout => 15, :start_timeout => 15, :reliable => false}

    req_cred = [:login, :passcode, :host, :port, :ssl]

    req_cred.each do |cred|
        credentials[:hosts][0][cred] = @opts[cred.to_s]
    end

    return credentials
  end

  def self.read_json_file_as_hash(file_path)
    JSON.parse(File.read(file_path))
  end

  # get all the provided arguments of the script
  def self.get_args(opts)
    # we dont want include arguments which are not valid
    known_arg = ["host", "message_body", "port", "ssl", "message_header", "queue", "message_file", "conf_file"]
    unknown_arg = []

    ARGV.each do |a|
      # checking if the arguments are options for the script
      m = /\-\-(?:(help)|(.+?)=(.+))/.match(a)

      if m
        if m[1] == "help"
          self.show_help()
          exit()
        end
        if known_arg.include?(m[2])
          opts[m[2]] = m[3]
        else
          unknown_arg.push(m[2])
        end
      # if the last argument is not an option, and still exists we use it as a message body
      elsif ARGV[-1] == a
        opts["message_body"] = ARGV[-1]
      end
    end

    raise "Unknown argument option(s): #{unknown_arg.join(", ")}"if unknown_arg.count > 0
    return opts
  end

  # loads all the ENV variables if they exist
  def self.load_cred_env_vars(opts)
    env_vars = {
      "host" => "STOMP_BUS_HOST",
      "port" => "STOMP_BUS_PORT",
      "queue" => "STOMP_BUS_QUEUE",
      "message_header" => "STOMP_MESSAGE_HEADER",
      "message_body" => "STOMP_MESSAGE_BODY"
    }


    env_vars.each do |key, value|
      opts[key] = ENV[value] if ENV[value] && !ENV[value].empty?
    end
    if ENV["STOMP_BUS_CREDENTIALS"] && !ENV["STOMP_BUS_CREDENTIALS"].empty?
      cred = ENV["STOMP_BUS_CREDENTIALS"].split(":")
      opts["login"] = cred[0]
      opts["passcode"] = cred[1]
    end

    return opts
  end

  # loads message to be send
  def load_message()
    msg = {}
    if @opts.has_key?("message_body") && @opts.has_key?("message_file")
      raise "You can`t have both a message file and message as an argument. Choose only one!"
    elsif @opts.has_key?("message_body") && @opts.has_key?("message_header")
      msg["header"] = JSON.parse(@opts["message_header"])
      msg["body"] = @opts["message_body"]
    elsif @opts.has_key?("message_body")
      msg["header"] = {}
      msg["body"] = @opts["message_body"]
    elsif @opts.has_key?("message_file")
      json_hash = self.read_json_file_as_hash(@opts["message_file"])
      msg["header"] = json_hash["header"]
      msg["body"] = json_hash["body"]
    end
    if msg["body"].nil?
      raise "Your message is empty! You need to provide a message to be sent!"
    end
    return msg
  end
end
