class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user.present?

    if user.teacher?
      can %i[read create update], Survey
      teacher = user.kind
      can :index, Student, id: teacher.students_teachers_relations.select(:student_id) if teacher.is_a?(Teacher)
    end

    if user.student?
      can %i[index refresh prepare choose], Teacher
      can %i[show respond], Teacher do |teacher|
        Teachers::AvailableTeachersForStudent.new(stage: Stage.current, student: user.kind).call.include?(teacher)
      end
    end
  end
end
