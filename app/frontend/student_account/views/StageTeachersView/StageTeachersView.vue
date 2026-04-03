<template>
  <div class="max-w-4xl mx-auto px-4">
    <h1 class="text-3xl font-normal text-gray-800 my-4">Оценка качества преподавания</h1>
    <p class="text-gray-600 my-4">Анкеты преподавателей, которые вели дисциплины за указанный период.</p>
    <v-divider class="my-4"></v-divider>
    <div>
      <div class="flex justify-end gap-2 mb-4">
        <v-btn size="small" variant="outlined" v-if="stageAttendee.fetchingStatus !== 'in_progress'" @click="refreshTeachers">
          Обновить список преподавателей
        </v-btn>
        <v-btn size="small" variant="outlined" @click="router.push({ path: `/stages/${stageId}/teachers` })">
          Выбрать преподавателей из списка
        </v-btn>
      </div>

      <template v-if="stageAttendee.fetchingStatus === 'done'">
        <StageTeacher
          class="mb-4 shadow-sm"
          v-for="item in items"
          :key="item.id"
          :id="item.id"
          :name="item.name"
          :stage-id="stageId"
          :participated="item.participated"
        />
      </template>
      <template v-else-if="stageAttendee.fetchingStatus === 'in_progress'">
        <div class="text-gray-600 my-4">
          <div class="d-flex justify-center align-center" style="min-height: 100px;">
            <v-progress-circular indeterminate color="primary" />
            <span class="ml-4">Загрузка...</span>
          </div>
          <p>Загружаем список преподавателей. Это может занять некоторое время (от одной до десяти минут).</p>
        </div>
      </template>
      <template v-else-if="stageAttendee.fetchingStatus === 'failed'">
        <div class="text-gray-600 my-4">
          Не удалось получить актуальный список преподавателей.
          Возможно, проблема вызвана техническими работами на стороне 1С:Университет.
          Попробуйте вернуться сюда через несколько часов и попробовать снова обновить список преподавателей.
        </div>
      </template>
      <template v-else-if="stageAttendee.fetchingStatus === 'fresh'">
        <div class="text-gray-600 my-4">
          Добро пожаловать! Нажмите "Обновить список преподавателей", чтобы приступить к оцениванию.
        </div>
      </template>
    </div>
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
const { showMessage } = useSnackbar()

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
    showMessage(error.response.data[0], 'warning')
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
