require 'lolsoap'

class LolSoap::WSDL
  class NullType

    # https://github.com/loco2/lolsoap/pull/21
    def element(name)
      NullElement.new
    end

    def element_prefix(name)
        self.prefix
    end

    def sub_type(name)
        element(name).type
    end

    def has_attribute?(name)
        false
    end
  end
end
