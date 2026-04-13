# 🚀 Panduan Deployment MiroFish di VPS (Production)

Panduan ini akan menjelaskan langkah-langkah lengkap untuk meng-online-kan aplikasi **MiroFish** di Virtual Private Server (VPS) bersistem operasi Ubuntu, mulai dari mengunduh kode hingga menyiapkan Domain dan sertifikat SSL 100% aktif (HTTPS).

---

## 🛠 Persiapan Awal
Sebelum memulai, pastikan Anda telah menyiapkan hal-hal berikut:
1. **VPS Baru** dengan OS **Ubuntu 20.04** atau **22.04**.
2. **Domain Aktif** (misalnya `mirofish.contoh.com`).
3. Anda sudah mengarahkan (A Record) Domain/Subdomain Anda di penyedia DNS (seperti Cloudflare atau Niagahoster) ke **IP Publik VPS** Anda.

---

## 💻 Tahap 1: Masuk ke VPS & Unduh Kode dari GitHub

Buka terminal (Mac/Linux) atau PowerShell/Command Prompt (Windows), lalu masuk ke VPS Anda via SSH:
```bash
ssh root@IP_VPS_ANDA
```

Setelah berhasil masuk, unduh kode MiroFish versi terbaru langsung dari *fork* repositori Github Anda sendiri:
```bash
# Pastikan git sudah ter-install (biasanya bawaan Ubuntu)
git clone https://github.com/andihzan/MiroFish.git

# Masuk ke dalam direktori aplikasi
cd MiroFish
```

---

## 🔐 Tahap 2: Atur Password Keamanan & Konfigurasi (PENTING)

Aplikasi ini menggunakan JWT Authentication. Anda wajib membuat *password master* untuk melindungi sistem.

1. Buat tiruan file konfigurasi dari `.env.example`:
   ```bash
   cp .env.example .env
   ```
2. Buka file `.env` menggunakan editor teks (misalnya nano):
   ```bash
   nano .env
   ```
3. Cari bagian **Security** di bagian bawah, lalu ubah nilainya menjadi password rahasia Anda:
   ```env
   # ==========================================
   # Security
   # ==========================================
   # Ubah admin123 menjadi password kuat sesuai keinginan Anda!
   APP_PASSWORD=admin123
   
   # Ubah string di bawah dengan kode acak yang sangat panjang & rumit
   JWT_SECRET_KEY=b7ff9c8d-kunci-rahasia-sangat-susah-ditebak-1234
   ```
   *(Tekan `Ctrl+O` lalu `Enter` untuk menyimpan, lalu `Ctrl+X` untuk keluar).*

---

## ⚙️ Tahap 3: Menjalankan Instalasi Otomatis (Deploy.sh)

Kami telah menyiapkan *Script Instalasi Ajaib* (`deploy.sh`) khusus untuk memudahkan seluruh proses instalasi Docker, Reverse Proxy Nginx, dan Firewall.

1. Beri izin file tersebut agar bisa dieksekusi:
   ```bash
   chmod +x deploy.sh
   ```

2. Jalankan skrip instalasinya:
   ```bash
   ./deploy.sh
   ```

3. Skrip akan berjalan secara otomatis memperbaiki sistem Anda dan memasang Docker secara instan.
   > ⏳ *Catatan: Proses kompilasi Docker (Membangun Image untuk Backend dan Frontend) mungkin akan memakan waktu 5-10 menit tergantung kecepatan CPU VPS Anda.*

---

## 🔒 Tahap 4: Konfigurasi Domain dan SSL (HTTPS) Otomatis

Seusai Docker berhasil menyala, skrip `deploy.sh` akan langsung bertanya dua hal kepada Anda di layar terminal:

1. **"Masukkan nama domain Anda (contoh: mirofish.domain.com):"**
   👉 Ketik domain yang telah Anda arahkan ke IP VPS Anda tadi lalu tekan Enter.

2. **"Masukkan email Anda untuk notifikasi SSL Let's Encrypt:"**
   👉 Ketik alamat email aktif Anda lalu tekan Enter.

Skrip akan secara mandiri menghubungi server **Let's Encrypt** untuk menerbitkan gembok SSL (HTTPS) dan kemudian memuat peraturannya ke dalam server Nginx.

---

## 🎉 Selesai! Aplikasi Sudah Online

Apabila Anda melihat pesan hijau yang bertuliskan **"🎉 Setup Nginx dan Let's Encrypt untuk HTTPS telah selesai!"**, artinya proses telah rampung secara menyeluruh.

Silakan buka browser web Anda dan kunjungi halaman:
- **`https://domain-anda.com`**

Sistem siap menyambut Anda dengan lapisan keamanan dari gembok hijau HTTPS yang solid serta *Password Authentication* yang sebelumnya Anda tanam di file konfigurasi.

> [!TIP]
> **Cara Merestart Aplikasi di Kemudian Hari:**
> Jika Anda mengunggah (push) fitur baru ke Github dan melakukan `git pull` di dalam VPS, Anda wajib me-restart sistem untuk mendeteksi perubahan:
> ```bash
> docker compose down
> docker compose up -d --build
> ```
