class StagedPetitionCreator
  ERRORS_PER_STAGE = {
    'petition' => [:title, :department, :action, :description],
    'creator' => [:creator_signature, :'creator_signature.name',
      :'creator_signature.email', :'creator_signature.email_confirmation',
      :'creator_signature.uk_citizenship', :'creator_signature.address',
      :'creator_signature.town', :'creator_signature.postcode',
      :'creator_signature.country'],
    'sponsors' => [:sponsors, :sponsor_emails],
    'submit' => [:'creator_signature.terms_and_conditions']
  }

  def initialize(params, request)
    @params = params
    @request = request
  end

  def petition
    @_petition ||= build_petition
  end

  # This is the stage we came from - the UI elements we showed the user
  # that generated these params
  def previous_stage
    @_previous_stage ||= @params.fetch('stage', 'petition')
  end

  # This is the stage we are going to - the UI elements we will show the
  # user depending on their input.
  def stage
    @_stage ||= calculate_stage
  end

  delegate :id, :to_param, :errors, :model_name, :to_key,
           :title, :action, :department, :department_id, :description,
           :duration, :sponsors, :sponsor_emails, :errors, :creator_signature,
           to: :petition

  def creator_signature!
    if creator_signature.nil?
      petition.build_creator_signature(country: 'United Kingdom')
    end
    creator_signature
  end

  def previous_stage_errors
    errors.to_hash.slice(errors_for_stage(previous_stage))
  end

  def create
    sanitize!
    validate!
    if stage == 'done'
      petition.save
    else
      false
    end
  end

  def moving_backwards?
    move == 'back'
  end

  def moving_forwards?
    move == 'next'
  end

  private

  def sanitize!
    if creator_signature
      creator_signature.email.strip! unless creator_signature.email.blank?
      creator_signature.ip_address = @request.remote_ip
      creator_signature.notify_by_email = true
    end
    title.strip! unless title.blank?
  end

  def validate!
    petition.valid?
  end

  def move
    @_move ||= @params['move']
  end

  STAGES = {
    'petition' => { 'next' => 'creator', 'back' => 'petition' },
    'creator' => { 'next' => 'sponsors', 'back' => 'petition' },
    'sponsors' => { 'next' => 'submit', 'back' => 'creator' },
    'submit' => { 'next' => 'done', 'back' => 'creator' }
  }

  # In order:
  # 1. the user wants to go back - let them
  # 2. the user entered invalid data - show them the same UI again
  # 3. the user somehow entered invalid data for some other step - show them that UI
  # 4. the user wants to go forward - show them the next UI
  # 5. the user somehow hasn't indicated what they want to do - show them the same UI again
  def calculate_stage
    if moving_backwards?
      STAGES[previous_stage]['back']
    elsif previous_stage_errors.any?
      previous_stage
    elsif errors.any?
      earliest_error_stage
    elsif moving_forwards?
      STAGES[previous_stage]['next']
    else
      previous_stage
    end
  end

  def earliest_error_stage
    if errors.any? { |field, _| errors_for_stage('petition').include? field }
      'petition'
    elsif errors.any? { |field, _| errors_for_stage('creator').include? field }
      'creator'
    elsif errors.any? { |field, _| errors_for_stage('sponsors').include? field }
      'sponsors'
    elsif errors.any? { |field, _| errors_for_stage('submit').include? field }
      'submit'
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
    Petition.new(sanitized_params)
  end

  def parse_emails(emails)
    emails.strip.split(/\r?\n/).map { |e| e.strip }
  end
end
