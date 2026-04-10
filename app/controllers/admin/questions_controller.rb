class Admin::QuestionsController < Admin::BaseController
  load_and_authorize_resource

  def index
  end

  def show
  end

  def create
    @question = Question.new(question_params)
    if @question.save
      render json: {id: @question.id, text: @question.text, max_rating: @question.max_rating}, status: :created
    else
      render json: {errors: @question.errors.full_messages}, status: :unprocessable_entity
    end
  end

  private

  def question_params
    params.require(:question).permit(:text, :max_rating)
  end
end
