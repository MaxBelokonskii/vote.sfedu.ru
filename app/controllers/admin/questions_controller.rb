class Admin::QuestionsController < Admin::BaseController
  load_and_authorize_resource

  def index
    @questions = Question.order(:text)
  end

  def show
  end

  def new
    @question = Question.new(max_rating: 10)
  end

  def create
    @question = Question.new(question_params)
    respond_to do |format|
      if @question.save
        format.html { redirect_to admin_questions_path, notice: "Критерий успешно создан" }
        format.json { render json: {id: @question.id, text: @question.text, max_rating: @question.max_rating}, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: {errors: @question.errors.full_messages}, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    if @question.update(question_params)
      redirect_to admin_question_path(@question), notice: "Критерий успешно обновлён"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @question.used_in_stages?
      redirect_to admin_questions_path, alert: "Нельзя удалить критерий: используется в стадиях анкетирования"
    else
      @question.destroy
      redirect_to admin_questions_path, notice: "Критерий удалён"
    end
  end

  private

  def question_params
    params.require(:question).permit(:text, :max_rating)
  end
end
