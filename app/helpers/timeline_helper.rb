module TimelineHelper
  module Items
    class BaseItem
      with_options instance_writer: false do
        class_attribute :scope, :timestamp
      end

      attr_reader :petition, :template, :completed
      delegate :t, :short_date_format, to: :template

      def initialize(petition, template, completed: false)
        @petition = petition
        @template = template
        @completed = completed
      end

      def title
        t(:title, scope: :"timeline.#{scope}", **i18n)
      end

      def description
        t(:description_html, scope: :"timeline.#{scope}", **i18n)
      end

      def occurred_at
        petition.instance_exec(&timestamp)
      end

      private

      def i18n
        {}.tap do |hash|
          hash[:debate_threshold] = Site.formatted_threshold_for_debate
          hash[:response_threshold] = Site.formatted_threshold_for_response

          if petition.closed?
            hash[:closing_date] = short_date_format(petition.closed_at)
            hash[:iso_closing_date] = petition.closed_at.to_date.iso8601
          else
            hash[:closing_date] = short_date_format(petition.deadline)
            hash[:iso_closing_date] = petition.deadline.to_date.iso8601
          end

          if petition.debate_scheduled?
            hash[:debate_date] = short_date_format(petition.scheduled_debate_date)
            hash[:iso_debate_date] = petition.scheduled_debate_date.iso8601
          end
        end
      end
    end

    class PublishedItem < BaseItem
      self.scope = :published
      self.timestamp = -> { published_at }
    end

    class ClosesItem < BaseItem
      self.scope = :closes
      self.timestamp = -> { deadline }
    end

    class ClosedItem < BaseItem
      self.scope = :closed
      self.timestamp = -> { closed_at }
    end

    class ResponseTargetItem < BaseItem
      self.scope = :response_target
      self.timestamp = -> { deadline - 2.minutes }
    end

    class DebateTargetItem < BaseItem
      self.scope = :debate_target
      self.timestamp = -> { deadline - 1.minute }
    end

    class AwaitingResponseItem < BaseItem
      self.scope = :awaiting_response
      self.timestamp = -> { response_threshold_reached_at }
    end

    class ResponsedItem < BaseItem
      self.scope = :responded
      self.timestamp = -> { government_response_at }
    end

    class DebatedItem < BaseItem
      self.scope = :debated
      self.timestamp = -> { debate_outcome_at || scheduled_debate_date.beginning_of_day }
    end

    class NotDebatedItem < BaseItem
      self.scope = :not_debated
      self.timestamp = -> { debate_outcome_at || scheduled_debate_date.beginning_of_day }
    end

    class DebatedScheduledItem < BaseItem
      self.scope = :debate_scheduled
      self.timestamp = -> { scheduled_debate_date.beginning_of_day }
    end

    class AwaitingDebateItem < BaseItem
      self.scope = :awaiting_debate
      self.timestamp = -> { debate_threshold_reached_at }
    end
  end

  def petition_timeline(petition)
    return unless petition.published?

    items = []
    items << Items::PublishedItem.new(petition, self, completed: true)

    if petition.closed?
      items << Items::ClosedItem.new(petition, self, completed: true)
    else
      items << Items::ClosesItem.new(petition, self, completed: false)
    end

    if petition.debated?
      items << Items::DebatedItem.new(petition, self, completed: true)
    elsif petition.not_debated?
      items << Items::NotDebatedItem.new(petition, self, completed: true)
    elsif petition.debate_scheduled?
      items << Items::DebateScheduledItem.new(petition, self, completed: true)
    elsif petition.awaiting_debate_decision?
      items << Items::AwaitingDebateItem.new(petition, self, completed: false)
    elsif petition.open?
      items << Items::DebateTargetItem.new(petition, self, completed: false)
    end

    if petition.responded?
      items << Items::ResponsedItem.new(petition, self, completed: true)
    elsif petition.awaiting_response?
      items << Items::AwaitingResponseItem.new(petition, self, completed: false)
    elsif petition.open?
      items << Items::ResponseTargetItem.new(petition, self, completed: false)
    end

    yield items.sort_by(&:occurred_at)
  end
end
