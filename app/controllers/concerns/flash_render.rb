module FlashRender
  extend ActiveSupport::Concern

  include FlashI18n

  def render(options = {}, locals = {}, &block)
    flash_options = Hash === options ? options : locals

    self.class._flash_types.each do |flash_type|
      if value = flash_options.delete(flash_type)
        flash.now[flash_type] = translate_flash(value)
      end
    end

    if other_flashes = flash_options.delete(:flash)
      other_flashes.each do |key, value|
        flash.now[key] = translate_flash(value)
      end
    end

    super(options, locals, &block)
  end
end
