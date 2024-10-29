require 'zlib'

module SessionAdvisoryLock
  extend ActiveSupport::Concern

  class LockFailedError < RuntimeError; end

  included do
    delegate :connection, to: :"ActiveRecord::Base"
    delegate :select_value, to: :connection

    lock_id = Zlib.crc32(self.name)
    lock_sql = "SELECT pg_try_advisory_lock(#{lock_id})"
    unlock_sql = "SELECT pg_advisory_unlock(#{lock_id})"

    define_method :get_advisory_lock do
      select_value(lock_sql)
    end

    define_method :release_advisory_lock do
      select_value(unlock_sql)
    end
  end

  private

  def with_lock
    unless locked = get_advisory_lock
      raise LockFailedError, "Unable to obtain advisory lock, check for concurrent #{self.class.name} jobs"
    end

    yield
  ensure
    release_advisory_lock if locked
  end
end
