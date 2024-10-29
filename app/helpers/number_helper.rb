module NumberHelper
  def number_to_word(number)
    I18n.t(number, scope: :"number.words")
  end
end
