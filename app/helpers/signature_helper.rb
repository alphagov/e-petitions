module SignatureHelper
  def signature_count(key, count, options = {})
    t(:"#{key}_html", **(signature_count_options(count, number_with_delimiter(count), options)))
  end

  private

  def signature_count_options(count, num, options)
    options.reverse_merge(scope: :"ui.signature_counts", count: count, num: num)
  end
end
