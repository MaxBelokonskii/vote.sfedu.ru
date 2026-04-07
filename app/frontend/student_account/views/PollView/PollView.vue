<template>
  <div class="max-w-4xl mx-auto px-4">
    <button @click="router.push({ path: '/' })" class="inline-flex items-center gap-1.5 text-sm text-gray-500 hover_text-gray-900 transition-colors duration-200 cursor-pointer border-0 bg-transparent mt-4 mb-2 px-0">
      <svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5 3 12m0 0 7.5-7.5M3 12h18" />
      </svg>
      Назад к списку опросов
    </button>
    <h1 class="text-3xl font-normal text-gray-800 my-4">{{ poll.title || "Загрузка..." }}</h1>
    <p class="text-gray-600 my-4">Выберите кандидатуру из списка ниже, чтобы проголосовать.</p>
    <v-divider class="my-4"></v-divider>
    <div class="mt-4">
      <template v-if="poll.participated">
        <div class="d-flex align-center mb-4">
          <CheckMark />
          <span class="ml-2">Ваш голос принят. Спасибо за участие!</span>
        </div>
        <button @click="router.push({ path: `/` })" class="px-4 py-2 bg-emerald-600 text-white text-sm font-medium rounded-lg hover_bg-emerald-700 transition-colors duration-200 cursor-pointer border-0">Вернуться к списку опросов</button>
      </template>
      <template v-else>
        <div v-if="loading" class="d-flex justify-center" style="min-height: 100px;">
          <v-progress-circular indeterminate color="primary" />
        </div>
        <div v-else>
          <div
            v-for="option in poll.options"
            :key="option.id"
            class="mb-3 p-4 rounded-lg border cursor-pointer transition-all duration-200"
            :class="pollOptionId === option.id ? 'border-primary bg-blue-50 shadow-sm' : 'border-gray-200 bg-white hover_bg-gray-50'"
            @click="pollOptionId = option.id"
          >
            <div class="flex items-center gap-4">
              <div
                class="w-5 h-5 rounded-full border-2 shrink-0 flex items-center justify-center transition-colors duration-200"
                :class="pollOptionId === option.id ? 'border-primary' : 'border-gray-300'"
              >
                <div
                  v-if="pollOptionId === option.id"
                  class="w-2.5 h-2.5 rounded-full bg-primary"
                ></div>
              </div>
              <div
                v-if="option.imageUrl"
                class="h-20 w-20 bg-center bg-cover rounded shrink-0"
                :style="`background-image: url(${option.imageUrl});`"
              />
              <div>
                <h3 class="text-base font-medium text-gray-900">{{ option.title }}</h3>
                <p class="text-sm text-gray-600 mt-1" v-if="option.description">{{ option.description }}</p>
              </div>
            </div>
          </div>
        </div>
        <button
          class="w-full mt-4 px-6 py-3 bg-primary text-white rounded-lg font-medium transition-colors duration-200 cursor-pointer border-0 disabled_opacity-50 disabled_cursor-not-allowed"
          :class="pollOptionId != null ? 'hover_bg-blue-800' : ''"
          @click="leaveVoice"
          :disabled="pollOptionId == null"
        >Проголосовать</button>
      </template>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useSnackbar } from '../../composables/useSnackbar'
import pollsService from "../../api/pollsService"
import CheckMark from "../../components/CheckMark.vue"

const route = useRoute()
const router = useRouter()
const { showMessage, showError } = useSnackbar()

const poll = ref({ options: [] })
const loading = ref(false)
const pollOptionId = ref(null)

function leaveVoice() {
  pollsService.leaveVoice(route.params.id, pollOptionId.value)
    .then(() => {
      poll.value.participated = true
    })
    .catch((error) => {
      showError(error)
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
