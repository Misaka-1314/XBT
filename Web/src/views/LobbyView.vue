<template>
  <div class="screen">
    <div class="body">
      <RouterView />
    </div>
    <var-bottom-navigation v-model:active="active">
      <var-bottom-navigation-item label="标签" icon="home" />
      <var-bottom-navigation-item label="标签" icon="magnify" />
      <var-bottom-navigation-item label="标签" icon="heart" />
      <var-bottom-navigation-item label="标签" icon="account-circle" />
    </var-bottom-navigation>
  </div>

</template>

<script setup>
import { onMounted } from 'vue';

function resetVhAndPx() {
  document.body.style.height = `${window.innerHeight}px`
  
  console.log(window.innerHeight);
}
onMounted(() => {
  window.addEventListener('resize', resetVhAndPx)
  resetVhAndPx()
})
</script>

<style scoped>
.screen {
  display: flex;
  flex-direction: column;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  height: 100%;
  width: 100%;
}

.body {
  flex: 1;
}
</style>