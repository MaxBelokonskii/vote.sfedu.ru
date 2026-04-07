<template>
  <v-radio :value="option.id" class="mb-3 pa-4 rounded-lg border border-gray-200 bg-white">
    <template #label>
      <div class="flex items-center cursor-pointer">
        <div
          v-if="option.imageUrl"
          class="h-24 w-24 bg-center bg-cover rounded shrink-0"
          :style="`background-image: url(${option.imageUrl});`"
        />
        <div class="ml-4">
          <h3 class="text-base font-medium text-gray-900">{{ option.title }}</h3>
          <p class="text-sm text-gray-600 mt-1">{{ option.description }}</p>
        </div>
      </div>
    </template>
  </v-radio>
</template>

<script setup>
defineProps({
  option: Object
})
</script>
