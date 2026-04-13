#!/bin/bash

# Pindah ke direktori di mana script ini berada
cd "$(dirname "$0")"

echo "=========================================================="
echo "      Menjalankan MiroFish di Localhost (Docker)          "
echo "=========================================================="

# Mengecek apakah Docker sudah berjalan
if ! docker info > /dev/null 2>&1; then
  echo "❌ Error: Docker tidak berjalan. Harap buka aplikasi Docker Desktop terlebih dahulu di Mac Anda!"
  exit 1
fi

echo ">>> Membangun (Build) dan menyalakan kontainer..."
# Menggunakan --build agar perubahan kodingan terbaru (seperti JWT Login) ikut ter-compile
docker compose up -d --build

echo ""
echo "✅ MiroFish berhasil dijalankan di background!"
echo "➡️  Akses Web    : http://localhost:3000"
echo "➡️  Pusat API    : http://localhost:5001"
echo ""
echo "💡 Untuk mematikan aplikasi, jalankan perintah: ./stop.sh"
echo "=========================================================="
