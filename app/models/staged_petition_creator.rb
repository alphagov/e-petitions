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
    @_stage ||= next_or_previous?(next_result: next_stage, previous_result: previous_stage)
  end

  def next_stage
    @_next_stage ||= calculate_next_stage
  end

  def previous_stage_object
    @_previous_stage_object ||= object_for_stage(previous_stage)
  end

  def stage_object
    @_stage_object ||= next_or_previous?(next_result: object_for_stage(next_stage), previous_result: previous_stage_object)
  end

  def object_for_stage(stage)
    case stage
    when 'petition'
      Staged::Petition.new(petition)
    when 'creator'
      Staged::Creator.new(petition)
    when 'sponsors'
      Staged::Sponsors.new(petition)
    when 'submit'
      Staged::Submit.new(petition)
    when 'done'
      petition
    end
  end

  def next_or_previous?(next_result:, previous_result:)
    @_next_or_previous ||= calculate_next_or_previous
    case @_next_or_previous
    when :next
      next_result
    when :previous
      previous_result
    end
  end

  def calculate_next_or_previous
    if moving_backwards?
      :next
    elsif create_petition
      :next
    elsif previous_stage_object.errors.none?
      :next
    else
      :previous
    end
  end

  def create_petition
    @_creat_petition ||= try_to_create_petition
  end

  def try_to_create_petition
    if moving_backwards?
      false
    elsif moving_forwards?
      sanitize!
      validate!
      if next_stage == 'done'
        petition.save
      else
        false
      end
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
    if petition.creator_signature
      petition.creator_signature.email.strip! unless petition.creator_signature.email.blank?
      petition.creator_signature.ip_address = @request.remote_ip
      petition.creator_signature.notify_by_email = true
    end
    petition.title.strip! unless petition.title.blank?
  end

  def validate!
    previous_stage_object.valid?
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

  # Here we calculate the next stage the user is trying to
  # get to (validating if they can get there happens elsewhere):
  # 1. the user wants to go back - let them
  # 2. the user wants to go forward - show them the next UI
  # 3. the user somehow hasn't indicated what they want to do - show them the same UI again
  def calculate_next_stage
    if moving_backwards?
      STAGES[previous_stage]['back']
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
