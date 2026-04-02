import { createRouter, createWebHistory } from 'vue-router'
import MainView from "../views/MainView/MainView.vue"
import PollView from "../views/PollView/PollView.vue"
import StageTeachersView from "../views/StageTeachersView/StageTeachersView.vue"
import StageFeedbackView from "../views/StageFeedbackView/StageFeedbackView.vue"
import SelectTeachersView from "../views/SelectTeachersView/SelectTeachersView.vue"

export default createRouter({
  history: createWebHistory('/student'),
  scrollBehavior: () => ({ top: 0 }),
  routes: [
    { path: '/', component: MainView },
    { path: '/polls/:id', component: PollView },
    { path: '/stages/:id', component: StageTeachersView },
    { path: '/stages/:stageId/teachers/:id', component: StageFeedbackView },
    { path: '/stages/:id/teachers', component: SelectTeachersView }
  ]
})
