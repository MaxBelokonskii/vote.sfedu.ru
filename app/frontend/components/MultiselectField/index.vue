<template>
  <div>
    <Multiselect
      v-model="selectValue"
      :options="options"
      mode="tags"
      :close-on-select="false"
      :searchable="true"
      placeholder="Выберите или начните вводить"
      label="name"
      value-prop="id"
      track-by="name"
      no-results-text="Ничего не найдено"
    />
    <div style="display: none" ref="optionsRef">
      <slot></slot>
    </div>
    <input v-for="optionId in selectValue" :key="optionId" type="hidden" :name="name" :value="optionId">
    <input v-if="selectValue.length === 0" type="hidden" :name="name" value="">
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import Multiselect from '@vueform/multiselect'

defineProps({
  name: {
    type: String,
    required: true
  },
  id: {
    type: String
  }
})

const selectValue = ref([])
const options = ref([])
const optionsRef = ref(null)

onMounted(() => {
  const optionElements = optionsRef.value.querySelectorAll('option')
  optionElements.forEach(option => {
    const optionObject = {
      id: option.value,
      name: option.innerHTML
    }
    options.value.push(optionObject)
    if (option.selected) {
      selectValue.value.push(option.value)
    }
  })
})
</script>
