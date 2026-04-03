<template>
  <v-card
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
      <v-btn @click="router.push({ path: `/${meta.resource}/${meta.id}` })" v-else color="primary">
        Перейти к опросу
      </v-btn>
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
