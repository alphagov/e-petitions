require 'ostruct'
require 'json'

class RejectionReason < OpenStruct
  FILE = Rails.root.join(*%w(config rejection_reasons.json))

  class << self
    def for_code(code)
      reasons[code]
    end

    def options_for_select
      reasons.collect do |code, reason|
        option_value = reason.published ? reason.title : "#{reason.title} (will be hidden)"
        [option_value, code]
      end
    end

    private

    def load_reasons
      hash = JSON.parse(IO.read(FILE)).inject({}) do |hash, pair|
        hash[pair.first] = new(pair.second)
        hash
      end
    end

    def reasons
      @reasons ||= load_reasons
    end
  end
end
