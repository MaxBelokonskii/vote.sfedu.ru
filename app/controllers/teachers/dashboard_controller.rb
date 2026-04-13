module Teachers
  class DashboardController < Teachers::BaseController
    def show
      @teacher = current_user.teacher || current_user.kind
      @surveys_count = Survey.where(user: current_user).count
    end
  end
end
