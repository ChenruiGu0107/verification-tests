require 'watir-webdriver'
require 'headless'
require 'common'

module CucuShift
  class Web4
    include Common::Helper
    FUNMAP = {
      'select'=> 'select',
      'text_field' => 'text_field',
      'textarea' => 'textarea',
      'a' => 'as',
      'button' => 'button',
      'input'=> 'input',
      'checkbox' => 'checkbox'
    }

    ELEMENT_TIMEOUT = 10
    def initialize(**opts)
      @browser_type = :firefox 
      @rules = opts[:rules]
      @host = opts[:server]
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
  
      unless ENV.has_key? "DEBUG_WEB"
        @headless = Headless.new
        @headless.start
      end
  
      if @browser_type == :firefox
        @browser = Watir::Browser.new :firefox, :profile => firefox_profile, :http_client=>client
      elsif @browser_type == :chrome
        @browser = Watir::Browser.new :chrome, desired_capabilities: chrome_profile, switches: chrome_switches
      else
        raise "Not implemented yet"
      end
      @browser
    end
   
    def finalize
      @browser.close
      @headless.destroy if defined?(@headless)
    end
  
    def run_action(action, **opts)
      logger.info("running web action #{action} ... ")
      base_url = @host
      @rules = opts[:rules]
      unless @rules
        raise "rules source have no #{action} rules"  
      end
      result={}
      @rules[action.to_sym][:pages].each do |page|
        rule = @rules[page.to_sym]
        logger.info("#{rule}")
        goto_url(base_url + rule[:url])
         
        if rule[:elements]
          do_elements(rule[:elements], opts)
        end 
    
        result.merge! check_page(rule[:checkpoints].dup,opts)
      end
      result
    end

    def goto_url(url)
      browser.goto url
    end

    def do_elements(elements, **opts)
      elements.each{ |element|
        
        ele = find_elements(element)
        
        unless ele
          logger.error("can not find element #{element[:selector]}")
        end

        do_action(ele,element,opts)
      }
    end
    
    def find_elements(hash, **opts)
      fun = FUNMAP[hash[:tag]]
      unless fun
        raise "the type #{hash[:type]} for #{hash} not support by this, or typo"
      end

      element = wait_for_element do
        unless fun
          logger.error("There are no function register for the #{hash[:tag]}")
        else
          logger.info("use function #{fun} to generate the element")
          browser.method(fun.to_sym).call(hash[:selector])
        end
      end
      unless element
        logger.error "can not found the element #{hash[:selector]} with tag #{hash[:tag]} in the #{@browser.url} page"
      end
      element
    end

    def do_action(element, hash, **opts)
      action, value = hash[:action].split(" ")
      if value
        opt = value.delete(">").delete("<")
        if value = opts[opt.to_sym] 
          ## since when given the specific element type, the action should be given as follow
          logger.info("current tag is #{hash[:tag]}")
          case hash[:tag]
          when 'select'
            if opts[name.to_sym]
              element.select_value value
            elsif hash[:def_value]
              element.select_value hash[:def_value]
            else
              logger.error("Please, provide a value for this element: #{prop}")
            end
          when 'filefield', 'file-field','file_field'
            element.set value
          when 'checkbox','radio','a','element'
            element.click
          when 'textfield', 'text_field', 'text_area', 'textarea'
            element.clear
            if opts.has_key? opt.to_sym
              if opts.has_key? :characterwise
                value.each_char do |c|
                  element.append c
                end
              else
                element.send_keys value
              end
    
            elsif prop.has_key? :def_value
              element.send_keys prop[:def_value]
            else
              logger.error("Please provide the value for this element: #{prop}")
            end
          when 'input'
            case element.type
            when 'text','password'
              element.send_keys value
            else
              element.click
            end 
          else
            element.click
          end
        else
          logger.warn("we have no #{opt} options in opts")
        end
      else
        if action.to_s == "click"
          case hash[:tag]
          when 'button'
            element.click
          else
            element.click
          end
        else
          logger.error("we can not deal with the action your provide")
        end
      end
    end
    
    def check_page(points, opt)
      ##todo
      result = {}
      points.each do |point|
        #todo: write some logic for the gsub varibales for text
        pp=point.dup
        if point[:text]
          point[:text].match(/<.*?>/).to_a.each do |data|
            if value = opt[data.delete("<").delete(">").to_sym]
                pp[:text] = pp[:text].gsub(/<.*?>/, value) unless pp.frozen? 
            else
              logger.warn("we have no opts")
            end
          end
        end
        logger.info(pp)
        element = wait_for_element do 
          browser.element(pp)
        end
        unless element.exist?
          logger.error "Can not find the elements #{point[:selector]} for the page"
        else
          result[:success] = true
        end
      end
      result
    end

    def wait_for_element(&b)
      result=nil
      for i in 1..ELEMENT_TIMEOUT
        if result && result.present?
          break
        end
        result = b.call
        sleep 1
      end
      result
    end

  end
end
