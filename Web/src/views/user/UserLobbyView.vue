<template>
  <var-button @click="routeToLogin" type="primary" round icon-container style="width: 48px;height: 48px;position: absolute;bottom: 66px;right: 16px;">
    <var-icon name="plus" />
  </var-button>

  <h2>当前用户</h2>
  <var-paper elevation="2" class="paper">
  </var-paper>
  <h2>其他用户</h2>

</template>
<script setup>
import router from '@/router';

function routeToLogin(){
  router.push({ name: 'user-login' })
}
</script>
<style scoped></style>