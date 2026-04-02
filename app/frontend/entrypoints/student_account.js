import { createApp } from 'vue'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import router from '../student_account/router'
import App from '../student_account/App.vue'

const app = createApp(App)
app.use(ElementPlus)
app.use(router)
app.mount('#application')

export { app, router }
