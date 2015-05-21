module Staged
  class Stage < Struct.new(:model)
    def complete?; false; end

    def go(move)
      case move
      when 'back'
        go_back
      when 'next'
        if valid?
          go_next
        else
          stay
        end
      else
        stay
      end
    end

    def stay; self; end

    def valid?
      stage_object.valid?
    end
  end
end
