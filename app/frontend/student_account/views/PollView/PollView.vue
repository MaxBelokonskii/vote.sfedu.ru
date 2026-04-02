<template>
  <div class="page">
    <h1 class="page__title">{{ poll.title || "Загрузка..." }}</h1>
    <p class="page__subtitle">Выберите кандидатуру из списка ниже, чтобы проголосовать.</p>
    <v-divider class="my-4"></v-divider>
    <div class="mt-4">
      <template v-if="poll.participated">
        <div class="d-flex align-center mb-4">
          <CheckMark />
          <span class="ml-2">Ваш голос принят. Спасибо за участие!</span>
        </div>
        <v-btn @click="router.push({ path: `/` })" color="success">Вернуться к списку опросов</v-btn>
      </template>
      <template v-else>
        <div v-if="loading" class="d-flex justify-center" style="min-height: 100px;">
          <v-progress-circular indeterminate color="primary" />
        </div>
        <v-radio-group v-else v-model="pollOptionId" class="w-100">
          <PollOption v-for="option in poll.options" :key="option.id" :option="option" />
        </v-radio-group>
        <v-btn
          color="primary"
          block
          @click="leaveVoice"
          :disabled="pollOptionId == null"
        >Проголосовать</v-btn>
      </template>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useSnackbar } from '../../composables/useSnackbar'
import pollsService from "../../api/pollsService"
import PollOption from "./PollOption.vue"
import CheckMark from "../../components/CheckMark.vue"

const route = useRoute()
const router = useRouter()
const { showMessage } = useSnackbar()

const poll = ref({ options: [] })
const loading = ref(false)
const pollOptionId = ref(null)

function leaveVoice() {
  pollsService.leaveVoice(route.params.id, pollOptionId.value)
    .then(() => {
      poll.value.participated = true
    })
    .catch((error) => {
      showMessage(error.response.data[0], 'warning')
    })
}

onMounted(() => {
  loading.value = true
  pollsService.show(route.params.id).then((response) => {
    loading.value = false
    poll.value = response.data
  })
})
</script>
