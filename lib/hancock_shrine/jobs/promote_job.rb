if defined?(ActiveJob)
  # class PromoteJob < ApplicationJob
  class PromoteJob < ActiveJob::Base
    queue_as :shrine_queue

    def perform(data)
      # puts 'PromoteJob'
      # puts data.inspect
      shrine_class = ((data["shrine_class"] and data["shrine_class"].constantize) || Shrine)
      attacher = shrine_class::Attacher.promote(data) 
      # OR
      # attacher = Shrine::Attacher.promote(data)  # finish promoting (`backgrounding` plugin)
      # puts attacher.inspect
      # puts attacher
      # puts attacher and attacher.record 
      # puts attacher and attacher.record and attacher.record.touch
      # attacher and attacher.record and attacher.record.touch
    end
  end
end
