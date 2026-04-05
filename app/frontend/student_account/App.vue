<template>
  <v-app>
    <v-main>
      <router-view />
      <!-- Toast notification -->
      <Transition name="toast">
        <div
          v-if="snackbar.show"
          class="fixed top-20 left-1/2 -translate-x-1/2 z-50 px-5 py-3 rounded-lg shadow-lg text-sm font-medium"
          :class="snackbar.color === 'warning' ? 'bg-amber-500 text-white' : 'bg-emerald-500 text-white'"
        >
          {{ snackbar.message }}
        </div>
      </Transition>
    </v-main>
  </v-app>
</template>

<script setup>
import { watch } from 'vue'
import { useSnackbar } from './composables/useSnackbar'

const { snackbar } = useSnackbar()

watch(() => snackbar.value.show, (val) => {
  if (val) {
    setTimeout(() => { snackbar.value.show = false }, snackbar.value.timeout)
  }
})
</script>

<style>
.toast-enter-active, .toast-leave-active {
  transition: all 0.3s ease;
}
.toast-enter-from, .toast-leave-to {
  opacity: 0;
  transform: translate(-50%, -12px);
}
</style>
