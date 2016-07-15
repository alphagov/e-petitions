class Task < ActiveRecord::Base
  validates :name, presence: true, length: { maximum: 60 }

  class << self
    def run(name, period = 12.hours, &block)
      task_for(name).send(:run, period, &block)
    end

    private

    def task_for(name)
      begin
        find_or_create_by!(name: name)
      rescue ActiveRecord::RecordNotUnique => e
        retry
      end
    end
  end

  private

  def run(period = 12.hours, &block)
    retry_lock do
      if pending?(period)
        block.call
        touch
      end
    end
  end

  def pending?(period)
    created_at == updated_at || updated_at < period.ago
  end

  def retry_lock
    retried = false

    begin
      with_lock { yield }
    rescue PG::InFailedSqlTransaction => e
      if retried
        raise e
      else
        retried = true
        self.class.connection.clear_cache!
        retry
      end
    end
  end
end
