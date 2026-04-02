<script setup>
import { ref, computed, onMounted } from 'vue'
import { useNotification } from '@kyvg/vue3-notification'
import Question from './Question.vue'
import request from '../../api/request'

const props = defineProps({
  id: String
})

const { notify } = useNotification()

const questions = ref({})
const answers = ref({})
const finished = ref(false)

const requiredQuestionsKeys = computed(() => {
  const keys = []
  for (const key in questions.value) {
    if (Object.hasOwn(questions.value, key) && questions.value[key].required) {
      keys.push(key)
    }
  }
  return keys
})

const answeredQuestionsKeys = computed(() => {
  const keys = []
  for (const key in answers.value) {
    if (Object.hasOwn(answers.value, key)) {
      const answer = answers.value[key]
      if (answer.options.length > 0 || answer.text !== null) {
        keys.push(key)
      }
    }
  }
  return keys
})

const isFormValid = computed(() => {
  return requiredQuestionsKeys.value.every(
    (key) => answeredQuestionsKeys.value.indexOf(key) !== -1
  )
})

function sendFormAnswer() {
  if (isFormValid.value) {
    request.post(`/api/surveys/${props.id}/answers.json`, {
      answers: answers.value
    })
      .then(() => {
        finished.value = true
      })
      .catch(() => {
        notify({
          title: 'Что-то пошло не так :(',
          type: 'warn',
          text: 'Скорее всего, мы уже знаем о случившемся и спешим Вам на помощь.'
        })
      })
  } else {
    notify({
      title: 'Ошибка :(',
      type: 'warn',
      text: 'Вы ответили не на все обязательные вопросы анкеты.'
    })
  }
}

onMounted(() => {
  request.get(`/api/surveys/${props.id}/questions.json`)
    .then((response) => {
      questions.value = response.data
    })
})
</script>

<template>
  <div>
    <div class="survey-form" v-if="!finished">
      <Question
        v-for="q in questions"
        :key="q.id"
        :required="q.required"
        :text="q.text"
        :options="q.options"
        :free="q.freeAnswer"
        :multichoice="q.multichoice"
        v-model="answers[q.id]"
      />
      <button class="btn" @click="sendFormAnswer" :disabled="!isFormValid">Отправить ответ</button>
    </div>
    <div class="note" v-else>
      <p>Спасибо за участие в опросе!</p>
    </div>
  </div>
</template>
