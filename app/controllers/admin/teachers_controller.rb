class Admin::TeachersController < Admin::BaseController
  before_action :load_active_teacher, only: [:show, :edit, :update, :destroy]
  before_action :ensure_manual, only: [:edit, :update, :destroy]
  authorize_resource except: [:import, :import_template]
  before_action -> { authorize!(:manage, Teacher) }, only: [:import, :import_template]

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

  def import
    if request.get?
      @result = nil
      return
    end

    file = params[:file]
    if file.blank?
      flash.now[:alert] = "Выберите файл для загрузки"
      @result = nil
      return render :import, status: :unprocessable_entity
    end

    ext = File.extname(file.original_filename).delete(".").downcase
    unless %w[xlsx csv].include?(ext)
      flash.now[:alert] = "Поддерживаются только файлы xlsx и csv"
      @result = nil
      return render :import, status: :unprocessable_entity
    end

    @result = Teachers::AsAdmin::ImportFromFile.call(file_path: file.tempfile.path, extension: ext)
    render :import
  rescue ArgumentError => e
    flash.now[:alert] = e.message
    @result = nil
    render :import, status: :unprocessable_entity
  end

  def import_template
    io = StringIO.new
    workbook = WriteXLSX.new(io)
    sheet = workbook.add_worksheet("Преподаватели")
    header_format = workbook.add_format(bold: 1, bg_color: "#E5E7EB", border: 1)
    sheet.write_row(0, 0, ["ФИО", "СНИЛС", "ID в 1С"], header_format)
    sheet.write_row(1, 0, ["Иванов Иван Иванович", "11223344595", ""])
    sheet.write_row(2, 0, ["Петров Пётр Петрович", "15778846842", "EXT-1"])
    sheet.set_column(0, 0, 32)
    sheet.set_column(1, 1, 16)
    sheet.set_column(2, 2, 14)
    workbook.close

    send_data io.string,
      filename: "teachers_template.xlsx",
      type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
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
