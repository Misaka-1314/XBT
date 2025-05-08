import axios from 'axios';
import { useRouter } from 'vue-router';
import { baseURL, version } from './constants';
import { useUserStore } from '@/stores/UserStore';

// 忽略 token 的 URL 列表
const IGNORE_TOKEN_URLS = ['/login'];


// 跳转到登录页
const redirectToLogin = () => {
  let router = useRouter();
  router.push({ name: 'user-login' })
    ; // 假设是单页应用的登录路径
};

// 创建 axios 实例
export const api = axios.create({
  baseURL: baseURL,
  timeout: 60000,
  headers: {
    version,
    'Content-Type': 'application/json'
  }
});


// 请求拦截器
api.interceptors.request.use(async (config) => {
  // 检查是否忽略 token
  const shouldIgnore = IGNORE_TOKEN_URLS.some(url => config.url.includes(url));
  if (shouldIgnore) {
    return config;
  }

  // 获取 token

  const userStore = useUserStore();
  const token = userStore.token;

  if (!token) {
    redirectToLogin();
    // 中断请求
    return Promise.reject(new Error('未登录'));
  }

  // 添加 token
  config.headers['token'] = token;
  return config;
}, error => {
  return Promise.reject(error);
});

export default api;
