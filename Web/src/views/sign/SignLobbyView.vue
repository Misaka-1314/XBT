<template>
  <div style="display: flex;flex-direction: row;">
    <h2 style="margin-right: 8px;">课程列表</h2>
    <var-loading size="small" v-show="isLoading" />
  </div>
  <var-paper v-for="clazz in selectedClasses" elevation="2" class="paper">
    <var-cell :title="clazz.name" :description="clazz.teacher" @click="() => { clazz.expanded = !clazz.expanded }"
      ripple>
      <template #icon>
        <var-image width="42px" height="42px" fit="cover" radius="4" :src="clazz.icon" style="margin-right: 8px;" />
      </template>
      <template #extra>
        <div class="cell-extra">{{ getChineseStringByDatetime(new Date(clazz.actives[0].startTime)) }}</div>
      </template>
    </var-cell>
    <var-collapse-transition :expand="clazz.expanded">
      <var-divider margin="0"></var-divider>
      <template v-for="active in clazz.actives">
        <var-cell icon="map-marker" :title="SignType.fromId(active.signType).name" :description="active.subtitle" ripple :style="{color: active.isActive ? 'var(--color-primary)' : undefined}">
          <template #extra>
            <div class="cell-extra">
              {{ getChineseStringByDatetime(new Date(active.startTime)) }}
            </div>
          </template>
        </var-cell>
        <var-divider margin="0" style="border-color: rgba(0,0,0,0.1);" hairline />
      </template>
      <div v-if="clazz.triggeredLimit" class="no-more">仅显示最近{{ activesLimit }}条数据</div>
    </var-collapse-transition>
  </var-paper>



</template>

<script setup>
import api from '@/utils/api';
import { activesLimit, SignType } from '@/utils/constants';
import { getChineseStringByDatetime } from '@/utils/datetime';
import { Snackbar } from '@varlet/ui';
import { computed, onMounted, reactive, ref } from 'vue';
const isLoading = ref(false);
const selectedClasses = reactive(
  []
);

async function refreshPage() {
  isLoading.value = true;
  const resp = (await api.post('getSelectedCourseAndActivityList', {})).data;

  if (!resp.suc) {
    Snackbar({
      type: 'warning',
      content: resp.msg,
      duration: 2000,
    })
    isLoading.value = false;
  }
  const _selectedClasses = JSON.parse(JSON.stringify(resp.data));
  _selectedClasses.map((v, i) => {
    v.expanded = i < selectedClasses.length ? selectedClasses[i].expanded : false;
    v.triggeredLimit = false;
    if (v.actives.length > activesLimit) {
      v.triggeredLimit = true;
      v.actives = v.actives.slice(0, activesLimit);
    }
    let badgeCount = 0;
    for (let j = 0; j < v.actives.length; j++) {
      v.actives[j].classId = v.classId;
      v.actives[j].courseId = v.courseId;
      let record = v.actives[j].signRecord;
      let isActive = v.actives[j].endTime > Date.now();
      let prefix = isActive ? (v.actives[j].endTime == 64060559999000 ? "进行中(手动结束)" : '进行中') : "已结束";
      if (record.source == 'none') {
        v.actives[j].subtitle = prefix;
      } else if (record.source == 'self') {
        v.actives[j].subtitle = prefix + '(本人签到)';
      } else if (record.source == 'xxt') {
        v.actives[j].subtitle = prefix + '(学习通)';
      } else if (record.source == 'agent') {
        v.actives[j].subtitle = prefix + '(' + record.sourceName + '代签)';
      }
      v.actives[j].isActive = isActive;
      let isBadge = (record.source == 'none' && isActive);
      v.actives[j].badge = isBadge;
      if (isBadge) badgeCount++;
    }
  })
  selectedClasses.splice(0, selectedClasses.length, ..._selectedClasses);
  isLoading.value = false;
}

onMounted(() => {
  refreshPage();
})




</script>
<style scoped>
.paper {
  display: flex;
  flex-direction: column;
  user-select: none;
  -webkit-user-select: none;
}

.no-more {
  text-align: center;
  color: rgba(0, 0, 0, 0.5);
  font-size: 12px;
  padding: 3px;
}
</style>