class Admin::UsersController < Admin::BaseController
  load_and_authorize_resource

  def index
    @q = User.ransack(params[:q])
    users = @q.result
    users = users.where(kind_type: params[:kind].classify) if params[:kind].present?
    users = users.where(role: params[:role]) if params[:role].present?
    @users = paginate_entries(users).order(id: :asc)
  end

  def show
  end

  def update
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "Пользователь обновлён"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:role)
  end
end
