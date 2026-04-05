<template>
  <div class="flex items-center justify-between p-4 bg-white rounded-xl border border-gray-200 hover_shadow-sm transition-shadow duration-200">
    <span class="font-medium text-gray-900">{{ name }}</span>
    <div>
      <CheckMark v-if="participated" />
      <button
        v-else
        @click="router.push({ path: `/stages/${stageId}/teachers/${id}` })"
        class="px-4 py-2 bg-primary text-white text-sm font-medium rounded-lg hover_bg-blue-800 transition-colors duration-200 cursor-pointer border-0"
      >Заполнить анкету</button>
    </div>
  </div>
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
