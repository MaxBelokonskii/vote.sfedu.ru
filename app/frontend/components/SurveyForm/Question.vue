<script setup>
import { ref, computed, watch } from 'vue'

const props = defineProps({
  required: Boolean,
  text: String,
  multichoice: Boolean,
  free: Boolean,
  options: Array,
  modelValue: Object
})

const emit = defineEmits(['update:modelValue'])

const chosenOptions = ref([])
const freeAnswer = ref(null)

const handledAnswers = computed(() => {
  if (!props.multichoice) {
    return [chosenOptions.value]
  }
  return [...chosenOptions.value]
})

const freeAnswerChoosed = computed(() => {
  if (props.options.length === 0 && props.free) return true
  return handledAnswers.value.indexOf("free") > -1
})

function emitValue() {
  emit('update:modelValue', {
    options: handledAnswers.value.filter(Number),
    text: freeAnswerChoosed.value ? freeAnswer.value : null
  })
}

function optionID(id) {
  return `option${id}`
}

watch(chosenOptions, emitValue, { deep: true })
watch(freeAnswer, emitValue)
</script>

<template>
  <div class="bg-white rounded-lg border border-gray-200 p-6">
    <h3 class="text-base font-semibold text-gray-900 mb-4">
      <span v-if="required" class="text-red-500">* </span>{{ text }}
    </h3>
    <div class="space-y-3">
      <div class="flex items-start gap-3" v-for="item in options" :key="item.id">
        <input type="checkbox" :id="optionID(item.id)" :value="item.id" v-model="chosenOptions" v-if="multichoice"
          class="mt-1 rounded border-gray-300 text-primary focus_ring-primary">
        <input type="radio" :id="optionID(item.id)" :value="item.id" v-model="chosenOptions" v-else
          class="mt-1 border-gray-300 text-primary focus_ring-primary">
        <label class="text-sm text-gray-700 cursor-pointer" :for="optionID(item.id)">
          {{ item.text }}
        </label>
      </div>

      <div class="flex items-start gap-3" v-if="free && options.length > 0">
        <input type="checkbox" value="free" v-model="chosenOptions" v-if="multichoice"
          class="mt-1 rounded border-gray-300 text-primary focus_ring-primary">
        <input type="radio" value="free" v-model="chosenOptions" v-else
          class="mt-1 border-gray-300 text-primary focus_ring-primary">
        <input type="text" v-model="freeAnswer" placeholder="Укажите Ваш ответ" :disabled="!freeAnswerChoosed"
          class="flex-1 rounded-lg border border-gray-300 px-3 py-2 text-sm focus_ring-2 focus_ring-primary focus_border-primary disabled_opacity-50 disabled_bg-gray-50">
      </div>

      <div v-else-if="free && options.length === 0">
        <textarea v-model="freeAnswer" placeholder="Укажите Ваш ответ"
          class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus_ring-2 focus_ring-primary focus_border-primary min-h-[100px]"></textarea>
      </div>
    </div>
  </div>
</template>
