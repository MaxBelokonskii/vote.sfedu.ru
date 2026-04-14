module Teachers
  class DashboardController < Teachers::BaseController
    def show
      @teacher = current_teacher
      @surveys_count = Survey.where(user: current_user).count
    end
  end
end
