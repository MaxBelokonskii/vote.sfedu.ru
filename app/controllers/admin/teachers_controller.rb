class Admin::TeachersController < Admin::BaseController
  before_action :load_active_teacher, only: [:show, :edit, :update, :destroy]
  before_action :ensure_manual, only: [:edit, :update, :destroy]
  authorize_resource

  def index
    @q = Teacher.active.ransack(params[:q])
    @teachers = paginate_entries(@q.result).order(id: :asc)
  end

  def show
    @results = Stage.active.map { |stage|
      {
        stage: stage,
        results: stage.calculation_rule_klass.new(@teacher, stage).call
      }
    }
  end

  def new
    @teacher = Teacher.new(origin: :manual, kind: :common)
  end

  def create
    @teacher = Teacher.new(teacher_params.merge(origin: :manual))
    if @teacher.save
      redirect_to admin_teacher_path(@teacher), notice: "Преподаватель создан"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @teacher.update(teacher_params)
      redirect_to admin_teacher_path(@teacher), notice: "Преподаватель обновлён"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @teacher.soft_delete!
    redirect_to admin_teachers_path, notice: "Преподаватель удалён"
  end

  private

  def teacher_params
    params.require(:teacher).permit(:name, :kind, :snils, :external_id)
  end

  def load_active_teacher
    @teacher = Teacher.active.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_teachers_path, alert: "Преподаватель не найден"
  end

  def ensure_manual
    return if @teacher.editable_by_admin?
    redirect_to admin_teacher_path(@teacher), alert: "Импортированных из 1С преподавателей нельзя редактировать через UI"
  end
end
