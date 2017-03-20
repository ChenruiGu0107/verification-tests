#!/usr/bin/env ruby
# frozen_string_literal: true

"""
Utility to enable some PolarShift operations via CLI
"""

require 'commander'

require_relative 'common/load_path'

require 'common'
require "gherkin_parse"

require_relative "stompbus/stompbus"

module CucuShift
  class PolarShiftCli
    include Commander::Methods
    include Common::Helper

    TCMS_RELEVANT_TAGS = ["admin", "destructive", "vpn", "smoke"].freeze

    def initialize
      always_trace!
    end

    def run
      program :name, 'PolarShift CLI'
      program :version, '0.0.1'
      program :description, 'Tool to enable some PolarShift operations via CLI'

      #Commander::Runner.instance.default_command(:gui)
      default_command :help

      global_option('-p', '--project ID', 'Project ID to use')
      global_option('--polarshift URL', 'PolarShift URL')

      command :fiddle do |c|
        c.syntax = "#{__FILE__} fiddle"
        c.description = 'enter a pry shell to play with API'
        c.action do |args, options|
          require 'pry'
          binding.pry
        end
      end

      command :"update-automation" do |c|
        c.syntax = 'dyn.rb create_a [options]'
        c.description = 'create A record depending on opts'
        c.option('--wait', "wait on message bus for operation to complete")
        c.action do |args, options|
          setup_global_opts(options)
          if args.empty?
            raise "please add Test Case IDs in the command line"
            exit false
          end

          project_id = project

          parser = GherkinParse.new
          cases_loc = parser.locations_for *args
          cases_spec = parser.spec_for cases_loc

          updates = generate_case_updates(project_id, cases_spec)

          # print what we are going to do to user
          updates.each do |c, updates|
            say "Automation script field for #{HighLine.color c, :bold}:\n"
            updates.each do |field, update|
              say "#{HighLine.color(field.to_s.upcase, :magenta, :bold)}: #{HighLine.color(update.strip, :green)}"
            end
            say "======================================"
          end

          ## prepare user/password to the bus early to catch message
          bus_client = msgbus.new_client

          puts "Updating cases: #{updates.keys.join(", ")}.."
          res = polarshift.
            update_test_case_custom_fields(project_id, updates)

          if res[:success]
            filter = JSON.load(res[:response])["description"].
              gsub(/\A.*\-\-selector "(.+='.+')"\z/m, '\\1')
            unless filter =~ /\A[-_.a-zA-Z0-9]+='[-_.a-zA-Z0-9:]+'\z/
              puts "unknown importer response:\n#{res[:response]}"
              exit false
            end
            puts "waiting for a bus message with selector: #{filter}"
            message = nil
            bus_client.subscribe(msgbus.default_queue, selector:filter) do |msg|
              message = msg
              bus_client.close
            end
            bus_client.join
            puts STOMPBus.msg_to_str(message)
          else
            puts "HTTP Status: #{res[:exitcode]}, Response:\n#{res[:response]}"
            exit false
          end
        end
      end

      run!
    end

    # @param project [String] project id
    # @param cases_spec [Hash<String, Hash>] structure like:
    #   case_id_1:
    #     scenario: scenario name
    #     file: file name relative to cucumber dir
    #     args:
    #       some: arg if any
    #   case_id_2: ...
    def generate_case_updates(project, cases_spec)
      updates = normalize_tags(project, cases_spec).map do |case_id, spec|
        tags = spec.delete("tags")
        update = {
          caseautomation: "automated",
          automation_script: {"cucushift" => spec}.to_yaml
        }
        update[:tags] = tags if tags
        [ case_id, update ]
      end
      return Hash[updates]
    end

    # @return [Array<String, Array>] same as [GherkinParse#cases_spec] but
    #   we do not convert to Hash as it is not needed
    # @see #generate_case_updates for parameter description
    def normalize_tags(project, cases_spec)
      casetags = {}
      cases_spec.each do |case_id, spec|
        tags = spec.delete("tags")
        if tags && !tags.empty?
          raise "bad tag format: #{tags}" unless Array === tags
          tags.each do |tag|
            raise "bad tag value: #{tag.inspect}" unless String === tag
          end
          casetags[case_id] = tags
        else
          casetags[case_id] = []
        end
      end

      puts "Getting cases: #{casetags.keys.join(", ")}.."
      polarshift.refresh_cases_wait(project, casetags.keys)
      cases_raw = polarshift.get_cases_smart(project, casetags.keys)

      cases = cases_raw.map { |c| PolarShift::TestCase.new(c, polarshift) }

      cases.each do |tcms_case|
        final_tags = casetags[tcms_case.id] & TCMS_RELEVANT_TAGS
        final_tags.concat(tcms_case.tags - TCMS_RELEVANT_TAGS)
        if final_tags != tcms_case.tags
          cases_spec[tcms_case.id]["tags"] = final_tags.join(" ")
        end
      end

      return cases_spec
    end

    def project
      polarshift.default_project
    end

    def polarshift
      @polarshift ||= PolarShift::Request.new(**opts)
    end

    def msgbus
      @msgbus ||= STOMPBus.new
    end

    def opts
      @opts || raise('please first call `setup_global_opts(options)`')
    end

    # @param options [Ostruct] options as processed by Commander
    def setup_global_opts(options)
      opts = options.default
      if opts[:project]
        opts[:manager] = { project: opts.delete(:project) }
      end
      if opts[:polarshift]
        opts[:base_url] = opts.delete(:polarshift)
      end
      @opts = opts
    end
  end
end

if __FILE__ == $0
  CucuShift::PolarShiftCli.new.run
end
