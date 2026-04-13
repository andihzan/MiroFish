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
# 2. Aktifkan IPv6 di Kernel (Kunci Utama!)
# ==========================================
# VPS baru sering menonaktifkan IPv6. Nginx default Ubuntu
# membutuhkan IPv6 saat pertama kali start. Kita aktifkan sementara
# agar proses instalasi berjalan mulus.
echo ">>> 0/5: Memastikan dukungan IPv6 kernel aktif..."
echo 0 > /proc/sys/net/ipv6/conf/all/disable_ipv6
echo 0 > /proc/sys/net/ipv6/conf/default/disable_ipv6
echo 0 > /proc/sys/net/ipv6/conf/lo/disable_ipv6

# ==========================================
# 3. Perbaiki State APT yang Nyangkut (jika ada)
# ==========================================
# Jika sebelumnya ada proses apt yang gagal di tengah jalan,
# kita perbaiki dulu sebelum melakukan apapun.
echo ">>> Membersihkan state APT yang mungkin rusak..."
dpkg --configure -a 2>/dev/null || true
apt --fix-broken install -y 2>/dev/null || true

# ==========================================
# 4. Update Sistem & Install Nginx, Certbot
# ==========================================
echo ">>> 1/5: Update sistem dan install paket dasar (Nginx, Git, Certbot)..."
apt update && apt upgrade -y
apt install -y curl wget git nano ufw nginx certbot python3-certbot-nginx

# Hapus konfigurasi default Nginx (yang berisi IPv6)
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
