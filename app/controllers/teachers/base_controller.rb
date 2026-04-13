module Teachers
  class BaseController < ApplicationController
    layout "teacher"
    before_action :authenticate_user!
    before_action :ensure_teacher

    rescue_from CanCan::AccessDenied do |_exception|
      redirect_to root_path
    end

    private

    def ensure_teacher
      redirect_to root_path unless current_user&.teacher?
    end
  end
end
