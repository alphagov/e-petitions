module WelshPets
  module Routing
    extend ActiveSupport::Concern

    class LocalizedRoutes
      class Scope
        POISON  = Object.new
        OPTIONS = %i[path controller action format as constraints localized via]

        def initialize(options, parent)
          if parent
            @options = parent.merge(options)
            @parent  = parent
          else
            @options = options
          end
        end

        def new(options)
          Scope.new(options, self)
        end

        def parent
          @parent || self
        end

        def merge(**options)
          {}.tap do |scope|
            OPTIONS.each do |option|
              value = if @options.key?(option)
                if options.key?(option)
                  merge_option(option, @options[option], options[option])
                else
                  @options[option]
                end
              elsif options.key?(option)


                options[option]
              else
                POISON
              end

              unless value == POISON
                scope[option] = value
              end
            end
          end
        end

        def route(**options)
          Route.new(options, self)
        end

        def [](option)
          @options[option]
        end

        private

        def normalize_path(path)
          path.squeeze("/").chomp("/")
        end

        def merge_option(option, parent, child)
          case option
          when :path
            normalize_path("#{parent}/#{child}")
          when :constraints
            (parent || {}).merge(child)
          else
            child
          end
        end
      end

      class Route < Scope
        def initialize(options, parent)
          super

          unless @options[:controller]
            raise ArgumentError, "Please specify a controller for the route"
          end

          unless @options[:action]
            raise ArgumentError, "Please specify an action for the route"
          end
        end

        def path(locale)
          localized_path(@options[:path], locale)
        end

        def options(suffix)
          {}.tap do |opts|
            opts[:controller] = @options[:controller]
            opts[:action] = @options[:action]
            opts[:as] = localized_as(@options[:as], suffix)
            opts[:via] = @options[:via]

            if @options.key?(:constraints)
              opts[:constraints] = @options[:constraints]
            end

            opts[:defaults] = { route: name }

            if @options.key?(:format)
              opts[:format] = @options[:format]
            end
          end
        end

        def redirect(suffix)
          Redirect.new(localized_as(@options[:as], suffix))
        end

        def via
          @options[:via]
        end

        def name
          @options[:as]
        end

        def localized?
          @options.key?(:localized) ? @options[:localized] : true
        end

        private

        def localized_path(path, locale)
          if localized?
            I18n.t locale, scope: "routes.#{path}", default: path
          else
            path
          end
        end

        def localized_as(as, suffix)
          unless as.nil? || suffix.nil?
            :"#{as}_#{suffix}"
          end
        end
      end

      class Redirect
        include Rails.application.routes.url_helpers

        def initialize(route)
          @route = route
        end

        def call(params, request)
          public_send(:"#{@route}_url", params.merge(request.query_parameters))
        end
      end

      attr_reader :routes

      def initialize
        @routes = []
        @scope  = Scope.new({}, nil)
      end

      def draw(&block)
        instance_exec(&block)
      end

      def scope(path = nil, **options)
        @scope = @scope.new(options.merge(path: path))
        yield
      ensure
        @scope = @scope.parent
      end

      def get(path, **options)
        @routes << @scope.route(options.merge(path: path, via: :get))
      end

      def post(path, **options)
        @routes << @scope.route(options.merge(path: path, via: :post))
      end

      def each(&block)
        @routes.each(&block)
      end
    end

    def public_scope(&block)
      routes = LocalizedRoutes.new
      routes.draw(&block)

      constraints(Site.constraints_for_public_en) do
        defaults locale: "en-GB" do
          routes.each do |route|
            match route.path("en-GB"), route.options("en")

            if route.localized?
              match route.path("cy-GB"), to: redirect(route.redirect("en"), status: 308), via: route.via, as: nil
            end
          end
        end
      end

      constraints(Site.constraints_for_public_cy) do
        defaults locale: "cy-GB" do
          routes.each do |route|
            match route.path("cy-GB"), route.options("cy")

            if route.localized?
              match route.path("en-GB"), to: redirect(route.redirect("cy"), status: 308), via: route.via, as: nil
            end
          end
        end
      end

      routes.each do |route|
        route_en = :"#{route.name}_en"
        route_cy = :"#{route.name}_cy"

        direct(route.name) do |*args|
          route_for((I18n.locale == :"en-GB" ? route_en : route_cy), *args)
        end
      end
    end

    def moderation_scope(&block)
      constraints(Site.constraints_for_moderation, &block)
    end
  end
end
