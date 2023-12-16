require 'scrypt'

module Devise
  module Encryptable
    module Encryptors
      class AuthlogicScrypt
        DEFAULTS = {
          key_len: 32,
          salt_size: 8,
          max_time: 0.2,
          max_mem: 1024 * 1024,
          max_memfrac: 0.5
        }

        def self.digest(password, stretches, salt, pepper)
          ::SCrypt::Password.create([password, salt].join, DEFAULTS)
        end

        def self.salt(stretches)
          SecureRandom.base58(20)
        end

        def self.compare(encrypted_password, password, stretches, salt, pepper)
          ::SCrypt::Password.new(encrypted_password) == [password, salt].join
        end
      end
    end
  end
end
