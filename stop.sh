#!/bin/bash

# Pindah ke direktori di mana script ini berada
cd "$(dirname "$0")"

echo "=========================================================="
echo "      Mematikan MiroFish di Localhost                     "
echo "=========================================================="

# Mengecek apakah Docker sudah berjalan
if ! docker info > /dev/null 2>&1; then
  echo "❌ Error: Docker tidak berjalan."
  exit 1
fi

echo ">>> Menghentikan kontainer MiroFish..."
docker compose down

echo ""
echo "✅ MiroFish berhasil dimatikan secara total."
echo "=========================================================="
