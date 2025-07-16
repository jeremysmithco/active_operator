# frozen_string_literal: true

module ActiveOperator
  class PerformOperationJob < ActiveJob::Base
    discard_on ActiveRecord::RecordNotFound

    def perform(operation, force: false)
      operation.perform(force:)
    end
  end
end
