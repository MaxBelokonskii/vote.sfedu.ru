<template>
  <el-card class="voting">
    <template #header>
      <div class="voting__header">
        <span class="voting__title">{{ title }}</span>
      </div>
    </template>
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
    <div class="voting__action">
      <template v-if="participated">
        <CheckMark />
        <span style="margin-left: 8px;">Спасибо за участие!</span>
      </template>
      <el-button @click="router.push({ path: `/${meta.resource}/${meta.id}` })" v-else>Перейти к опросу</el-button>
    </div>
  </el-card>
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
