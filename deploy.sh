#!/bin/bash
# ==========================================================
# MiroFish VPS Auto Deployment Setup Script (Ubuntu)
# Harus dijalankan sebagai root (atau menggunakan sudo)
# ==========================================================

# Menghentikan script jika terjadi error
set -e

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
# 2. Update Sistem & Install Nginx, Certbot
# ==========================================
echo ">>> 1/5: Update sistem dan install paket dasar (Nginx, Git, Certbot)..."
apt update && apt upgrade -y

# Install basic tools
apt install -y curl wget git nano ufw certbot

# Buat konfigurasi dummy yang aman (IPv4 ONLY) untuk mencegat instalasi Nginx
mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
cat > /etc/nginx/sites-available/default <<EOF
server {
    listen 80 default_server;
    server_name _;
    root /var/www/html;
}
EOF
ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Remove IPv6 from global config if it exists
sed -i 's/listen \[::\]/# listen \[::\]/g' /etc/nginx/nginx.conf 2>/dev/null || true

# Install Nginx and certbot-nginx. (Pasti akan sukses sekarang)
apt install -y nginx python3-certbot-nginx || true

# Jika tadi masih sempat nyangkut (kondisi awal user), perbaiki paksa:
apt --fix-broken install -y

# Muluskan direktori Nginx untuk domain baru kita
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/default

# ==========================================
# 3. Install Docker & Docker Compose
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

# Memastikan service berjalan saat boot
systemctl enable docker
systemctl start docker

# ==========================================
# 4. Setup Nginx Reverse Proxy
# ==========================================
echo ">>> 3/5: Mengkonfigurasi Nginx untuk domain $DOMAIN_NAME..."

# Membuat file konfigurasi server block Nginx
cat > /etc/nginx/sites-available/$DOMAIN_NAME <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;

    # Mengarahkan trafik ke Frontend (Port 3000)
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        
        # Meneruskan IP asli dari Nginx ke Node.js
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Jika Anda ingin API backend terbuka melalui Nginx misal di /api
    # location /api {
    #     proxy_pass http://127.0.0.1:5001;
    #     ...
    # }
}
EOF

# Aktifkan server block tersebut
if [ -f "/etc/nginx/sites-enabled/$DOMAIN_NAME" ]; then
    rm /etc/nginx/sites-enabled/$DOMAIN_NAME
fi
ln -s /etc/nginx/sites-available/$DOMAIN_NAME /etc/nginx/sites-enabled/

# Hapus default page milik Nginx (opsional)
if [ -f "/etc/nginx/sites-enabled/default" ]; then
    rm /etc/nginx/sites-enabled/default
fi

# Cek apakah Nginx config valid & reload
nginx -t
systemctl restart nginx

# ==========================================
# 5. Install SSL / HTTPS menggunakan Certbot
# ==========================================
echo ">>> 4/5: Memasang SSL HTTPS dari Let's Encrypt..."
# Perintah ini akan mendaftarkan SSL dan otomatis memaksakan (redirect) trafik ke HTTPS
certbot --nginx -d "$DOMAIN_NAME" --non-interactive --agree-tos -m "$EMAIL_ADDRESS" --redirect

# ==========================================
# 6. Konfigurasi Firewall Dasar (UFW)
# ==========================================
echo ">>> 5/5: Konfigurasi Firewall..."
ufw allow OpenSSH
ufw allow 'Nginx Full'
# ufw enable (Dikomment agar tidak mematikan koneksi SSH jika salah config, nyalakan manual nanti)
echo "Firewall sudah dikonfigurasi."

# ==========================================
# Selesai
# ==========================================
echo ""
echo "================================================================="
echo "✅ SETUP SERVER SELESAI!"
echo "================================================================="
echo "Konfigurasi:"
echo "🌐 Domain Anda       : https://$DOMAIN_NAME (Sudah aman ter-SSL!)"
echo "🐳 Docker & Compose : Tersedia"
echo ""
echo "LANGKAH SELANJUTNYA (Yang harus Anda lakukan secara manual):"
echo "1. Clone project MiroFish Anda ke dalam VPS:"
echo "   git clone <URL_GITHUB_ANDA> /var/www/mirofish"
echo ""
echo "2. Masuk ke folder, setup Environment (.env):"
echo "   cd /var/www/mirofish"
echo "   cp .env.example .env"
echo "   nano .env  (Isi LLM_API_KEY & ZEP_API_KEY Anda)"
echo ""
echo "3. Nyalakan Aplikasi:"
echo "   docker compose up -d"
echo "================================================================="
echo ""
