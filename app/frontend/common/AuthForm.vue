<script setup>
import { ref, computed } from 'vue'

const props = defineProps({
  path: String,
  name: String
})

const identityName = ref('')

const identityUrl = computed(() => {
  if (identityName.value) {
    const name = identityName.value.split('@')[0].trim()
    return `https://openid.sfedu.ru/server.php/idpage?user=${name}`
  }
  return ''
})
</script>

<template>
  <form :action="path" method="post" class="bg-white text-gray-900 rounded-xl shadow-lg p-8 max-w-md w-full">
    <h3 class="text-xl font-semibold mb-6">Вход в личный кабинет</h3>
    <input
      class="w-full rounded-lg border border-gray-300 px-4 py-3 text-sm mb-4 focus_ring-2 focus_ring-primary focus_border-primary outline-none"
      type="text"
      placeholder="Логин на sfedu.ru"
      v-model="identityName"
    >
    <input type="hidden" :name="name" :value="identityUrl">
    <slot></slot>
    <button class="w-full px-6 py-3 bg-primary text-white rounded-lg hover_bg-blue-800 transition-colors font-medium mt-2">Войти</button>
  </form>
</template>
