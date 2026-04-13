#!/bin/bash
# ==========================================================
# MiroFish VPS Auto Deployment Setup Script (Ubuntu)
# Harus dijalankan sebagai root (atau menggunakan sudo)
# ==========================================================

# ==========================================
# 1. Input Parameter dari User
# ==========================================
echo "=========================================================="
echo "      MiroFish - Server Setup (Docker, Nginx, SSL)        "
echo "=========================================================="
read -p "Masukkan nama Domain APP Anda (contoh: mirofish.domain.com): " DOMAIN_NAME
read -p "Masukkan alamat Email untuk SSL Let's Encrypt: " EMAIL_ADDRESS

if [ -z "$DOMAIN_NAME" ] || [ -z "$EMAIL_ADDRESS" ]; then
    echo "Error: Domain dan Email tidak boleh kosong!"
    exit 1
fi

echo "Memulai instalasi sistem untuk domain: $DOMAIN_NAME"
sleep 2

# ==========================================
# 2. Perbaiki State APT yang Nyangkut (jika ada)
# ==========================================
echo ">>> Membersihkan state APT dan instalasi Nginx yang rusak..."
dpkg --configure -a 2>/dev/null || true
apt --fix-broken install -y 2>/dev/null || true

# Hapus total Nginx agar bisa install dari kondisi bersih
apt purge -y nginx nginx-common nginx-full nginx-core 2>/dev/null || true
apt autoremove -y 2>/dev/null || true

# ==========================================
# 3. Update Sistem & Install Paket Dasar
# ==========================================
echo ">>> 1/5: Update sistem dan install paket dasar..."
apt update && apt upgrade -y
apt install -y curl wget git nano ufw certbot

# ==========================================
# 4. Install Nginx dengan Patch IPv6 Otomatis
# ==========================================
echo ">>> 1.5/5: Install Nginx dan patch konfigurasi IPv6..."

# Langkah 1: Install Nginx - biarkan gagal di post-install (IPv6), file sudah terekstrak
apt install -y nginx 2>/dev/null || true

# Langkah 2: Patch SEMUA file konfigurasi Nginx yang baru saja diekstrak
#            Ganti semua listen [::] dengan versi komentar (# listen [::])
find /etc/nginx -type f \( -name "*.conf" -o -name "default" \) \
    -exec sed -i 's/listen \[::\]/#listen \[::\]/g' {} \;

# Langkah 3: Paksa DPkG selesaikan konfigurasi Nginx (sekarang config sudah aman IPv4)
dpkg --configure nginx 2>/dev/null || true
apt install -y python3-certbot-nginx

# Hapus default site bawaan
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/default

# ==========================================
# 5. Install Docker & Docker Compose
# ==========================================
echo ">>> 2/5: Mengecek Instalasi Docker..."
if ! command -v docker &> /dev/null; then
    echo "Docker belum terinstall. Menginstall Docker sekarang..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    apt-get install -y docker-compose-plugin
    rm get-docker.sh
else
    echo "Docker sudah terinstall."
fi

systemctl enable docker
systemctl start docker

# ==========================================
# 6. Jalankan Aplikasi MiroFish via Docker
# ==========================================
echo ">>> 2.5/5: Menyalakan aplikasi MiroFish via Docker..."
docker compose down 2>/dev/null || true
docker compose up -d --build

# ==========================================
# 7. Setup Nginx Reverse Proxy
# ==========================================
echo ">>> 3/5: Mengkonfigurasi Nginx untuk domain $DOMAIN_NAME..."

cat > /etc/nginx/sites-available/$DOMAIN_NAME <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /api {
        proxy_pass http://127.0.0.1:5001;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Aktifkan config dan reload Nginx
ln -sf /etc/nginx/sites-available/$DOMAIN_NAME /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx

# ==========================================
# 8. Install SSL / HTTPS (Let's Encrypt)
# ==========================================
echo ">>> 4/5: Memasang SSL HTTPS dari Let's Encrypt..."
certbot --nginx -d "$DOMAIN_NAME" --non-interactive --agree-tos -m "$EMAIL_ADDRESS" --redirect

# ==========================================
# 9. Konfigurasi Firewall
# ==========================================
echo ">>> 5/5: Konfigurasi Firewall..."
ufw allow OpenSSH
ufw allow 'Nginx Full'
echo "Firewall sudah dikonfigurasi."

# ==========================================
# Selesai
# ==========================================
echo ""
echo "================================================================="
echo "✅ SETUP SERVER SELESAI! MiroFish sudah ONLINE!"
echo "================================================================="
echo "🌐 Akses Aplikasi : https://$DOMAIN_NAME"
echo "🐳 Docker         : Berjalan di background"
echo "🔒 SSL            : Aktif (Let's Encrypt)"
echo ""
echo "💡 Tips Maintenance:"
echo "   - Restart app  : docker compose restart"
echo "   - Lihat log    : docker compose logs -f"
echo "   - Update app   : git pull && docker compose up -d --build"
echo "================================================================="
