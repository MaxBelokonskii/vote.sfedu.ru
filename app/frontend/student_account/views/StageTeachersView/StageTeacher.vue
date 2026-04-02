<template>
  <el-card>
    <div class="stage-teacher">
      <div class="stage-teacher__name">{{ name }}</div>
      <div class="stage-teacher__action">
        <CheckMark v-if="participated" />
        <el-button @click="router.push({ path: `/stages/${stageId}/teachers/${id}` })" v-else>Заполнить анкету</el-button>
      </div>
    </div>
  </el-card>
</template>

<script setup>
import { useRouter } from 'vue-router'
import CheckMark from "../../components/CheckMark.vue"

const router = useRouter()

defineProps({
  id: Number,
  stageId: Number,
  name: String,
  participated: Boolean
})
</script>
