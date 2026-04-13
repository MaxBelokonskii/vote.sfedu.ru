module Teachers
  class StudentsController < Teachers::BaseController
    authorize_resource

    def index
      @teacher = current_user.teacher || current_user.kind
      relations = @teacher&.students_teachers_relations || StudentsTeachersRelation.none
      @students = Student.where(id: relations.distinct.pluck(:student_id)).order(:name)
    end
  end
end
