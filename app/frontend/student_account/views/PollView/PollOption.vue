<template>
  <v-card class="mb-4 w-100">
    <v-radio :value="option.id" class="pa-4">
      <template #label>
        <div class="flex items-center">
          <div
            v-if="option.imageUrl"
            class="h-24 w-24 bg-center bg-cover rounded"
            :style="`background-image: url(${option.imageUrl});`"
          />
          <div class="ml-4">
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
