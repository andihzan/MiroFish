<template>
  <button class="logout-btn" @click="handleLogout" title="Logout">
    <span class="logout-icon">⎋</span>
    <span class="logout-text">{{ $t('auth.logout', 'Logout') }}</span>
  </button>
</template>

<script setup>
import { useRouter } from 'vue-router'

const router = useRouter()

const handleLogout = () => {
  localStorage.removeItem('mirofish_auth_token')
  router.push('/login')
}
</script>

<style scoped>
.logout-btn {
  background: transparent;
  color: inherit;
  border: 1px solid currentColor;
  opacity: 0.8;
  padding: 4px 12px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.8rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  transition: opacity 0.2s, background 0.2s, color 0.2s, border-color 0.2s;
  margin-left: 8px;
}

.logout-btn:hover {
  opacity: 1;
  border-color: #FF4500;
  color: #FF4500;
  background: rgba(255, 69, 0, 0.05);
}

.logout-icon {
  font-size: 1rem;
  line-height: 1;
}
</style>
