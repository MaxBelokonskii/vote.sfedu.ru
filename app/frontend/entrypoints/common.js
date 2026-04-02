import { createApp } from 'vue'
import Notifications from '@kyvg/vue3-notification'
import AuthForm from '../common/AuthForm.vue'
import SurveyForm from '../components/SurveyForm/index.vue'
import MultiselectField from '../components/MultiselectField/index.vue'

const app = createApp({
  components: {
    AuthForm,
    SurveyForm,
    MultiselectField,
  }
})
app.use(Notifications)
app.mount('#common-app')
