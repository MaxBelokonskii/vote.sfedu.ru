import { ref } from 'vue'

const snackbar = ref({
  show: false,
  message: '',
  color: 'success',
  timeout: 3000,
})

export function useSnackbar() {
  function showMessage(message, type = 'success') {
    snackbar.value = {
      show: true,
      message,
      color: type === 'warning' ? 'warning' : 'success',
      timeout: 3000,
    }
  }

  return { snackbar, showMessage }
}
