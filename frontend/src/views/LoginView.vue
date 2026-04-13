<template>
  <div class="login-container">
    <div class="login-card">
      <div class="login-header">
        <h1 class="nav-brand">MIROFISH</h1>
        <div class="login-lock-icon">🔒</div>
        <h2>{{ $t('auth.loginTitle', 'System Access') }}</h2>
        <p class="login-subtitle">{{ $t('auth.loginDesc', 'Enter master password to continue.') }}</p>
      </div>

      <form @submit.prevent="handleLogin" class="login-form">
        <div class="input-group">
          <input
            type="password"
            v-model="password"
            :placeholder="$t('auth.passwordPlaceholder', 'Password')"
            class="password-input"
            required
            autofocus
            :disabled="loading"
          />
        </div>

        <div v-if="error" class="error-message">
          {{ error }}
        </div>

        <button type="submit" class="login-btn" :disabled="!password || loading">
          <span v-if="!loading">{{ $t('auth.loginBtn', 'Enter System') }}</span>
          <span v-else>{{ $t('auth.loggingIn', 'Authenticating...') }}</span>
          <span class="btn-arrow">→</span>
        </button>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import axios from 'axios'

const password = ref('')
const error = ref('')
const loading = ref(false)
const router = useRouter()
const route = useRoute()

const handleLogin = async () => {
  if (!password.value) return
  
  error.value = ''
  loading.value = true
  
  try {
    const baseURL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5001'
    const response = await axios.post(`${baseURL}/api/auth/login`, {
      password: password.value
    })
    
    if (response.data.success && response.data.token) {
      // Save token
      localStorage.setItem('mirofish_auth_token', response.data.token)
      
      // Redirect back to intended route or home
      const redirect = route.query.redirect || '/'
      router.push(redirect)
    }
  } catch (err) {
    if (err.response && err.response.data && err.response.data.error) {
      error.value = err.response.data.error
    } else {
      error.value = 'Network error or system unavailable.'
    }
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #f5f5f5;
  font-family: 'Space Grotesk', 'Noto Sans SC', system-ui, sans-serif;
}

.nav-brand {
  font-family: 'JetBrains Mono', monospace;
  font-weight: 800;
  letter-spacing: 1px;
  font-size: 1.5rem;
  margin-bottom: 20px;
}

.login-card {
  background: white;
  padding: 50px 40px;
  border-radius: 8px;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.05);
  width: 100%;
  max-width: 420px;
  border: 1px solid #eee;
}

.login-header {
  text-align: center;
  margin-bottom: 30px;
}

.login-lock-icon {
  font-size: 2rem;
  margin-bottom: 10px;
}

.login-header h2 {
  font-size: 1.5rem;
  font-weight: 600;
  margin-bottom: 10px;
}

.login-subtitle {
  color: #666;
  font-size: 0.9rem;
}

.input-group {
  margin-bottom: 20px;
}

.password-input {
  width: 100%;
  padding: 15px;
  font-size: 1rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  outline: none;
  font-family: 'JetBrains Mono', monospace;
  transition: border-color 0.2s;
}

.password-input:focus {
  border-color: #000;
}

.error-message {
  color: #ff4500;
  font-size: 0.85rem;
  margin-bottom: 20px;
  text-align: center;
  background: rgba(255, 69, 0, 0.05);
  padding: 10px;
  border-radius: 4px;
}

.login-btn {
  width: 100%;
  padding: 15px;
  background: #000;
  color: white;
  border: none;
  font-size: 1rem;
  font-weight: 500;
  cursor: pointer;
  display: flex;
  justify-content: space-between;
  align-items: center;
  transition: opacity 0.2s;
}

.login-btn:hover:not(:disabled) {
  opacity: 0.8;
}

.login-btn:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.btn-arrow {
  font-family: sans-serif;
}
</style>
