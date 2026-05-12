require 'will_paginate/view_helpers/action_view'

module SearchHelper
  class PetitionPaginationRenderer < WillPaginate::ActionView::LinkRenderer
    def pagination
      @options[:page_links] ? windowed_page_numbers : []
    end

    def to_html
      list_items = pagination.map do |item|
        item.is_a?(Integer) ? page_number(item) : send(item)
      end.join

      html = previous_page
      html += tag(:ul, list_items, class: "pagination__list")
      html += next_page

      @options[:container] ? html_container(html) : html
    end

    def container_attributes
      { class: "pagination", "aria-label": "Pagination" }
    end

    protected

    def html_container(html)
      tag(:nav, html, container_attributes)
    end

    def gap
      tag(:li, "…", class: "pagination__item pagination__item--ellipsis")
    end

    def page_number(page)
      if page == current_page
        tag(:li, link(page, page, "aria-label": "Page #{page}", "aria-current": "page"), class: "pagination__item pagination__item--current")
      else
        tag(:li, link(page, page, "aria-label": "Page #{page}"), class: "pagination__item")
      end
    end

    def previous_page
      num = @collection.current_page > 1 && @collection.current_page - 1
      previous_or_next_page(num, I18n.t(:previous_label, scope: :pagination), "pagination__prev")
    end

    def next_page
      num = @collection.current_page < total_pages && @collection.current_page + 1
      previous_or_next_page(num, I18n.t(:next_label, scope: :pagination), "pagination__next")
    end

    def previous_or_next_page(page, text, classname, aria_label = nil)
      if page
        tag(:div, link(text, page), class: classname, "aria-label": aria_label)
      else
        ""
      end
    end

    def windowed_page_numbers
      inner_window = @options[:inner_window].to_i
      window_from = current_page - inner_window
      window_to = current_page + inner_window

      # adjust lower or upper limit if either is out of bounds
      if window_to > total_pages
        window_from -= window_to - total_pages
        window_to = total_pages
      end
      if window_from < 1
        window_to += 1 - window_from
        window_from = 1
        window_to = total_pages if window_to > total_pages
      end

      # these are always visible
      middle = window_from..window_to

      # left window
      if current_page > 4 # there's a gap
        left = [1, :gap]
      else # runs into visible pages
        left = 1...middle.first
      end

      # right window
      if total_pages - current_page > 3 # again, gap
        right = [:gap, total_pages]
      else # runs into visible pages
        right = (middle.last + 1)..total_pages
      end

      left.to_a + middle.to_a + right.to_a
    end
  end

  def paginate(petitions, options = {})
    options[:renderer] ||= PetitionPaginationRenderer
    options[:inner_window] ||= 1
    options[:container] = false

    tag.nav(class: "pagination", aria: { label: "Pagination" }) do
      concat(will_paginate(petitions, options))
    end
  end

  def filter_tag(name, label, value, current_values)
    capture do
      concat checkbox_tag("#{name}[]", value, current_values.include?(value), id: "#{name}_#{value}")
      concat label_tag(name, label, for: "#{name}_#{value}")
    end
  end
end
