module FlashI18n
  def redirect_to(url, options = {})
    self.class._flash_types.each do |flash_type|
      if options.key?(flash_type)
        options[flash_type] = translate_flash(options[flash_type])
      end
    end

    if other_flashes = options[:flash]
      other_flashes.each do |key, value|
        other_flashes[key] = translate_flash(value)
      end
    end

    super(url, options)
  end

  protected

  def translate_flash(key)
    if admin_request?
      scope = :"admin.flash"
    else
      scope = :"public.flash"
    end

    if Array === key
      options = key.extract_options!
      I18n.t(key.first, **({ scope: scope }.merge(options)))
    elsif Symbol === key
      I18n.t(key, scope: scope)
    else
      key
    end
  end
end
