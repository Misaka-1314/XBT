import './assets/main.css'

import { createApp } from 'vue'
import App from './App.vue'
import router from './router'

import Varlet from '@varlet/ui'
import '@varlet/ui/es/style'
import '@varlet/touch-emulator'
import { createPinia } from 'pinia'


const app = createApp(App)

const pinia = createPinia()
app.use(pinia)

app.use(router)

app.use(Varlet)

app.mount('#app')
