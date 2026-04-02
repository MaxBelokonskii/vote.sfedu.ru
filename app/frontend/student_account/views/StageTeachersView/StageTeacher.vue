<template>
  <v-card>
    <v-card-text class="d-flex align-center justify-space-between">
      <div class="stage-teacher__name">{{ name }}</div>
      <div class="stage-teacher__action">
        <CheckMark v-if="participated" />
        <v-btn @click="router.push({ path: `/stages/${stageId}/teachers/${id}` })" v-else color="primary" size="small">
          Заполнить анкету
        </v-btn>
      </div>
    </v-card-text>
  </v-card>
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
