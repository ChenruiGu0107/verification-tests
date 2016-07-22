require 'lolsoap'

class LolSoap::WSDL
  class NullType

    # https://github.com/loco2/lolsoap/pull/21
    def element(name)
      NullElement.new
    end
  end
end
