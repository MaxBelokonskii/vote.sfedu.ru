<template>
  <v-card>
    <v-card-title class="flex items-center justify-between">
      <span class="text-base">{{ title }}</span>
    </v-card-title>
    <v-card-text class="text-sm">
      <p class="mb-4" v-if="!!description">
        {{ description }}
      </p>
      <div class="mb-4">
        <dl class="flex mb-2">
          <dt class="w-24 text-gray-500">Начало</dt>
          <dd>{{ startsAt }}</dd>
        </dl>
        <dl class="flex mb-2">
          <dt class="w-24 text-gray-500">Завершение</dt>
          <dd>{{ endsAt }}</dd>
        </dl>
      </div>
    </v-card-text>
    <v-card-actions class="flex items-center">
      <template v-if="participated">
        <CheckMark />
        <span class="ml-2">Спасибо за участие!</span>
      </template>
      <button v-else @click="router.push({ path: `/${meta.resource}/${meta.id}` })" class="px-4 py-2 bg-primary text-white text-sm font-medium rounded-lg hover_bg-blue-800 transition-colors duration-200 cursor-pointer border-0">
        Перейти к опросу
      </button>
    </v-card-actions>
  </v-card>
</template>

<script setup>
import { useRouter } from 'vue-router'
import CheckMark from "../../components/CheckMark.vue"

const router = useRouter()

defineProps({
  title: String,
  description: String,
  startsAt: String,
  endsAt: String,
  participated: Boolean,
  meta: Object
})
</script>
