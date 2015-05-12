class StagedPetitionCreator
  def initialize(params, request, stage, move)
    @params = params
    @request = request
    @previous_stage = stage || 'petition'
    @move = move
  end

  # This is the stage we came from - the UI elements we showed the user
  # that generated these params
  attr_reader :previous_stage
  attr_reader :move

  def petition
    @_petition ||= build_petition
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

  def build_petition
    Petition.new(@params)
  end
end
