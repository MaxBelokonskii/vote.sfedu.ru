class Admin::StagesController < Admin::BaseController
  load_and_authorize_resource

  def index
    @stages = Stage.active.order(starts_at: :desc)
  end

  def show
    respond_to do |format|
      format.html {}
      format.xlsx do
        io_string = Stages::ProgressReport.run!(stage: @stage)
        send_data(
          io_string,
          filename: "ВыгрузкаПоФакультетам-#{I18n.l(Time.current, format: :slug)}.xlsx",
          disposition: "attachment",
          type: Mime::Type.lookup_by_extension(:xlsx)
        )
      end
    end
  end

  def new
    @stage = Stage.new(
      lower_participants_limit: 10,
      scale_min: 6,
      scale_max: 10,
      lower_truncation_percent: 5,
      upper_truncation_percent: 5,
      with_scale: true,
      with_truncation: true
    )
    load_form_collections
  end

  def create
    @stage = Stage.new(stage_params.except(:new_questions_attributes))
    create_and_attach_new_questions
    if @stage.save
      redirect_to admin_stage_path(@stage), notice: "Стадия успешно создана"
    else
      load_form_collections
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_form_collections
  end

  def update
    @stage.assign_attributes(stage_params.except(:new_questions_attributes))
    create_and_attach_new_questions
    if @stage.save
      redirect_to admin_stage_path(@stage), notice: "Стадия успешно обновлена"
    else
      load_form_collections
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @stage.soft_delete!
    redirect_to admin_stages_path, notice: "Стадия удалена"
  end

  private

  def stage_params
    params.require(:stage).permit(
      :starts_at, :ends_at,
      :lower_participants_limit,
      :with_scale, :scale_min, :scale_max,
      :with_truncation, :lower_truncation_percent, :upper_truncation_percent,
      semester_ids: [],
      question_ids: [],
      new_questions_attributes: [:text, :max_rating]
    )
  end

  def load_form_collections
    @semesters = Semester.order(year_begin: :desc, kind: :asc)
    @questions = Question.order(:text)
  end

  def create_and_attach_new_questions
    new_attrs = stage_params[:new_questions_attributes]
    return if new_attrs.blank?

    new_attrs.each_value do |attrs|
      next if attrs[:text].blank?
      question = Question.create!(text: attrs[:text], max_rating: attrs[:max_rating] || 10)
      @stage.questions << question
    end
  end
end
