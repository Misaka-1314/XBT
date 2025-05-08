<template>
  <var-button @click="routeToLogin" type="primary" round icon-container
    style="width: 48px;height: 48px;position: absolute;bottom: 66px;right: 16px;">
    <var-icon name="plus" />
  </var-button>

  <h2>当前用户</h2>
  <var-paper elevation="2" class="paper">
    <var-cell :title="currentUser.name"
      :description="currentUser.mobile.substring(0, 3) + '****' + currentUser.mobile.substring(7, 11)">
      <template #icon>
        <var-image width="42px" height="42px" fit="cover" radius="4" style="margin-right: 8px;"
          :src="proxyImage(currentUser.avatar)" />
      </template>
      <template #extra>
        <div class="cell-extra">
          <var-button text type="primary" @click.stop @click="userStore.removeUser(currentUser.uid)">退出登录</var-button>
        </div>
      </template>
    </var-cell>
  </var-paper>
  <template v-if="otherUserList.length > 0">
    <h2>其他用户</h2>
    <var-paper elevation="2" class="paper" v-for="(user, index) in otherUserList" :key="user.mobile">
      <var-cell :title="user.name" :description="user.mobile.substring(0, 3) + '****' + user.mobile.substring(7, 11)">
        <template #icon>
          <var-image width="42px" height="42px" fit="cover" radius="4" style="margin-right: 8px;" :src="proxyImage(user.avatar)" />
        </template>
        <template #extra>
          <div class="cell-extra">
            <var-button text type="primary" @click="userStore.changeCurrentUser(user.uid)">切换</var-button>
            <var-button text type="primary" @click="userStore.removeUser(user.uid)">删除</var-button>
          </div>
        </template>
      </var-cell>
    </var-paper>
  </template>
</template>
<script setup>
import router from '@/router';
import { useUserStore } from '@/stores/UserStore';
import { proxyImage } from '@/utils/constants';
import { storeToRefs } from 'pinia';

const userStore = useUserStore();
const currentUser = storeToRefs(userStore).currentUser;
const otherUserList = storeToRefs(userStore).otherUserList;

function routeToLogin() {
  router.push({ name: 'user-login' })
}
</script>
<style scoped></style>