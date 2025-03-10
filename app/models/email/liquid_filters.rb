module Email
  module LiquidFilters
    def date(value, format)
      value.strftime(format)
    end

    def number_to_word(number)
      I18n.t(number.to_i, scope: :"number.words")
    end

    def pluralize(word, count)
      word.pluralize(count)
    end

    def titleize(text)
      text.to_s.titleize
    end

    def blockquote(text)
      text.to_s.gsub(/^/, "> ")
    end
  end
end
