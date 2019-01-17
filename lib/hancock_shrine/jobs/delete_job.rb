if defined?(ActiveJob)
  # class DeleteJob < ApplicationJob
  class DeleteJob < ActiveJob::Base
    queue_as :shrine_queue

    def perform(data)
      # puts 'DeleteJob'
      # puts data.inspect
      shrine_class = ((data["shrine_class"] and data["shrine_class"].constantize) || Shrine)
      attacher = shrine_class::Attacher.delete(data) 
      # OR
      # attacher = Shrine::Attacher.delete(data)  # finish deleting (`backgrounding` plugin)
      # puts attacher.inspect
      attacher and attacher.record and attacher.record.touch
    end
  end
end
