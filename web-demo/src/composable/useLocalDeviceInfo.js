import axios from "axios";
import { ref } from "vue";

export const useLocalDeviceInfo = () => {
  const deviceInfo = ref();

  const AGENT_BASE_URL = "http://127.0.0.1:18888/api";

  const getLocalDeviceInfo = async () => {
    try {
      const res = await axios.get(`${AGENT_BASE_URL}/device`, {
        timeout: 2000,
      });
      if (res.status !== 200) {
        console.error(`local agent not running.status is${res.status}`);
        return;
      }
      console.log("getLocalDeviceInfo:res", res.data);
      deviceInfo.value = res.data.interfaces;
    } catch (err) {
      console.error("get local device info failed,error is", err);
    }
  };

  const stopAgent = async () => {
    try {
      const res = await axios.get(`${AGENT_BASE_URL}/exit`, { timeout: 2000 });
      if (res.status !== 200) {
        console.error(`local agent not running.status is${res.status}`);
        return;
      }
      console.log("res", res.data);
    } catch (err) {
      console.error("get local device info failed,error is", err);
    }
  };

  return {
    deviceInfo,
    getLocalDeviceInfo,
    stopAgent,
  };
};
