<template>
  <div class="page">
    <h1 class="page__title">{{ poll.title || "Загрузка..." }}</h1>
    <p class="page__subtitle">Выберите кандидатуру из списка ниже, чтобы проголосовать.</p>
    <el-divider></el-divider>
    <div style="margin-top: 16px">
      <template v-if="poll.participated">
        <div style="display: flex; align-items: center; margin-bottom: 16px;">
          <CheckMark />
          <span style="margin-left: 8px;">Ваш голос принят. Спасибо за участие!</span>
        </div>
        <el-button @click="router.push({ path: `/` })" type="success">Вернуться к списку опросов</el-button>
      </template>
      <template v-else>
        <el-radio-group v-loading="loading" v-model="pollOptionId" size="small" style="width: 100%; min-height: 100px;">
          <PollOption v-for="option in poll.options" :key="option.id" :option="option" />
        </el-radio-group>
        <el-button
          type="primary"
          style="width: 100%;"
          @click="leaveVoice"
          :disabled="pollOptionId == null"
        >Проголосовать</el-button>
      </template>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import pollsService from "../../api/pollsService"
import PollOption from "./PollOption.vue"
import CheckMark from "../../components/CheckMark.vue"

const route = useRoute()
const router = useRouter()

const poll = ref({ options: [] })
const loading = ref(false)
const pollOptionId = ref(null)

function leaveVoice() {
  pollsService.leaveVoice(route.params.id, pollOptionId.value)
    .then(() => {
      poll.value.participated = true
    })
    .catch((error) => {
      ElMessage({
        message: error.response.data[0],
        type: 'warning'
      })
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
