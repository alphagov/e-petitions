require 'active_support/cache/dalli_store'

module ActiveSupport
  module Cache
    class AtomicDalliStore < DalliStore
      def fetch(name, options = nil)
        if block_given?
          result = read(name, options)

          if result.nil?
            result = instrument(:generate, name, options) do |payload|
              yield
            end

            write(name, result, options)
          else
            instrument(:fetch_hit, name, options) { |payload| }
          end

          result
        else
          read(name, options)
        end
      end

      def read(name, options = nil)
        super.tap do |result|
          if result.present?
            return nil if lock!(name, options)
          end
        end
      end

      def write(name, value, options = nil)
        expiry = (options && options[:expires_in]) || 0
        options[:expires_in] = expiry + 20 unless expiry.zero?
        ttl_set(ttl_key(name, options), expiry) && super
      end

      def delete(name, options = nil)
        ttl_delete(ttl_key(name, options)) && super
      end

      private

      def lock!(name, options)
        key = ttl_key(name, options)
        ttl_get(key) ? false : ttl_add(key)
      end

      def ttl_key(name, options)
        "#{namespaced_key(name, options)}.ttl"
      end

      def ttl_get(key)
        with { |c| c.get(key, raw: true) }
      rescue Dalli::DalliError => e
        logger.error("DalliError: #{e.message}") if logger
        raise if raise_errors?
        nil
      end

      def ttl_add(key)
        with { |c| c.add(key, "", 10, raw: true) }
      rescue Dalli::DalliError => e
        logger.error("DalliError: #{e.message}") if logger
        raise if raise_errors?
        false
      end

      def ttl_set(key, expiry)
        with { |c| c.set(key, "", expiry, raw: true) }
      rescue Dalli::DalliError => e
        logger.error("DalliError: #{e.message}") if logger
        raise if raise_errors?
        false
      end

      def ttl_delete(key)
        with { |c| c.delete(key) }
      rescue Dalli::DalliError => e
        logger.error("DalliError: #{e.message}") if logger
        raise if raise_errors?
        false
      end
    end
  end
end
