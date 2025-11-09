ActiveSupport.on_load(:active_record) do
  module PgVector
    module Types
      class Vector < ActiveRecord::Type::Value
        def type
          :vector
        end

        def serialize(value)
          if value.respond_to?(:to_ary)
            super("[#{value.to_ary.map(&:to_f).join(',')}]")
          else
            super(value)
          end
        end

        private

        def cast_value(value)
          if value.is_a?(String)
            value[1..-1].split(",").map(&:to_f)
          elsif value.respond_to?(:to_ary)
            value.to_ary.map(&:to_f)
          else
            raise "can't cast #{value.class.name} to halfvec"
          end
        end
      end

      class HalfVector < Vector
        def type
          :halfvec
        end
      end
    end

    module ColumnMethods
      extend ActiveSupport::Concern

      included do
        define_column_methods :vector, :halfvec
      end
    end

    module RegisterTypes
      def initialize_type_map(m = type_map)
        super

        register_class_with_limit m, "vector", PgVector::Types::Vector
        register_class_with_limit m, "halfvec", PgVector::Types::HalfVector
      end
    end
  end

  module ActiveRecord
    module ConnectionAdapters
      class PostgreSQLAdapter < AbstractAdapter
        NATIVE_DATABASE_TYPES[:halfvec] = { name: "halfvec" }
        NATIVE_DATABASE_TYPES[:vector] = { name: "vector" }

        class << self
          prepend(PgVector::RegisterTypes)
        end
      end

      TableDefinition.include(PgVector::ColumnMethods)
    end
  end

  ActiveRecord::Type.register(:vector, PgVector::Types::Vector)
  ActiveRecord::Type.register(:halfvec, PgVector::Types::HalfVector)
end
