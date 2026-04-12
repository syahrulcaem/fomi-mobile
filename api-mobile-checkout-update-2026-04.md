# Update Khusus API Checkout Mobile (Apr 2026)

Dokumen ini menjelaskan perubahan API checkout mobile agar sinkron dengan checkout web terbaru.

## Ringkasan Perubahan

- Endpoint checkout mobile kini mendukung flow baru:
  - Produk fisik wajib memilih QR aktif (`selected_asset_id`)
  - Mode perpanjang (`renewal_asset_id`) tervalidasi ketat
  - Dukungan pembayaran `bank_transfer` dengan upload bukti
  - Dukungan varian produk (`variant_id`)
- Ditambahkan endpoint context checkout agar mobile bisa merender step checkout tanpa hardcode.
- Ditambahkan endpoint CRUD alamat tersimpan khusus checkout mobile.

## Endpoint Baru (Recommended)

Semua endpoint di bawah membutuhkan Bearer token.

- `GET /api/user/shop/checkout/context`
- `POST /api/user/shop/checkout`
- `GET /api/user/shop/checkout/addresses`
- `POST /api/user/shop/checkout/addresses`
- `DELETE /api/user/shop/checkout/addresses/{address}`

## Endpoint Legacy yang Tetap Didukung

- `POST /api/orders/checkout` (alias ke flow checkout baru)
- `GET /api/orders/checkout/context` (alias ke context checkout baru)
- `POST /api/user/renewal/checkout` (legacy renewal khusus aplikasi lama)

## Kontrak Request Checkout Baru

`POST /api/user/shop/checkout`

Field utama:

- `items` (required, array)
- `items[].product_id` (required)
- `items[].quantity` (required, integer >= 1)
- `items[].variant_id` (opsional, wajib jika produk punya varian)
- `payment_method` (`midtrans` default atau `bank_transfer`)
- `renewal_asset_id` (opsional)
- `selected_asset_id` (wajib jika ada produk fisik)
- `customer_name`, `customer_email`, `customer_phone` (opsional, fallback ke data user)

Jika ada produk fisik, wajib kirim juga:

- `shipping_address`, `shipping_city`, `shipping_province`, `shipping_postal_code`
- `regency_id`, `district_id`
- `shipping_cost`
- `shipping_courier`, `shipping_service`

Jika `payment_method=bank_transfer`, wajib kirim:

- `payment_bank_name`
- `payment_sender_name`
- `payment_proof` (jpg/jpeg/png/webp/pdf max 4MB)

## Aturan Validasi Penting

- Produk fisik:
  - `selected_asset_id` harus milik user
  - asset wajib punya subscription aktif
  - asset wajib punya QR aktif
- Renewal:
  - tidak boleh digabung dengan checkout produk fisik
  - harus tepat 1 item paket subscription dengan quantity 1
- Produk digital non-package:
  - wajib punya sticker template aktif

## Dampak Integrasi Mobile

Untuk migrasi dari flow lama, mobile app perlu:

1. Mengambil context dari `GET /api/user/shop/checkout/context` saat halaman checkout dibuka.
2. Menambahkan step pemilihan QR aktif untuk checkout yang mengandung produk fisik.
3. Mengirim field pengiriman lengkap saat ada produk fisik.
4. Mengirim multipart form saat memilih `bank_transfer`.
5. Tetap memanggil `POST /api/midtrans/check-status` setelah transaksi Midtrans sukses.

## Referensi Dokumen Utama

Detail lengkap endpoint terbaru tersedia di `docs/api-user.md` bagian:

- `Order dan Checkout User (Update Mobile Checkout Apr 2026)`
