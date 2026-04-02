<template>
  <v-app>
    <v-main>
      <router-view />
      <v-snackbar
        v-model="snackbar.show"
        :color="snackbar.color"
        :timeout="snackbar.timeout"
        location="top"
      >
        {{ snackbar.message }}
      </v-snackbar>
    </v-main>
  </v-app>
</template>

<script setup>
import { useSnackbar } from './composables/useSnackbar'

const { snackbar } = useSnackbar()
</script>
