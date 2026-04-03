<template>
  <div class="max-w-4xl mx-auto px-4">
    <h1 class="text-3xl font-normal text-gray-800 my-4">Добавление преподавателей в список</h1>
    <p class="text-gray-600 my-4">Ниже представлены анкеты преподавателей, которые можно свободно добавить в список.</p>
    <v-divider class="my-4"></v-divider>
    <v-text-field
      v-model="search"
      prepend-inner-icon="mdi-magnify"
      label="Начните вводить для поиска..."
      density="compact"
      hide-details
      class="mb-4"
    />
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
const { showMessage } = useSnackbar()

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
      showMessage(error.response.data[0], 'warning')
    })
  } else {
    row.formState = 'sent'
    stagesTeachersRelationsService.removeRelation(stageId.value, row.id).then(() => {
      row.selected = false
      row.formState = 'initial'
      showMessage(`${row.name} успешно удален(а) из списка для оценивания`)
    }).catch((error) => {
      row.formState = 'failed'
      showMessage(error.response.data[0], 'warning')
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
