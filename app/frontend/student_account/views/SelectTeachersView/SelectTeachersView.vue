<template>
  <div class="page">
    <h1 class="page__title">Добавление преподавателей в список</h1>
    <p class="page__subtitle">Ниже представлены анкеты преподавателей, которые можно свободно добавить в список.</p>
    <el-divider></el-divider>
    <el-table
      :data="filteredData"
      style="width: 100%">
      <el-table-column
        label="Фамилия, имя, отчество"
        prop="name">
      </el-table-column>
      <el-table-column align="right">
        <template #header>
          <el-input
            v-model="search"
            size="small"
            placeholder="Начните вводить для поиска..."/>
        </template>
        <template #default="scope">
          <el-button
            size="default"
            :type="scope.row.selected ? 'danger' : 'default'"
            @click="handleClick(scope.$index, scope.row)"
            :disabled="scope.row.formState === 'sent'"
          >
            <el-icon v-if="scope.row.selected"><RemoveFilled /></el-icon>
            <el-icon v-else><CirclePlusFilled /></el-icon>
          </el-button>
        </template>
      </el-table-column>
    </el-table>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { RemoveFilled, CirclePlusFilled } from '@element-plus/icons-vue'
import stagesTeachersService from "../../api/stagesTeachersService"
import stagesTeachersRelationsService from "../../api/stagesTeachersRelationsService"

const route = useRoute()

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
      ElMessage({ message: `${row.name} успешно добавлен(а) в список для оценивания` })
    }).catch((error) => {
      row.formState = 'failed'
      ElMessage({ message: error.response.data[0], type: 'warning' })
    })
  } else {
    row.formState = 'sent'
    stagesTeachersRelationsService.removeRelation(stageId.value, row.id).then(() => {
      row.selected = false
      row.formState = 'initial'
      ElMessage({ message: `${row.name} успешно удален(а) из списка для оценивания` })
    }).catch((error) => {
      row.formState = 'failed'
      ElMessage({ message: error.response.data[0], type: 'warning' })
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
