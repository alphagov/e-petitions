module Email
  module LiquidFilters
    def number_to_word(number)
      I18n.t(number.to_i, scope: :"number.words")
    end

    def pluralize(count, singular, plural)
      word = count == 1 ? singular : plural
      "#{count || 0} #{word}"
    end

    def titleize(text)
      text.to_s.titleize
    end
  end
end
