<template>
  <div class="max-w-4xl mx-auto px-4">
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
        <v-btn @click="router.push({ path: `/stages/${stage.id}` })" color="success">Вернуться к списку преподавателей</v-btn>
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

        <v-btn
          color="primary"
          block
          @click="sendFeedback"
          :disabled="!isSubmitEnabled || formState.sent || formState.done"
        >Проголосовать</v-btn>
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
    .leaveFeedback(feedback)
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
