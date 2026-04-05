<template>
  <div class="max-w-4xl mx-auto px-4">
    <h1 class="text-3xl font-normal text-gray-800 my-4">{{ poll.title || "Загрузка..." }}</h1>
    <p class="text-gray-600 my-4">Выберите кандидатуру из списка ниже, чтобы проголосовать.</p>
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
