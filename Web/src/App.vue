<template>
  <RouterView/>
</template>

<script setup>
import { onMounted } from 'vue';

// Chrome / Safari 100vh bug fix
function setBodyHeight() {
  document.body.style.height = `${window.innerHeight}px`
}
onMounted(() => {
  window.addEventListener('resize', setBodyHeight)
  setBodyHeight()
})
</script>

<style scoped>

</style>
