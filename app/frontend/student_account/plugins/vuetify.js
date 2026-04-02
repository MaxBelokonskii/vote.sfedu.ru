import 'vuetify/styles'
import '@mdi/font/css/materialdesignicons.css'
import { createVuetify } from 'vuetify'

export default createVuetify({
  theme: {
    defaultTheme: 'sfedu',
    themes: {
      sfedu: {
        dark: false,
        colors: {
          primary: '#1565C0',
          secondary: '#36475f',
          accent: '#fee882',
          surface: '#ffffff',
          background: '#f5f5f5',
          error: '#D32F2F',
          success: '#388E3C',
          warning: '#F57C00',
          info: '#1976D2',
        },
      },
    },
  },
  defaults: {
    VBtn: { variant: 'flat', rounded: 'lg' },
    VCard: { rounded: 'lg', elevation: 1 },
    VTextField: { variant: 'outlined', density: 'comfortable' },
  },
})
