class LoadTeachersJob < ApplicationJob
  queue_as :default
  discard_on ActiveRecord::RecordNotFound

  def perform(student_id)
    student = Student.find(student_id)
    Teachers::AsStudent::FetchFromDataSource.run(student: student)
  end
end
