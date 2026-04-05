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

  function showError(error) {
    const data = error?.response?.data
    let message = 'Произошла ошибка. Попробуйте позже.'

    if (Array.isArray(data) && data.length > 0 && typeof data[0] === 'string') {
      message = data[0]
    } else if (typeof data === 'string' && !data.startsWith('<')) {
      message = data
    } else if (data?.error) {
      message = data.error
    }

    showMessage(message, 'warning')
  }

  return { snackbar, showMessage, showError }
}
