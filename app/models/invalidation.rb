class Invalidation < ActiveRecord::Base
  extend Searchable(:id, :summary, :details, :petition_id)
  include Browseable

  belongs_to :petition
  has_many :signatures

  facet :all,       -> { by_most_recent }
  facet :completed, -> { completed.by_most_recent }
  facet :cancelled, -> { cancelled.by_most_recent }
  facet :pending,   -> { pending.by_most_recent }
  facet :enqueued,  -> { enqueued.by_most_recent }
  facet :running,   -> { running.by_longest_running }

  CONDITIONS = %i[
    petition_id name postcode ip_address
    email constituency_id location_code
    created_before created_after
  ]

  validates :summary, presence: true, length: { maximum: 255 }
  validates :details, length: { maximum: 10000 }
  validates :petition_id, numericality: { only_integer: true, allow_blank: true, greater_than_or_equal_to: 100000 }
  validates :name, length: { maximum: 255, allow_blank: true }
  validates :postcode, length: { maximum: 255, allow_blank: true }
  validates :ip_address, length: { maximum: 20 }, format: { with: /\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\z/ }, allow_blank: true
  validates :email, length: { maximum: 255, allow_blank: true }
  validates :constituency_id, length: { maximum: 30, allow_blank: true }
  validates :location_code, length: { maximum: 30, allow_blank: true }

  validate do
    if applied_conditions.empty?
      errors.add :petition_id, "Please select some conditions, otherwise all signatures will be invalidated"
    end

    if petition_id?
      errors.add :petition_id, "Petition doesn't exist" unless Petition.exists?(petition_id)
    end

    if constituency_id?
      errors.add :constituency_id, "Constituency doesn't exist" unless Constituency.exists?(external_id: constituency_id)
    end

    if location_code?
      errors.add :location_code, "Location doesn't exist" unless Location.exists?(code: location_code)
    end

    if created_before? && created_after?
      errors.add :created_after, "Starting date is after the finishing date" unless created_before > created_after
    end
  end

  before_destroy do
    !started?
  end

  class << self
    def by_most_recent
      reorder(created_at: :desc)
    end

    def by_longest_running
      reorder(started_at: :asc)
    end

    def cancelled
      where(arel_table[:cancelled_at].not_eq(nil))
    end

    def completed
      where(arel_table[:completed_at].not_eq(nil))
    end

    def enqueued
      where(arel_table[:enqueued_at].not_eq(nil).and(arel_table[:started_at].eq(nil)))
    end

    def not_completed
      where(arel_table[:completed_at].eq(nil))
    end

    def pending
      where(enqueued_at: nil, started_at: nil, cancelled_at: nil, completed_at: nil)
    end

    def running
      started.not_completed
    end

    def started
      where(arel_table[:started_at].not_eq(nil))
    end
  end

  def cancel!(now = Time.current)
    return false if cancelled? || completed?

    update(cancelled_at: now)
  end

  def cancelled?
    cancelled_at?
  end

  def completed?
    completed_at?
  end

  def count!
    return false unless pending?

    update(matching_count: matching_signatures.count, counted_at: Time.current)
  end

  def start!
    return false unless pending?

    InvalidateSignaturesJob.perform_later(self)
    update(enqueued_at: Time.current)
  end

  def started?
    started_at?
  end

  def enqueued?
    enqueued_at?
  end

  def pending?
    !(enqueued? || started? || cancelled? || completed?)
  end

  def running?
    started? && !(completed? || cancelled?)
  end

  def percent_completed
    if started? || completed?
      matching_count.zero? ? 100 : calculate_percent_complete
    else
      matching_count.zero? ? 0 : calculate_percent_complete
    end
  end

  def matching_signatures
    scope = Signature.all
    scope = petition_scope(scope) if petition_id?
    scope = name_scope(scope) if name?
    scope = postcode_scope(scope) if postcode?
    scope = ip_address_scope(scope) if ip_address?
    scope = email_scope(scope) if email?
    scope = constituency_id_scope(scope) if constituency_id?
    scope = location_code_scope(scope) if location_code?
    scope = date_range_scope(scope) if date_range?

    scope
  end

  def invalidate!
    return if cancelled? || completed?

    update(
      started_at: Time.current,
      matching_count: matching_signatures.count,
      counted_at: Time.current
    )

    matching_signatures.find_in_batches(batch_size: 100) do |signatures|
      signatures.each do |signature|
        signature.invalidate!(Time.current, self)
        increment!(:invalidated_count)
      end

      reload and return if cancelled?
    end

    update(completed_at: Time.current)
  end

  private

  def petition_scope(scope)
    scope.where(petition_id: petition_id)
  end

  def name_scope(scope)
    scope.where("lower(name) LIKE ?", name.strip.downcase)
  end

  def postcode_scope(scope)
    scope.where(postcode: postcode)
  end

  def ip_address_scope(scope)
    scope.where(ip_address: ip_address)
  end

  def email_scope(scope)
    scope.where("email LIKE ?", email)
  end

  def constituency_id_scope(scope)
    scope.where(constituency_id: constituency_id)
  end

  def location_code_scope(scope)
    scope.where(location_code: location_code)
  end

  def date_range?
    created_before? || created_after?
  end

  def date_range_scope(scope)
    if created_before?
      scope = scope.where(table[:created_at].lt(created_before))
    end

    if created_after?
      scope = scope.where(table[:created_at].gt(created_after))
    end

    scope
  end

  def table
    Signature.arel_table
  end

  def calculate_percent_complete
    [[0, ((invalidated_count.to_f / matching_count.to_f) * 100).floor].max, 100].min
  end

  def applied_conditions
    CONDITIONS.select{ |c| read_attribute(c).present? }
  end
end
