class FillPersonalInfoJob < ApplicationJob
  queue_as :default
  discard_on ActiveRecord::RecordNotFound

  def perform(user_id)
    user = User.find(user_id)
    Students::Operations::FillPersonalInfo.new.call(student: user.kind) if user.student?
  end
end
