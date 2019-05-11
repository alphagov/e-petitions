class Domain < ActiveRecord::Base
  PATTERN = /\A(?:\*|\*\.[a-z]{2,}|(?:\*\.)*(?:[a-z0-9][a-z0-9-]{0,61}[a-z0-9]\.)+[a-z]{2,})\z/

  with_options class_name: "::Domain" do
    belongs_to :canonical_domain, required: false
    has_many :aliases, foreign_key: "canonical_domain_id", dependent: :destroy
  end

  validates :name, presence: true
  validates :name, uniqueness: { case_sensitive: false }
  validates :name, format: { with: PATTERN }
  validates :name, length: { maximum: 100 }

  validates :strip_characters, length: { maximum: 10 }
  validates :strip_extension, length: { maximum: 10 }

  validate if: :aliased_domain? do
    if aliased_domain? && !canonical_domain.present?
      errors.add(:aliased_domain, :not_found)
    end
  end

  attr_writer :aliased_domain

  before_validation if: :aliased_domain? do
    self.canonical_domain = find_canonical_domain
    self.strip_characters = nil
    self.strip_extension  = nil
  end

  before_validation unless: :aliased_domain? do
    self.canonical_domain = nil
  end

  class << self
    def default_scope
      preload(:canonical_domain)
    end

    def by_name
      order(:name)
    end

    def normalize(email)
      unless email.is_a?(Mail::Address)
        email = Mail::Address.new(email)
      end

      rule(email.domain).normalize(email)
    rescue Mail::Field::ParseError
      email
    end

    private

    def candidates(domain)
      [domain].tap { |c| domain.scan(?.) { c << %[*.#{$'}] } } + %w[*]
    end

    def rules(domain)
      candidates(domain).lazy.map { |c| find_by(name: c) }
    end

    def rule(domain)
      rules(domain).detect(-> { default_domain }) { |d| d.present? }
    end

    def default_domain
      begin
        find_or_create_by(name: "*", strip_extension: "+")
      rescue ActiveRecord::RecordNotUnique => e
        retry
      end
    end
  end

  def aliased_domain
    @aliased_domain || canonical_domain.try(:name)
  end

  def aliased_domain?
    aliased_domain.present?
  end

  def aliased_domains
    aliases.by_name.pluck(:name).join(", ")
  end

  def alias?
    canonical_domain.present?
  end

  def alias
    canonical_domain.name
  end

  def name=(value)
    super(value.to_s.downcase.strip)
  end

  def strip_characters?
    alias? ? canonical_domain.strip_characters? : super
  end

  def strip_characters
    alias? ? canonical_domain.strip_characters : super
  end

  def strip_extension?
    alias? ? canonical_domain.strip_extension? : super
  end

  def strip_extension
    alias? ? canonical_domain.strip_extension : super
  end

  def normalize(email)
    "#{local(email)}@#{domain(email)}"
  rescue Mail::Field::ParseError
    email
  end

  private

  def find_canonical_domain
    self.class.find_by(name: aliased_domain)
  end

  def local(email)
    email.local.dup.tap do |normalized|
      if strip_characters?
        normalized.gsub!(characters_regexp, "")
      end

      if strip_extension?
        normalized.gsub!(extension_regexp, "\\1")
      end
    end
  end

  def domain(email)
    alias? ? canonical_domain.name : email.domain
  end

  def characters_regexp
    Regexp.union(strip_characters.chars)
  end

  def extension_regexp
    range = Regexp.escape(strip_extension)
    /\A([^#{range}]+)[#{range}].+\z/
  end
end
