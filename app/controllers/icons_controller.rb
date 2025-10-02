class IconsController < PublicController
  VALID_SIZES = %w[120x120 152x152 167x167 180x180]

  def show
    expires_in 1.hour, public: true

    if valid_size?
      redirect_to asset_url("apple-touch-icon-#{size}"), status: :temporary_redirect
    else
      redirect_to asset_url('apple-touch-icon'), status: :temporary_redirect
    end
  end

  private

  def size
    params[:size].to_s
  end

  def valid_size?
    VALID_SIZES.include?(size)
  end

  def asset_url(icon)
    view_context.asset_url("os-social/apple/#{icon}.png")
  end
end
