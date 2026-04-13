class Admin::TeachersController < Admin::BaseController
  load_and_authorize_resource

  before_action :ensure_manual, only: [:edit, :update, :destroy]

  def index
    @q = Teacher.active.ransack(params[:q])
    @teachers = paginate_entries(@q.result).order(id: :asc)
  end

  def show
    @results = Stage.all.map { |stage|
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
      @teacher.encrypt_snils! if @teacher.snils.present?
      redirect_to admin_teacher_path(@teacher), notice: "Преподаватель создан"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @teacher.update(teacher_params)
      @teacher.encrypt_snils! if @teacher.snils.present?
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

  def ensure_manual
    return if @teacher.editable_by_admin?
    redirect_to admin_teacher_path(@teacher), alert: "Импортированных из 1С преподавателей нельзя редактировать через UI"
  end
end
