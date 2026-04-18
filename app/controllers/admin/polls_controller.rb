module Admin
  class PollsController < Admin::BaseController
    load_and_authorize_resource
    before_action :ensure_editable, only: [:edit, :update]

    def new
      @poll = Poll.new
      load_form_collections
    end

    def create
      @poll = Poll.new(poll_params)
      if @poll.save
        flash[:success] = "Голосование успешно создано"
        redirect_to admin_poll_path(@poll)
      else
        load_form_collections
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      load_form_collections
    end

    def update
      if @poll.update(poll_params)
        flash[:success] = "Голосование успешно обновлено"
        redirect_to admin_poll_path(@poll)
      else
        load_form_collections
        render :edit, status: :unprocessable_entity
      end
    end

    def index
      @polls = @polls.order(starts_at: :desc)
    end

    def show
      @options = @poll.options
    end

    def archive
      @poll.update(archived_at: Time.current)

      redirect_to admin_polls_path
    end

    def destroy
      ::Polls::AsAdmin::RemovePoll.new.call(poll: @poll) do |monad|
        monad.success do |result|
          respond_with(:success, "Опрос успешно удален")
          redirect_to admin_polls_path
        end

        monad.failure do
          respond_with(:error, "К сожалению, уже невозможно удалить этот опрос")
          redirect_to admin_poll_path(@poll)
        end
      end
    end

    private

    def respond_with(kind, msg)
      flash[kind] = msg
    end

    def load_form_collections
      @faculties = Faculty.all.order(name: :asc)
    end

    def ensure_editable
      return if @poll.editable_by_admin?
      redirect_to admin_poll_path(@poll), alert: "Редактировать можно только предстоящее неархивное голосование"
    end

    def poll_params
      parameters = params.require(:poll).permit(:name, :starts_at, :ends_at, faculty_ids: [])
      parameters[:faculty_ids] = Array(parameters[:faculty_ids]).map(&:presence).compact.map(&:to_i)
      parameters
    end
  end
end
