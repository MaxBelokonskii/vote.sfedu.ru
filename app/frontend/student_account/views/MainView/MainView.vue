<template>
  <div class="page">
    <h1 class="page__title">Активные опросы</h1>
    <p class="page__subtitle">Выберите активный опрос из списка ниже и помогите университету стать лучше.</p>
    <v-divider class="my-4"></v-divider>
    <template v-if="items.length > 0">
      <MainViewVoteCard
        v-for="item in items" :key="item.meta.source"
        :title="item.title"
        :description="item.description"
        :participated="item.participated"
        :starts-at="item.startsAtLocalized"
        :ends-at="item.endsAtLocalized"
        :meta="item.meta"
        class="mb-4"
      />
    </template>
    <div v-else>
      <div v-if="attempts > 0" class="d-flex justify-center align-center" style="min-height: 100px;">
        <v-progress-circular v-if="loading" indeterminate color="primary" />
        <span v-if="loading" class="ml-4">Загрузка...</span>
      </div>
      <template v-else>
        <p>
          Нет активных опросов. Приходите позднее и следите за СИЦ вашего структурного подразделения,
          где студенческий совет публикует информацию о предстоящих опросах.
        </p>
        <p>
          Если вы не видите опрос по вашему актуальному структурному подразделению, то попробуйте зайти сюда через пару минут.
          Возможно, мы не можем получить ваши зачётные книжки из 1С:Университет.
        </p>
      </template>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import MainViewVoteCard from "./MainViewVoteCard.vue"
import stagesService from "../../api/stagesService"
import pollsService from "../../api/pollsService"

const items = ref([])
const loading = ref(false)
const attempts = ref(10)

function fetchPolls() {
  pollsService.index().then((response) => {
    items.value = items.value.concat(response.data)
    loading.value = response.data.length === 0
    if (response.data.length === 0) {
      setTimeout(() => { fetchPolls(); attempts.value -= 1 }, 5000)
    }
  })
}

function fetchStages() {
  stagesService.index().then((response) => {
    items.value = items.value.concat(response.data)
    loading.value = response.data.length === 0
  })
}

onMounted(() => {
  loading.value = true
  fetchPolls()
  fetchStages()
})
</script>
