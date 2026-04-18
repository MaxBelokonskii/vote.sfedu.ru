module Admin
  module Polls
    class PollOptionsController < Admin::BaseController
      authorize_resource class: "Poll::Option"
      before_action :load_poll
      before_action :ensure_not_started, only: [:new, :create, :destroy]

      def new
        @poll_option = Poll::Option.new
      end

      def create
        @poll_option = Poll::Option.new(create_params.merge(poll: @poll))
        if @poll_option.save
          flash[:success] = "Вариант ответа успешно добавлен к голосованию"
          redirect_to admin_poll_path(@poll)
        else
          render :new, status: :unprocessable_entity
        end
      end

      def destroy
        @poll_option = Poll::Option.find(params[:id])
        @poll_option.destroy

        flash[:success] = "Вариант ответа успешно удален из голосования"
        redirect_to admin_poll_path(@poll)
      end

      private

      def load_poll
        @poll = Poll.find(params[:poll_id])
      end

      def ensure_not_started
        return unless @poll.started?
        flash[:error] = "Нельзя изменять варианты уже начавшегося голосования"
        redirect_to admin_poll_path(@poll)
      end

      def create_params
        permitted = params.require(:poll_option).permit(:title, :description, :image)
        permitted = permitted.except(:image) if permitted[:image].blank?
        permitted
      end
    end
  end
end
