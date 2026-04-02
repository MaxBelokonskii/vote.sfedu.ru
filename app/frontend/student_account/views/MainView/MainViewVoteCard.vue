<template>
  <v-card class="voting">
    <v-card-title class="voting__header">
      <span class="voting__title">{{ title }}</span>
    </v-card-title>
    <v-card-text>
      <div class="voting-description">
        <p class="voting-description__item voting-description__item_lg-offset" v-if="!!description">
          {{ description }}
        </p>
        <div class="voting-description__item voting-description__item_lg-offset">
          <dl class="voting-property voting-description__item">
            <dt class="voting-property__name">Начало</dt>
            <dd class="voting-property__value">{{ startsAt }}</dd>
          </dl>
          <dl class="voting-property voting-description__item">
            <dt class="voting-property__name">Завершение</dt>
            <dd class="voting-property__value">{{ endsAt }}</dd>
          </dl>
        </div>
      </div>
    </v-card-text>
    <v-card-actions class="voting__action">
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
