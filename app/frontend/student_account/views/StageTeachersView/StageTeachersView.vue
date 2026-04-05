<template>
  <div class="max-w-4xl mx-auto px-4 py-6">
    <div class="text-center mb-6">
      <h1 class="text-2xl font-bold text-gray-900 mb-2">Оценка качества преподавания</h1>
      <p class="text-gray-500 text-sm">Анкеты преподавателей, которые вели дисциплины за указанный период.</p>
    </div>

    <div class="flex flex-wrap justify-center gap-2 mb-6">
      <button
        v-if="stageAttendee.fetchingStatus !== 'in_progress'"
        @click="refreshTeachers"
        class="inline-flex items-center gap-2 px-4 py-2 rounded-lg border border-gray-300 bg-white text-sm font-medium text-gray-700 hover_bg-gray-50 transition-colors duration-200 cursor-pointer"
      >
        <svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0 3.181 3.183a8.25 8.25 0 0 0 13.803-3.7M4.031 9.865a8.25 8.25 0 0 1 13.803-3.7l3.181 3.182" />
        </svg>
        Обновить список
      </button>
      <button
        @click="router.push({ path: `/stages/${stageId}/teachers` })"
        class="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-primary text-white text-sm font-medium hover_bg-blue-800 transition-colors duration-200 cursor-pointer border-0"
      >
        <svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" d="M18 7.5v3m0 0v3m0-3h3m-3 0h-3m-2.25-4.125a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75 0ZM3 19.235v-.11a6.375 6.375 0 0 1 12.75 0v.109A12.318 12.318 0 0 1 9.374 21c-2.331 0-4.512-.645-6.374-1.766Z" />
        </svg>
        Выбрать из списка
      </button>
    </div>

    <!-- Список преподавателей -->
    <template v-if="stageAttendee.fetchingStatus === 'done'">
      <div class="space-y-3">
        <StageTeacher
          v-for="item in items"
          :key="item.id"
          :id="item.id"
          :name="item.name"
          :stage-id="stageId"
          :participated="item.participated"
        />
      </div>
    </template>

    <!-- Загрузка -->
    <template v-else-if="stageAttendee.fetchingStatus === 'in_progress'">
      <div class="flex flex-col items-center justify-center py-16 text-center">
        <div class="w-16 h-16 rounded-full bg-blue-100 flex items-center justify-center mb-5">
          <svg class="w-8 h-8 text-primary animate-spin" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path>
          </svg>
        </div>
        <h3 class="text-lg font-semibold text-gray-900 mb-2">Загружаем список преподавателей</h3>
        <p class="text-gray-500 text-sm max-w-md">Это может занять некоторое время — от одной до десяти минут. Пожалуйста, не закрывайте страницу.</p>
      </div>
    </template>

    <!-- Ошибка -->
    <template v-else-if="stageAttendee.fetchingStatus === 'failed'">
      <div class="flex flex-col items-center justify-center py-16 text-center">
        <div class="w-16 h-16 rounded-full bg-red-100 flex items-center justify-center mb-5">
          <svg class="w-8 h-8 text-red-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z" />
          </svg>
        </div>
        <h3 class="text-lg font-semibold text-gray-900 mb-2">Не удалось загрузить список</h3>
        <p class="text-gray-500 text-sm max-w-md mb-6">Возможно, проблема вызвана техническими работами на стороне 1С:Университет. Попробуйте вернуться позже и обновить список преподавателей.</p>
        <button
          @click="refreshTeachers"
          class="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-primary text-white text-sm font-medium hover_bg-blue-800 transition-colors duration-200 cursor-pointer border-0"
        >
          <svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0 3.181 3.183a8.25 8.25 0 0 0 13.803-3.7M4.031 9.865a8.25 8.25 0 0 1 13.803-3.7l3.181 3.182" />
          </svg>
          Попробовать снова
        </button>
      </div>
    </template>

    <!-- Начальное состояние -->
    <template v-else-if="stageAttendee.fetchingStatus === 'fresh'">
      <div class="flex flex-col items-center justify-center py-16 text-center">
        <div class="w-16 h-16 rounded-full bg-amber-100 flex items-center justify-center mb-5">
          <svg class="w-8 h-8 text-amber-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337 0 0 0 4.121-.952 4.125 4.125 0 0 0-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0 1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75 0Zm8.25 2.25a2.625 2.625 0 1 1-5.25 0 2.625 2.625 0 0 1 5.25 0Z" />
          </svg>
        </div>
        <h3 class="text-lg font-semibold text-gray-900 mb-2">Добро пожаловать!</h3>
        <p class="text-gray-500 text-sm max-w-md mb-6">Нажмите кнопку ниже, чтобы загрузить список ваших преподавателей и приступить к оцениванию.</p>
        <button
          @click="refreshTeachers"
          class="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-primary text-white text-sm font-medium hover_bg-blue-800 transition-colors duration-200 cursor-pointer border-0"
        >
          <svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0 3.181 3.183a8.25 8.25 0 0 0 13.803-3.7M4.031 9.865a8.25 8.25 0 0 1 13.803-3.7l3.181 3.182" />
          </svg>
          Загрузить преподавателей
        </button>
      </div>
    </template>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useSnackbar } from '../../composables/useSnackbar'
import StageTeacher from "./StageTeacher.vue"
import stagesTeachersService from "../../api/stagesTeachersService"

const route = useRoute()
const router = useRouter()
const { showMessage, showError } = useSnackbar()

const items = ref([])
const stageAttendee = ref({
  fetchingStatus: 'fresh',
  choosingStatus: 'not_selected'
})
const attempts = ref(10)

const stageId = computed(() => route.params.id)
const needToRepeatQuery = computed(() => stageAttendee.value.fetchingStatus === 'in_progress')

function fetchTeachers() {
  stagesTeachersService.index(stageId.value).then((response) => {
    items.value = items.value.concat(response.data.available)
    items.value = items.value.concat(response.data.evaluated)

    stageAttendee.value.fetchingStatus = response.data.stageAttendee.fetchingStatus
    stageAttendee.value.choosingStatus = response.data.stageAttendee.choosingStatus

    if (needToRepeatQuery.value) {
      repeatFetching()
    }
  })
}

function refreshTeachers() {
  stagesTeachersService.refreshTeachers(stageId.value).then(() => {
    stageAttendee.value.fetchingStatus = 'in_progress'
  }).catch((error) => {
    showError(error)
  })
}

function repeatFetching() {
  if (attempts.value === 0) {
    stageAttendee.value.fetchingStatus = 'failed'
    return
  }

  setTimeout(() => { fetchTeachers(); attempts.value -= 1 }, 5000)
}

onMounted(() => {
  fetchTeachers()
})
</script>
