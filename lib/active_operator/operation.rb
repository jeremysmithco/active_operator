# frozen_string_literal: true

module ActiveOperator
  class Operation < ActiveRecord::Base
    self.table_name = "active_operator_operations"

    belongs_to :record, polymorphic: true

    def received?  = received_at?
    def processed? = processed_at?
    def errored?   = errored_at?

    def perform(force: false)
      request!(force:)
      process!(force:)
    rescue
      errored!
      raise
    end

    def perform_later(force: false)
      ActiveOperator::PerformOperationJob.perform_later(self, force:)
    end

    def request!(force: false)
      return false if received? && !force

      update!(response: request, received_at: Time.current)
    end

    def process!(force: false)
      return false if !received?
      return false if processed? && !force

      ActiveRecord::Base.transaction do
        process
        update!(processed_at: Time.current)
      end
    end

    def errored!
      update!(errored_at: Time.current)
    end

    def request
      raise NotImplementedError, "Operations must implement the `request` method"
    end

    def process
      raise NotImplementedError, "Operations must implement the `process` method"
    end
  end
end
