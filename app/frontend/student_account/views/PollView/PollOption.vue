<template>
  <v-card class="mb-4 w-100">
    <v-radio :value="option.id" class="pa-4">
      <template #label>
        <div class="poll-option">
          <div
            v-if="option.imageUrl"
            class="poll-option__image"
            :style="`background-image: url(${option.imageUrl});`"
          />
          <div class="poll-option__info">
            <h3>{{ option.title }}</h3>
            <p>{{ option.description }}</p>
          </div>
        </div>
      </template>
    </v-radio>
  </v-card>
</template>

<script setup>
defineProps({
  option: Object
})
</script>
