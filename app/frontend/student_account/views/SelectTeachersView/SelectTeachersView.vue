<template>
  <div class="max-w-4xl mx-auto px-4">
    <h1 class="text-3xl font-normal text-gray-800 my-4">Добавление преподавателей в список</h1>
    <p class="text-gray-600 my-4">Ниже представлены анкеты преподавателей, которые можно свободно добавить в список.</p>
    <v-divider class="my-4"></v-divider>
    <div class="relative mb-4">
      <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z" />
      </svg>
      <input
        v-model="search"
        type="text"
        placeholder="Начните вводить для поиска..."
        class="w-full pl-10 pr-4 py-2.5 rounded-lg border border-gray-300 text-sm focus_ring-2 focus_ring-primary focus_border-primary outline-none transition-shadow duration-200"
      />
    </div>
    <v-table>
      <thead>
        <tr>
          <th>Фамилия, имя, отчество</th>
          <th class="text-right">Действие</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="(row, index) in filteredData" :key="row.id">
          <td>{{ row.name }}</td>
          <td class="text-right">
            <v-btn
              size="small"
              :color="row.selected ? 'error' : 'default'"
              :variant="row.selected ? 'flat' : 'outlined'"
              @click="handleClick(index, row)"
              :disabled="row.formState === 'sent'"
              icon
            >
              <v-icon>{{ row.selected ? 'mdi-minus-circle' : 'mdi-plus-circle' }}</v-icon>
            </v-btn>
          </td>
        </tr>
      </tbody>
    </v-table>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useSnackbar } from '../../composables/useSnackbar'
import stagesTeachersService from "../../api/stagesTeachersService"
import stagesTeachersRelationsService from "../../api/stagesTeachersRelationsService"

const route = useRoute()
const { showMessage, showError } = useSnackbar()

const tableData = ref([])
const search = ref('')

const stageId = computed(() => route.params.id)

const filteredData = computed(() => {
  if (!search.value) return tableData.value
  return tableData.value.filter(data =>
    data.name.toLowerCase().includes(search.value.toLowerCase())
  )
})

function handleClick(index, row) {
  if (row.formState === 'sent') return

  if (!row.selected) {
    row.formState = 'sent'
    stagesTeachersRelationsService.addRelation(stageId.value, row.id).then(() => {
      row.selected = true
      row.formState = 'initial'
      showMessage(`${row.name} успешно добавлен(а) в список для оценивания`)
    }).catch((error) => {
      row.formState = 'failed'
      showError(error)
    })
  } else {
    row.formState = 'sent'
    stagesTeachersRelationsService.removeRelation(stageId.value, row.id).then(() => {
      row.selected = false
      row.formState = 'initial'
      showMessage(`${row.name} успешно удален(а) из списка для оценивания`)
    }).catch((error) => {
      row.formState = 'failed'
      showError(error)
    })
  }
}

onMounted(() => {
  stagesTeachersService.rosterIndex(stageId.value).then((response) => {
    const teachers = [
      ...response.data.availableTeachers,
      ...response.data.selectedTeachers
    ]
    teachers.forEach(t => t.formState = 'initial')
    tableData.value = teachers
  })
})
</script>
