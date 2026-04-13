import { Application } from "@hotwired/stimulus"

const application = Application.start()

import ToggleFieldsController from "./toggle_fields_controller"
import NewQuestionController from "./new_question_controller"
import ConfirmModalController from "./confirm_modal_controller"
import ClickableCardController from "./clickable_card_controller"
import NestedFieldsController from "./nested_fields_controller"

application.register("toggle-fields", ToggleFieldsController)
application.register("new-question", NewQuestionController)
application.register("confirm-modal", ConfirmModalController)
application.register("clickable-card", ClickableCardController)
application.register("nested-fields", NestedFieldsController)

export { application }
