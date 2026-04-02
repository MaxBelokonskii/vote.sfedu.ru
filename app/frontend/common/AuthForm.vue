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
  <form :action="path" method="post" class="authorization-form">
    <h3 class="authorization-form__title">Вход в личный кабинет</h3>
    <input class="authorization-form__input" type="text" placeholder="Логин на sfedu.ru" v-model="identityName">
    <input type="hidden" :name="name" :value="identityUrl">
    <slot></slot>
    <button class="btn authorization-form__submit-button">Войти</button>
  </form>
</template>
