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
  <div class="survey-form-question">
    <h3 class="survey-form-question__title">
      <span v-if="required">* </span>{{ text }}
    </h3>
    <div class="survey-form-question__options">
      <div class="survey-form-question__option" v-for="item in options" :key="item.id">
        <div class="survey-form-question__option-box">
          <input type="checkbox" :id="optionID(item.id)" :value="item.id" v-model="chosenOptions" v-if="multichoice">
          <input type="radio" :id="optionID(item.id)" :value="item.id" v-model="chosenOptions" v-else>
        </div>
        <label class="survey-form-question__option-label" :for="optionID(item.id)">
          {{ item.text }}
        </label>
      </div>

      <div class="survey-form-question__option" v-if="free && options.length > 0">
        <div class="survey-form-question__option-box">
          <input type="checkbox" value="free" v-model="chosenOptions" v-if="multichoice">
          <input type="radio" value="free" v-model="chosenOptions" v-else>
        </div>
        <div class="survey-form-question__option-text">
          <input type="text" v-model="freeAnswer" placeholder="Укажите Ваш ответ" :disabled="!freeAnswerChoosed">
        </div>
      </div>

      <div class="survey-form-question__option" v-else-if="free && options.length === 0">
        <div class="survey-form-question__option-text">
          <textarea v-model="freeAnswer" placeholder="Укажите Ваш ответ"></textarea>
        </div>
      </div>
    </div>
  </div>
</template>
