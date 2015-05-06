class StagedPetitionCreator
  ERRORS_PER_STAGE = {
    'petition' => [:title, :department, :action, :description],
    'creator' =>  [:'creator_signature.name', :'creator_signature.email',
      :'creator_signature.email_confirmation', :'creator_signature.uk_citizenship',
      :'creator_signature.address', :'creator_signature.town',
      :'creator_signature.postcode', :'creator_signature.country'],
    'sponsors' => [:sponsors, :sponsor_emails],
    'submit' => [:'creator_signature.terms_and_conditions']
  }

  def initialize(params, request)
    @params = params
    @request = request
  end

  def petition
    @petition ||= build_petition
  end

  def stage
    @stage ||= calculate_stage
  end

  def sanitize!
    if creator_signature
      creator_signature.email.strip! unless creator_signature.email.blank?
      creator_signature.ip_address = @request.remote_ip
      creator_signature.notify_by_email = true
    end
    title.strip!
  end

  delegate :id, :to_param, :errors, :save, :model_name, :to_key,
           :title, :action, :department, :department_id, :description,
           :duration, :sponsors, :sponsor_emails, :errors, :creator_signature,
           to: :petition

  def stage_errors
    errors.to_hash.slice(errors_for_stage(stage))
  end

  private

  def calculate_stage
    if @params[:stage]
      @params[:stage]
    elsif errors.any? { |field, _| errors_for_stage('petition').include? field }
      'petition'
    elsif errors.any? { |field, _| errors_for_stage('creator').include? field }
      'creator'
    elsif errors.any? { |field, _| errors_for_stage('sponsors').include? field }
      'sponsors'
    elsif errors.any? { |field, _| errors_for_stage('submit').include? field }
      'submit'
    else
      'petition'
    end
  end

  def errors_for_stage(stage)
    self.class::ERRORS_PER_STAGE.fetch(stage, [])
  end

  def sanitized_params
    @_sanitized_params ||= sanitize_params
  end

  def sanitize_params
    @params.
      fetch('petition', {}).
      permit(:title, :action, :description, :duration, :department_id,
             :sponsor_emails,
             creator_signature: [
               :name, :email, :email_confirmation, :address, :town,
               :postcode, :country, :uk_citizenship,
               :terms_and_conditions, :notify_by_email
             ]).tap do |sanitized|
               if sanitized['creator_signature'].present?
                 sanitized['creator_signature_attributes'] = sanitized.delete('creator_signature')
               end
               if sanitized['sponsor_emails']
                 sanitized['sponsor_emails'] = parse_emails(sanitized['sponsor_emails'])
               end
             end
  end

  def build_petition
    Petition.new(sanitized_params).tap do |p|
      p.build_creator_signature(:country => 'United Kingdom') if p.creator_signature.nil?
    end
  end

  def parse_emails(emails)
    emails.strip.split(/\r?\n/).map { |e| e.strip }
  end
end
