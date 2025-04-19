<template>
  <div class="bg">
    <div class="card">
      <div class="title">
        学不通
      </div>
      <var-input variant="outlined" size="small" placeholder="手机号" v-model="value" style="width: 100%;" blur-color="rbga(0,0,0,0.9)"/>
      <var-input variant="outlined" size="small" type="password" placeholder="密码" v-model="value" style="width: 100%;" blur-color="rbga(0,0,0,0.9)"/>
      <p style="font-weight: lighter;">注册即代表同意本软件收集您的第三方网站隐私信息。其中包括: 姓名，手机号，密码，课程信息等。您的密码将仅用于登录第三方网站，已经过非对称加密处理，本网站保证您的密码不会进行明文存储以及传输。</p>
      <var-button block type="primary">登录 / 注册</var-button>
    </div>
  </div>
</template>
<script setup>

</script>
<style scoped>
.bg {
  background-image: linear-gradient(120deg, #89f7fe 0%, #66a6ff 100%);
  height: 100%;
  width: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
}
.card {
  width: 80%;
  background-color: rgba(255, 255, 255, 0.4);
  border: 2px solid rgba(255, 255, 255, 1);
  border-radius: 16px;
  padding: 32px;
  box-sizing: border-box;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 2px 2px 16px rgba(0, 0, 0, 0.2);
  flex-direction: column;
  gap: 16px;
}

.title {
  font-size: 48px;
  font-weight: bold;
}
</style>