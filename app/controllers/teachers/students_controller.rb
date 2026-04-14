module Teachers
  class StudentsController < Teachers::BaseController
    authorize_resource

    def index
      @teacher = current_teacher
      relations = @teacher&.students_teachers_relations || StudentsTeachersRelation.none
      @students = Student.where(id: relations.distinct.select(:student_id)).order(:name)
    end
  end
end
