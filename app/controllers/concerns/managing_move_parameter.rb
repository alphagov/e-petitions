module ManagingMoveParameter
  def assign_move
    move_value =
      if params.key? 'move:next'
        'next'
      elsif params.key? 'move:back'
        'back'
      elsif params.key? 'move'
        params['move']
      else
        'next'
      end
    move_value = 'next' unless ['next', 'back'].include? move_value
    params['move'] = move_value
  end
end
