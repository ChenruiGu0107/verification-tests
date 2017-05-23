require 'find'
require 'psych'
require 'uri'
require 'watir-webdriver'

require "base64"

  class Web4Cucumber
    attr_reader :base_url, :browser_type, :logger, :rules

    @@headless = nil

    FUNMAP = {
      :select => :select_lists,
      :checkbox => :checkboxes,
      :radio => :radios,
      :text_field => :text_fields,
      :textfield => :text_fields,
      :text_area => :textareas,
      :textarea => :textareas,
      :filefield => :file_fields,
      :file_field => :file_fields,
      :a => :as,
      :button => :button,
      :element => :elements,
      :input => :input,
      :js => :execute_script,
      :iframe => :iframe
    }

    ELEMENT_TIMEOUT = 10

    # @param logger [Object] should have methods `#info`, `#warn`, `#error` and
    #   `#debug` defined
    def initialize(
        rules:,
        base_url:,
        snippets_dir: "",
        logger: SimpleLogger.new,
        browser_type: :firefox,
        browser: nil
      )
      @browser_type = browser_type
      @rules = Web4Cucumber.load_rules [rules]
      @snippets_dir = snippets_dir
      @base_url = base_url
      @browser = browser
      @logger = logger
    end

    def is_new?
      !@browser
    end

    def browser
      return @browser if @browser
      firefox_profile = Selenium::WebDriver::Firefox::Profile.new
      chrome_profile = Selenium::WebDriver::Remote::Capabilities.chrome()
      if ENV.has_key? "http_proxy"
        proxy = ENV["http_proxy"].scan(/[\w\.\d\_\-]+\:\d+/)[0] # to get rid of the heading "http://" that breaks the profile
        firefox_profile.proxy = chrome_profile.proxy = Selenium::WebDriver::Proxy.new({:http => proxy, :ssl => proxy})
        firefox_profile['network.proxy.no_proxies_on'] = "localhost, 127.0.0.1"
        chrome_switches = %w[--proxy-bypass-list=127.0.0.1]
        ENV['no_proxy'] = '127.0.0.1'
      end
      client = Selenium::WebDriver::Remote::Http::Default.new
      client.timeout = 180

      headless

      if @browser_type == :firefox
        logger.info "Launching Firefox"
        @browser = Watir::Browser.new :firefox, :profile => firefox_profile, :http_client=>client, desired_capabilities: {marionette: false}
      elsif @browser_type == :chrome
        logger.info "Launching Chrome"
        @browser = Watir::Browser.new :chrome, desired_capabilities: chrome_profile, switches: chrome_switches
      else
        raise "Not implemented yet"
      end
      @browser
    end

    # start a new headless session if we don't have a GUI environment already;
    #   that means no windows, no mac, and no DISPLAY env variable;
    #   if you want to force headless on linux, just `unset DISPLAY` prior run
    def headless
      if !Gem.win_platform? &&
          /darwin/ !~ RUBY_PLATFORM &&
          !ENV["DISPLAY"] &&
          !@@headless
        require 'headless'
        @@headless = Headless.new
        @@headless.start
      end
    end

    def finalize
      @browser.close if @browser
      # avoid destroy as it happens at_exit anyway but often reused during run
      # @@headless.destroy if @@headless
    end

    def replace_rules(rulez)
      @rules = Web4Cucumber.load_rules [rulez]
    end

    def res_join(master_res, *results)
      results.each do |res|
        master_res.merge!(res) do |key, oldval, newval|
          case key
          when :success
            oldval && newval
          when :exitstatus
            newval
          when :instruction
            oldval
          else
            case oldval
            when String
              oldval << $/ << newval
            when CAN_APPEND
              oldval << newval
            when nil
              newval
            else
              raise "dunno how to merge result '#{key}' field: #{oldval}"
            end
          end
        end
      end
      return master_res
    end

    def run_action(action, **user_opts)
      logger.info("running web action #{action} ... ")
      unless rules[action.to_sym]
        raise "rules source have no #{action} rules"
      end
      result = {
        instruction: "perform web action '#{action}'",
        success: true,
        response: "performing web action '#{action}'",
        exitstatus: -1
      }
      rules[action.to_sym].each do |rule, spec|
        logger.info("#{rule}..") unless rule == :action
        case rule
        when :url
          res_join result, handle_url(spec, **user_opts)
        when :element
          res_join result, handle_element(spec, **user_opts)
        when :elements
          res_join result, *spec.map { |el| handle_element(el, **user_opts) }
        when :action
          res_join result, handle_action(spec, **user_opts)
        when :scripts
          res_join result, *spec.map { |st| handle_script(st, **user_opts) }
        when :cookies
          res_join result, *spec.map { |ck| handle_cookie(ck, **user_opts) }
        when :with_window
          res_join result, handle_switch_window(spec, **user_opts)
        when :params
          user_opts, res = handle_params(spec, **user_opts)
          res_join result, res
        else
          raise "unknown rule '#{rule}'"
        end

        break unless result[:success]
      end

      result[:response] << $/ << "web action '#{action}' "
      result[:response] << (result[:success] ? "completed" : "failed")
      return result
    end

    # Feel free to uncomment this if you need substitution of params with user_opts
    def handle_params(params, **user_opts)
      unless params.kind_of? Hash
        raise "The param should be a Hash"
      end
      res = {
        instruction: "merge #{params.inspect} with user_opts:#{user_opts.inspect}",
        success: true,
        response: "#{params.inspect} was merged with user_opts",
        exitstatus: -1
      }
      user_opts = params.map {|key, vals|
        if vals.instance_of?(String)
          [key, replace_angle_brackets(vals, user_opts)]
        else
          [key].push vals.map {|val|
            replace_angle_brackets(val, user_opts)
          }
        end
      }.to_h.merge user_opts
      return user_opts, res
    end

    def handle_cookie(cookie,**user_opts)
      unless cookie.kind_of? Hash
        raise "The cookie should be a Hash"
      end

      unless cookie.has_key?(:name) && cookie.has_key?(:expect_result)
        raise "Cookie lack of name or expect_result"
      end

      output = browser.cookies[cookie[:name]]
      if cookie[:expect_result].kind_of? String
        success = output == cookie[:expect_result]
      else
        success = ! output == ! cookie[:expect_result]
      end
      res = {
        instruction: "get cookie:\n#{cookie[:name]}\n\nexpected result: #{cookie[:expect_result].inspect}",
        success: success,
        response: output.to_s,
        exitstatus: -1
      }
      return res
    end

    def handle_script(script, **user_opts)
      unless script.kind_of? Hash
        raise "The script should be a Hash."
      end

      unless script.has_key?(:command) && script.has_key?(:expect_result) || script.has_key?(:file)
        raise "Script lack of file/command or expect_result"
      end
      # sleep to make sure the ajax done, still no idea how much time should be
      sleep 2

      if script.has_key?(:file)
        path = @snippets_dir + script[:file] + ((script[:file].end_with? ".js") ? "" : ".js")
        if File.exist?(path)
          command = replace_angle_brackets(File.read(path), user_opts)
        else
          error_msg = "#{path} does not exists."
          if @snippets_dir == ""
            error_msg += " You could set path to snippets folder in `snippets_dir` param."
          end
          raise error_msg
        end
      else
        command = replace_angle_brackets(script[:command], user_opts)
      end
      output = execute_script(command)

      if script[:expect_result].kind_of? String
        expect = replace_angle_brackets(script[:expect_result], user_opts)
        success = output == expect
      else
        success = ! output == ! script[:expect_result]
      end

      res = {
        instruction: "run JS:\n#{script[:command]}\n\nexpected result: #{script[:expect_result].inspect}",
        success: success,
        response: output.to_s,
        exitstatus: -1
      }
      return res
    end

    # window_rule[:selector] could be Regexp or String format of window's url/title
    # see the example in lib/rules/web/console/debug.xyaml
    def handle_switch_window(window_rule, **user_opts)
      unless window_rule.kind_of? Hash
        raise "switch window rule should be a Hash."
      end

      unless window_rule.has_key?(:selector) && window_rule.has_key?(:action)
        raise "switch window lack of selector or action"
      end

      if browser.window(window_rule[:selector]).exists?
        browser.window(window_rule[:selector]).use do
          return handle_action(window_rule[:action], **user_opts)
        end
      else
        for win in browser.windows
         logger.warn("window title: #{win.title}, window url: #{win.url}")
        end
        raise "specified window not found: #{window_rule[:selector].to_s}"
      end
    end

    def handle_action(action_body, **user_opts)
      case action_body
      when String, Symbol
        return run_action(action_body.to_sym, **user_opts)
      when Hash
        raise '"ref: action" must be provided within action rule of type '\
              'hash/dictionary' unless action_body[:ref]
        res_if = nil
        res_unless = nil

        if action_body[:if_element]
          res_if = handle_element(action_body[:if_element], **user_opts)
          unless res_if[:success]
            # element was not found but this is ok, we just return to caller
            res_if[:success] = true
            res_if[:response] << $/ << "skipping action #{action_body[:ref]}"
            return res_if
          end
        end

        if action_body[:unless_element]
          res_unless = handle_element(action_body[:unless_element], **user_opts)
          if res_unless[:success]
            # element was found so we quick return to caller
            res_unless[:response] << $/ << "skipping action #{action_body[:ref]}"
            return res_unless
          end
        end

        res_param = {}
        if action_body[:if_param]
          res_param[:success] = true
          if action_body[:if_param].kind_of? String
            unless user_opts.has_key? action_body[:if_param].to_sym
              # param was not found so we return to caller
              res_param[:response] = "parameter '#{action_body[:if_param]}' not in user_opts"
              return res_param
            end
          elsif action_body[:if_param].kind_of? Hash
            unless action_body[:if_param].all? { |name, value| user_opts[name]==value }
              # params from user_opts and from the if_param rule differ
              res_param[:response] = "parameters '#{(action_body[:if_param].to_a - user_opts.to_a).to_h}' not in user_opts"
              return res_param
            end
          else action_body[:if_param].kind_of? Array
            unless action_body[:if_param].all? { |name| user_opts.has_key? name.to_sym }
              # param was not found so we return to caller
              res_param[:response] = "parameters with '#{(action_body[:if_param].map &:to_sym) - user_opts.keys}' names not in user_opts"
              return res_param
            end
          end
        end

        res_context ={}
        if action_body[:context]
          res_context[:success], context_elements  = wait_for_elements(
            {
              :type => :iframe,
              :selector => action_body[:context],
              :context => user_opts[:_context]
            })
          unless res_context[:success]
            res_context[:response] = "Context element #{action_body[:context]}" \
                                     "wasn't found.Skipping action #{action_body[:ref]}"
            return res_context
          end
          user_opts[:_context] = context_elements.first.first.last
        end

        case action_body[:ref]
        when String, Symbol
          res = run_action(action_body[:ref].to_sym, **user_opts)
        when Array
          res = {}
          action_body[:ref].each { | action |
            res_join res, run_action(action.to_sym, **user_opts)
          }
        end
        res_join(res, res_if) if res_if
        res_join(res, res_unless) if res_unless
        res_join(res, res_param) unless res_param.empty?
        res_join(res, res_context) unless res_context.empty?
        return res
      else
        raise "unknown action rule body type: #{action_body.class}"
      end
    end

    def goto_url(url, **user_opts)
      url =  replace_angle_brackets(url, user_opts)

      if !(url =~ URI.regexp)
        url = URI.join(base_url, url).to_s
      end
      logger.info("Navigating to: #{url}")
      browser.goto url
      return {
        instruction: "opening #{url}",
        success: true,
        response: "opened #{url}",
        exitstatus: -1
      }
    end
    alias handle_url goto_url

    def handle_element(element_rule, **user_opts)
      unless element_rule.kind_of? Hash
        raise "Element rules should be a Hash but is: #{element_rule.inspect}"
      end
      if element_rule[:missing] && element_rule[:optional]
        raise "Optionally missing element doesn't make much sense"
      end

      #copy the element_rule
      rule = element_rule.dup
      #replace selector's '<param>' with corresponding value in user_opts
      rule[:selector] = selector_param_setter(rule[:selector], user_opts)

      #replace timeout's '<param>' with corresponding value in user_opts
      if rule[:timeout].kind_of? String
        rule[:timeout] = Integer(replace_angle_brackets(rule[:timeout], user_opts))
      end

      # context was provided with user_opts
      rule[:context] = user_opts[:_context]

      res = {}
      # # context was provided within element rule
      # if rule[:context]
      #   rule[:context] = selector_param_setter(rule[:context], user_opts)
      #   success, context_elements = wait_for_elements({:type => :iframe, :selector => rule[:context], :_context => rule[:_context]})
      #   rule[:_context] = context_elements.first.first.last
      #   context_res = {
      #     instruction: "handle context #{rule[:context]}",
      #     success: success,
      #     response: "context element#{success ? "" : ' not'} found: #{rule[:context]}",
      #     exitstatus: -1
      #   }
      #   res_join(res, context_res)
      # end

      # based on opts[:missing] it'll wait for element to appear/dissapear
      success, elements = wait_for_elements(rule)

      element_res = {
        instruction: "handle #{element_rule}",
        success: !! ( success || element_rule[:optional] ),
        response: "element#{success ^ element_rule[:missing] ? "" : ' not'} found: #{element_rule}",
        exitstatus: -1
      }
      res_join res, element_res

      # save screenshot if missing/required element found/not found
      unless success || element_rule[:optional]
        take_screenshot
      end

      # perform any operation over innermost element found
      op = element_rule[:op]
      if op && success
        if element_rule[:missing]
          raise "Obviously, you can't perform any operations on missing element"
        end
        # first element searched for, first field [the actual element list], last found element [this must be most inner element]
        element = elements.first.first.last
        opres = handle_operation(element, op, **user_opts)
        # If we are selecting an element before page is fully loaded,
        # Watir can lose this element and its op will fail. Retrying
        # handle_element on such error can help.
        if opres[:response].include? "#<Watir::Exception::UnknownObjectException: unable to locate element"
          return handle_element(element_rule, **user_opts)
        else
          res_join res, opres
        end
      end

      return res
    end

    # @param element [Watir::Element]
    # @param op_spec [String] operation to perform on element defined in rules
    # @param user_opts [Hash] the options user provided for the operation, e.g.
    #   { :username => "my_username", :password => "my_password" }
    def handle_operation(element, op_spec, **user_opts)
      unless op_spec.kind_of? String
        raise "Op specification not a String: #{op_spec.inspect}"
      end

      op, space, val = op_spec.partition(" ")
      val = replace_angle_brackets(val, user_opts)

      res = {
        instruction: "#{op} #{element} with #{val}",
        response: "#{op} on #{element} with #{val}",
        success: true,
        exitstatus: -1
      }

      begin
        case op
        when "click", "hover"
          raise "cannot #{op} with a value" unless val.empty?
          element.send(op.to_sym)
        when "clear"
          raise "cannot #{op} with a value" unless val.empty?
          element.to_subtype.clear
        when "drag_and_drop_by"
          # not working with sortable jQuery list, please use native js script
          # from lib/rules/web/snippets/jquery.simulate.drag-sortable.js
          off_right, off_down = val.split(" ").map {|c| c.to_i}
          raise "cannot #{op} without right and down offset values" unless off_right || off_down
          element.drag_and_drop_by(off_right, off_down)
        when "set", "select_value", "append"
          if element.instance_of?(Watir::CheckBox)
            if val == "true"
              val = true
            elsif val == "false"
              val = false
            else
              raise("you can set only 'true' or 'false' to element of type #{element.class}")
            end
          end

          if element.respond_to? op.to_sym
            element.send(op.to_sym, val)
          else
            raise "element type #{element.class} does not support #{op}"
          end
        when "send_keys"
          # see http://watirwebdriver.com/sending-special-keys
          # to allow multiple values and special keys, value must parse to valid
          #   YAML; e.g. `mystring`, `:mysym`, [":asdsdf", "sdf", ":fsdf"]`
          raise "you must specify value for op #{op}" if val.empty?
          keys = Psych.load val
          element.send_keys keys
        else
          raise "do not know how to '#{op}'"
        end
      rescue => err
        res[:success] = false
        res[:response] << "\n" << "operation #{op} failed:\n"
        res[:response] << self.class.exception_to_string(err)
      ensure
        return res
      end
    end

    # another option would be to save to file but not sure where to store
    #   as most formatters do not relocate the file
    def take_screenshot
      filename = Time.now.iso8601
      # screenshot = %{data:image/png;base64,#{browser.screenshot.base64}}
      # logger.embed screenshot, "application/octet-stream", "#{filename}-screenshot.png"
      logger.embed browser.screenshot.base64, "image/png;base64", "#{filename}-screenshot.png"
      logger.embed Base64.strict_encode64(browser.html), "text/html;base64", "#{filename}.html"
    end

    def get_elements(type: nil, context: browser, selector:)
      type = type ? type.to_sym : :element # generic element when type absent
      raise "unknown web element type '#{type}'" unless FUNMAP.has_key? type

      # note that this is lazily evaluated so errors may occur later
      res = context.public_send(FUNMAP[type], selector)

      # we want to always return an array
      if res.nil?
        res = []
      elsif res.kind_of? Watir::ElementCollection
        # sometimes non-existing element is returned, workaround that
        res = res.to_a.select { |e| e.exists? }
      else
        # some element types/methods return a single element
        res = res.exists? ? [res] : []
      end
      logger.info("found #{res.size} #{type} elements with selector: #{selector}")
      return res
    end

    def get_visible_elements(element_opts)
      return get_elements(**element_opts).select { |e| e.present? }
    end

    # return HTML code of current page
    def page_html
      return browser.html
    end

    # return URL of current page
    def url
      browser.url
    end

    # return title of current page
    def title
      browser.title
    end

    # return visible text of html body
    def text
      browser.text
    end

    # @param element_list [Array] list of parametrized element type/selector
    #   pairs where selectors may contain `<param>` strings
    # @param params [Hash] params to replace within selectors
    # @return [Array] list of processed element type/selector pairs
    private def element_list_param_setter(element_list, params)
      element_list.map do |el_type, selector|
        [el_type, selector_param_setter(selector, params)]
      end
    end

    # @param selector [Hash] element selector as accepted by watir and may
    #   contain `<param>` strings
    # @param params [Hash] params to replace within selector
    # @return [Hash] processed element selector as accepted by watir
    private def selector_param_setter(selector, params)
      return selector if params.empty?
      case selector
      when String
        # javascript selectors
        selector_res = replace_angle_brackets(selector, params)
      when Hash
        selector_res = {}
        selector.each do |selector_type, query|
          selector_res[selector_type] = replace_angle_brackets(query, params)
        end
      else
        raise "don't know how to handle selector of type #{selector.class}"
      end
      return selector_res
    end

    # replace <something> strings inside strings given option hash with symbol
    #   keys
    # @param [String] str string to replace
    # @param [Hash] opts hash options to use for replacement
    # @return [String] the value match in the opts[key]
    private def replace_angle_brackets(str, opts)
      return str.gsub(/<([a-z0-9_]+)>/) { |m|
        opts[m[1..-2].to_sym] || m
      }
    end

    # this somehow convoluted method can be used to wait for multiple elements
    #   for a given timeout to appear or dissapear; that means there is one
    #   timeout to check all requested elements
    # @param opts [Hash] with possible keys: :type, :selector, :list, :visible, :missing
    #   :timeout, :context
    # @return [Array] of `[status, [[[elements], type, selector], ..] ]`
    def wait_for_elements(opts)
      # expect either :list of [:type, :selector] pairs or
      #   :type and :selector options to be provided
      elements = opts[:list] || [[ opts[:type], opts[:selector] ]]
      only_visible = opts.has_key?(:visible) ? opts[:visible] : true
      missing = opts.has_key?(:missing) ? opts[:missing] : false
      timeout = opts[:timeout] || ELEMENT_TIMEOUT # in seconds
      context = opts[:context] || browser

      start = Time.now
      result = nil
      begin
        result = {:list => [], :success => true}
        break if elements.all? { |type, selector|
          element_opts = {
            :type => type,
            :context => context,
            :selector => selector
          }
          e = only_visible ?
              get_visible_elements(**element_opts) :
              get_elements(**element_opts)
          result[:list] << [e, opts[:type], opts[:selector]] unless e.empty?
          e.empty? == missing
        }
        result[:success] = false
      end while Time.now - start < timeout && sleep(1)

      return result[:success], result[:list]
    end
    alias wait_for_element wait_for_elements

    # parse CucuShift webauto single rules file; that is a YAML file with the
    #   only difference that duplicate keys on the second level are allowed;
    #   i.e. we can specify multiple `url`, `elements`, `action`, etc. child
    #   elements inside action rules
    # @param file [String] webauto XYAML file
    # @return [Hash] of the parsed data
    def self.parse_rules_file(file)
      # mid-level API to get document AST
      doc = Psych.parse_file(file)
      unless doc.root.kind_of? Psych::Nodes::Mapping
        raise "document root not a mapping: #{file}"
      end
      custom_doc = Psych::Nodes::Document.new(doc.version,
                                              doc.tag_directives,
                                              doc.implicit)
      custom_doc.children << Psych::Nodes::Mapping.new(doc.root.anchor,
                                                        doc.root.tag,
                                                        doc.root.implicit,
                                                        doc.root.style)
      actions = doc.root.children
      # store all action names to avoid duplications
      action_names = []
      res = {}
      actions.each_slice(2) do |action_name_ast, action_body_ast|
        action_name = action_name_ast.value
        if action_names.include? action_name
          raise "duplicate action #{action_name.inspect} definition in #{file.inspect}"
        elsif !action_name_ast.to_ruby.instance_of? String
          raise "You can't use #{action_name.inspect} as an action name"
        elsif !action_body_ast.kind_of? Psych::Nodes::Mapping
          raise "not a mapping: #{action_name.inspect} in #{file.inspect}"
        else
            action_names << action_name
        end

        custom_doc.root.children.concat [
          action_name_ast,
          Psych::Nodes::Sequence.new(action_body_ast.anchor,
                                      action_body_ast.tag,
                                      action_body_ast.implicit,
                                      action_body_ast.style)
        ]

        action_body_ast.children.each_slice(2) { |rule_name_ast, rule_body_ast|
          rule_name_ast.value = rule_name_ast.value.to_sym
          rule_pair = Psych::Nodes::Sequence.new()
          rule_pair.children.concat [rule_name_ast, rule_body_ast]
          custom_doc.root.children.last.children << rule_pair
        }
      end
      res = symkeys(custom_doc.to_ruby)

      return res
    end

    # traverse arrays and hashes to make all hash keys Symbols
    def self.symkeys(struc)
      case struc
      when Array
        struc.map! {|el| symkeys el}
        return struc
      when Hash
        target = {}
        struc.each { |k, v| target[k.to_sym] = symkeys(v) }
        return target
      else
        return struc
      end
    end

    def self.exception_to_string(e)
      str = "#{e.inspect}\n    #{e.backtrace.join("\n    ")}"
      e = e.cause
      while e do
        str << "\nCaused by: #{e.inspect}\n    #{e.backtrace.join("\n    ")}"
        e = e.cause
      end
      return str
    end

    def self.load_rules(*sources)
      return sources.flatten.reduce({}) { |rules, source|
        if source.kind_of? Hash
        elsif File.file? source
          source = parse_rules_file source
        elsif File.directory? source
          files = []
          if source.end_with? "/"
            # we should be recursive
            Find.find(source) { |path|
              if File.file?(path) && path.end_with?(".xyaml",".xyml")
                files << path
              end
            }
          else
            # we should only load .xyaml files in current dir
            files << Dir.entries(source).select {|d| File.file?(d) && d.end_with?(".xyaml",".xyml")}
          end

          source = load_rules(files)
        else
          raise "unknown rules source '#{source.class}': #{source}"
        end

        rules.merge!(source) { |key, v1, v2|
          raise "duplicate key '#{key}' in rules: #{sources}"
        }
      }
    end

    def execute_script(script)
      unless script.include?("return")
        raise "The script does not contain the keyword return"
      end
      browser.execute_script(script)
    end

    class SimpleLogger
      def info(msg)
        Kernel.puts msg
      end
      alias error info
      alias warn info
      alias debug info

      def embed(src, mime_type, label)
        if !src.kind_of?(String) || src.empty?
          Kernel.puts "empty embedding??"
        elsif (File.file?(src) rescue false)
          Kernel.puts "See #{File.absolute_path(src)}"
        elsif src =~ /\A[[:print:]]*\z/
          Kernel.puts "Embedded #{mime_type} data labeled #{label}:\n#{src}"
        else
          Kernel.puts "Unrecognized #{mime_type} data labeled #{label} (Base64):\n#{Base64.encode64 src}"
        end
      end
    end

    class CAN_APPEND
      def self.===(other)
        other.respond_to?(:<<)
      end
    end

  end
