<template>
  <div style="overflow-y: auto;height: 100%;width: 100%;">
    <div style="height: fit-content;width: 100%;padding: 8px;box-sizing: border-box;">
      <div style="display: flex;flex-direction: row;align-items: center;">
        <h2 style="margin-right: 8px;">配置生效课程</h2>
        <div style="flex: 1;"></div>
        <var-button type="primary">保存</var-button>
      </div>
    </div>
    <var-paper elevation="2" class="paper">
      <template v-for="clazz in allCourses">
        <var-cell ripple>

        </var-cell>
      </template>

    </var-paper>
  </div>
</template>
<script setup>
import { onMounted, watch } from 'vue';
import { useRoute } from 'vue-router';




onMounted(() => {


})

</script>
<style scoped></style>