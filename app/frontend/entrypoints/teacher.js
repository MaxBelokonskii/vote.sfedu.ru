// Teacher cabinet: only the Stimulus controllers needed for teacher views
import { Application } from "@hotwired/stimulus"
import NestedFieldsController from "../admin/controllers/nested_fields_controller"
import ConfirmModalController from "../admin/controllers/confirm_modal_controller"

const application = Application.start()
application.register("nested-fields", NestedFieldsController)
application.register("confirm-modal", ConfirmModalController)

export { application }
