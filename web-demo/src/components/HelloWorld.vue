<script setup>
import { useLocalDeviceInfo } from "../composable/useLocalDeviceInfo";

const { deviceInfo, getLocalDeviceInfo, stopAgent } = useLocalDeviceInfo();
</script>

<template>
  <div>
    <div>
      <button @click="getLocalDeviceInfo">获取本地设备信息</button>
      <button @click="stopAgent">停止本地设备鉴权</button>
    </div>
    <div v-if="deviceInfo">
      {{ deviceInfo }}
    </div>
  </div>
</template>

<style scoped>
.read-the-docs {
  color: #888;
}
</style>
