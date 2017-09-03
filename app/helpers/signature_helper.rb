module SignatureHelper
  def signature_count(key, count, options = {})
    t(:"#{key}.html", siganture_count_options(count, number_with_delimiter(count), options))
  end

  private

  def siganture_count_options(count, formatted_count, options)
    options.reverse_merge(scope: :"petitions.signature_counts", count: count, formatted_count: formatted_count)
  end
end
