<template>
  <div class="max-w-4xl mx-auto px-4">
    <button @click="router.push({ path: `/stages/${route.params.stageId}` })" class="inline-flex items-center gap-1.5 text-sm text-gray-500 hover_text-gray-900 transition-colors duration-200 cursor-pointer border-0 bg-transparent mt-4 mb-2 px-0">
      <svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5 3 12m0 0 7.5-7.5M3 12h18" />
      </svg>
      Назад к списку преподавателей
    </button>
    <h1 class="text-3xl font-normal text-gray-800 my-4">{{ teacher.name }}</h1>
    <p class="text-gray-600 my-4">Дисциплины, которые связывают вас с преподавателем:</p>
    <ul class="text-gray-600 my-4 list-disc pl-5">
      <li v-for="discipline in teacher.disciplines" :key="discipline">{{ discipline }}</li>
    </ul>
    <v-divider class="my-4"></v-divider>
    <div>
      <template v-if="formState.done">
        <div class="d-flex align-center mb-4">
          <span class="ml-2">Ваше мнение принято. Спасибо за участие!</span>
        </div>
        <button @click="router.push({ path: `/stages/${stage.id}` })" class="px-4 py-2 bg-emerald-600 text-white text-sm font-medium rounded-lg hover_bg-emerald-700 transition-colors duration-200 cursor-pointer border-0">Вернуться к списку преподавателей</button>
      </template>
      <template v-else>
        <div v-for="question in questions" :key="question.id" class="flex flex-col my-6">
          <div class="text-sm mb-3">{{ question.text }}</div>
          <div>
            <v-rating
              v-model="question.rate"
              :length="10"
              color="primary"
              active-color="primary"
              hover
              density="comfortable"
            />
          </div>
        </div>

        <button
          class="w-full px-6 py-3 bg-primary text-white font-medium rounded-lg transition-colors duration-200 cursor-pointer border-0 disabled_opacity-50 disabled_cursor-not-allowed"
          :class="isSubmitEnabled && !formState.sent ? 'hover_bg-blue-800' : ''"
          @click="sendFeedback"
          :disabled="!isSubmitEnabled || formState.sent || formState.done"
        >Проголосовать</button>
      </template>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useSnackbar } from '../../composables/useSnackbar'
import stagesTeachersService from "../../api/stagesTeachersService"

const route = useRoute()
const router = useRouter()
const { showMessage, showError } = useSnackbar()

const stage = ref({})
const teacher = ref({})
const questions = ref([])
const formState = reactive({
  sent: false,
  done: false
})

const isSubmitEnabled = computed(() => {
  return questions.value.map((q) => q.rate).every((v) => v !== 0)
})

function sendFeedback() {
  const feedback = {
    stageId: stage.value.id,
    teacherId: teacher.value.id,
    answers: questions.value.map((q) => ({ questionId: q.id, rate: q.rate }))
  }

  formState.sent = true

  stagesTeachersService
    .leaveFeedback(feedback.stageId, feedback.teacherId, feedback.answers)
    .then(() => (formState.done = true))
    .catch((error) => {
      formState.sent = false
      showError(error)
    })
}

onMounted(() => {
  stagesTeachersService
    .newFeedback(route.params.stageId, route.params.id)
    .then((response) => {
      stage.value = response.data.stage
      teacher.value = response.data.teacher
      questions.value = response.data.questions.map((q) => ({
        id: q.id,
        text: q.text,
        rate: null
      }))
    })
})
</script>
