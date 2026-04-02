import { createApp } from 'vue'
import vuetify from '../student_account/plugins/vuetify'
import router from '../student_account/router'
import App from '../student_account/App.vue'

const app = createApp(App)
app.use(vuetify)
app.use(router)
app.mount('#application')

export { app, router }
