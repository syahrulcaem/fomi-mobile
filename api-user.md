# Dokumentasi API User

Dokumentasi ini mencakup endpoint API yang dapat digunakan oleh user biasa atau publik. Route admin tidak dibahas di dokumen ini.

## Informasi Umum

- Base URL: `/api`
- Format respons: `application/json`
- Autentikasi: Laravel Sanctum Bearer Token
- Header untuk endpoint terproteksi:

```http
Authorization: Bearer {token}
Accept: application/json
```

## Konvensi Respons

- `200 OK`: request berhasil
- `201 Created`: data berhasil dibuat
- `401 Unauthorized`: token tidak ada atau tidak valid
- `403 Forbidden`: user tidak berhak mengakses resource
- `404 Not Found`: resource tidak ditemukan
- `409 Conflict`: resource bentrok, misalnya barcode sudah dipakai
- `422 Unprocessable Entity`: validasi gagal

Contoh respons validasi gagal:

```json
{
    "message": "The given data was invalid.",
    "errors": {
        "email": ["The email field is required."]
    }
}
```

## 1. Auth Publik

### POST `/register`

Mendaftarkan user baru dan langsung mengembalikan token login.

Request body:

```json
{
    "name": "Budi",
    "email": "budi@example.com",
    "phone": "08123456789",
    "password": "password123",
    "password_confirmation": "password123"
}
```

Field:

- `name`: required, string, max 255
- `email`: required, email, unik
- `phone`: nullable, string, max 20
- `password`: required, string, min 8, harus punya `password_confirmation`

Contoh respons `201`:

```json
{
    "message": "Registration successful",
    "user": {
        "id": 1,
        "name": "Budi",
        "email": "budi@example.com",
        "phone": "08123456789",
        "role": "user",
        "created_at": "2026-03-14T10:00:00.000000Z",
        "updated_at": "2026-03-14T10:00:00.000000Z"
    },
    "token": "1|sanctum-token"
}
```

### POST `/login`

Login user dan mengembalikan token Sanctum.

Request body:

```json
{
    "email": "budi@example.com",
    "password": "password123"
}
```

Field:

- `email`: required, email
- `password`: required

Contoh respons `200`:

```json
{
    "message": "Login successful",
    "user": {
        "id": 1,
        "name": "Budi",
        "email": "budi@example.com",
        "phone": "08123456789"
    },
    "token": "2|sanctum-token"
}
```

## 2. Produk Publik

### GET `/products`

Mengambil daftar produk aktif khusus **produk barang** (`type=physical`, non paket langganan).

Query parameter opsional:

- `category_id`: filter berdasarkan ULID kategori produk
- `category`: filter berdasarkan `id` / `slug` / `name` kategori

Contoh respons `200`:

```json
[
    {
        "id": 1,
        "category_id": 2,
        "name": "QR Tag Basic",
        "description": "Tag QR untuk barang pribadi",
        "price": 50000,
        "stock": 100,
        "image": "products/qrbasic.png",
        "type": "physical",
        "duration_days": 30,
        "included_subscription_plan_id": null,
        "is_active": true,
        "created_at": "2026-03-12T08:00:00.000000Z",
        "updated_at": "2026-03-12T08:00:00.000000Z"
    }
]
```

### GET `/products/{product}`

Mengambil detail satu produk berdasarkan ID.

Path parameter:

- `product`: ID produk

## 3. Scan QR Publik

### GET `/scan/{code}`

Memproses scan QR aktif dan otomatis membuat scan log. Endpoint ini boleh menerima query/body input lokasi dari frontend.

Path parameter:

- `code`: kode QR

Input opsional:

- `latitude`: koordinat latitude
- `longitude`: koordinat longitude
- `location_name`: nama lokasi

Kemungkinan respons:

Status normal:

```json
{
    "status": "normal",
    "message": "This item is safe. Owner information is protected.",
    "item_name": "Tas Kerja",
    "chat_enabled": false
}
```

Status hilang:

```json
{
    "status": "lost",
    "message": "This item has been reported as LOST. Please contact the owner.",
    "item_name": "Tas Kerja",
    "contact_info": {
        "name": "Budi",
        "phone": "08123456789",
        "email": "budi@example.com",
        "address": "Jakarta"
    },
    "chat_enabled": true,
    "asset_id": 5
}
```

Langganan habis:

```json
{
    "status": "subscription_expired",
    "message": "Subscription has ended. Owner needs to renew the subscription.",
    "item_name": "Tas Kerja",
    "chat_enabled": false
}
```

### POST `/scan/{code}/chat`

Mengirim pesan anonim dari penemu barang ke pemilik barang yang sedang berstatus hilang.

Request body:

```json
{
    "session_id": "finder-session-123",
    "message": "Halo, barang ini saya temukan di parkiran."
}
```

Field:

- `session_id`: required, string
- `message`: required, string, max 1000

Contoh respons `201`:

```json
{
    "message": "Message sent successfully",
    "chat": {
        "id": 10,
        "asset_id": 5,
        "sender_type": "finder",
        "message": "Halo, barang ini saya temukan di parkiran.",
        "session_id": "finder-session-123",
        "created_at": "2026-03-14T10:15:00.000000Z",
        "updated_at": "2026-03-14T10:15:00.000000Z"
    }
}
```

Catatan:

- Chat hanya bisa digunakan jika asset berstatus `lost`
- Jika QR tidak ditemukan akan mengembalikan `404`
- Jika asset tidak berstatus hilang akan mengembalikan `403`

### GET `/scan/{code}/chats/{sessionId}`

Mengambil riwayat chat anonim antara finder dan owner untuk satu sesi.

Path parameter:

- `code`: kode QR
- `sessionId`: session finder

Contoh respons `200`:

```json
[
    {
        "id": 10,
        "asset_id": 5,
        "sender_type": "finder",
        "message": "Halo, barang ini saya temukan di parkiran.",
        "session_id": "finder-session-123",
        "created_at": "2026-03-14T10:15:00.000000Z",
        "updated_at": "2026-03-14T10:15:00.000000Z"
    },
    {
        "id": 11,
        "asset_id": 5,
        "sender_type": "owner",
        "message": "Terima kasih, apakah bisa saya ambil sore ini?",
        "session_id": "finder-session-123",
        "created_at": "2026-03-14T10:17:00.000000Z",
        "updated_at": "2026-03-14T10:17:00.000000Z"
    }
]
```

## 4. FAQ dan Kontak

### GET `/faqs`

Mengambil FAQ aktif.

Contoh respons `200`:

```json
{
    "data": [
        {
            "id": 1,
            "question": "Bagaimana cara scan QR?",
            "answer": "Buka kamera lalu arahkan ke QR.",
            "order": 1
        }
    ]
}
```

### POST `/contact-us`

Mengirim pesan ke tim melalui form kontak.

Request body:

```json
{
    "name": "Budi",
    "email": "budi@example.com",
    "subject": "Bantuan QR",
    "message": "Saya ingin menanyakan status langganan saya."
}
```

Field:

- `name`: required, string, max 255
- `email`: required, email, max 255
- `subject`: required, string, max 255
- `message`: required, string

Contoh respons `201`:

```json
{
    "message": "Pesan berhasil terkirim!"
}
```

## 5. Midtrans untuk User Flow

### POST `/midtrans/check-status`

Dipakai frontend setelah pembayaran Midtrans sukses untuk memeriksa status order dan mengaktifkan order jika webhook belum diproses. Endpoint ini tidak memakai auth, tetapi hanya menerima `order_id` valid.

Request body:

```json
{
    "order_id": 123
}
```

Kemungkinan respons `200`:

```json
{
    "message": "Order activated",
    "status": "paid"
}
```

```json
{
    "message": "Payment still pending",
    "status": "pending"
}
```

```json
{
    "message": "Order already processed",
    "status": "processing"
}
```

Catatan:

- Endpoint webhook Midtrans internal sistem tidak didokumentasikan untuk konsumsi user

## 6. Auth User

Semua endpoint di bawah ini memerlukan Bearer Token.

### POST `/logout`

Menghapus token akses aktif.

Contoh respons `200`:

```json
{
    "message": "Logged out successfully"
}
```

### GET `/me`

Mengambil profil user yang sedang login beserta relasi `subscriptions.asset`.

## 7. Profil User Versi Umum

Endpoint ini tersedia di luar prefix `/user` dan dapat dipakai oleh aplikasi yang memakai struktur API lama.

### GET `/profile`

Mengambil profil user, subscription aktif, dan maksimal 10 order terbaru.

### PUT `/profile`

Update profil dasar user.

Request body:

```json
{
    "name": "Budi Santoso",
    "phone": "08123456789"
}
```

Field:

- `name`: optional, string, max 255
- `phone`: nullable, string, max 20

Contoh respons `200`:

```json
{
    "message": "Profile updated",
    "user": {
        "id": 1,
        "name": "Budi Santoso",
        "email": "budi@example.com",
        "phone": "08123456789"
    }
}
```

## 8. Asset dan QR Milik User

### GET `/assets`

Mengambil seluruh asset milik user dengan relasi `qrCodes` dan `activeSubscription`.

### POST `/assets`

Membuat asset baru sekaligus generate QR code otomatis.

Request body: `multipart/form-data`

Field:

- `name`: required, string, max 255
- `description`: nullable, string
- `image`: nullable, file image, max 2048 KB
- `contact_info`: nullable, object/array
- `contact_info.phone`: nullable, string
- `contact_info.email`: nullable, email
- `contact_info.address`: nullable, string

Contoh respons `201`:

```json
{
    "id": 5,
    "user_id": 1,
    "name": "Tas Kerja",
    "description": "Tas laptop hitam",
    "image": "assets/abc123.jpg",
    "status": "normal",
    "contact_info": {
        "phone": "08123456789",
        "email": "budi@example.com",
        "address": "Jakarta"
    },
    "qr_codes": [
        {
            "id": 8,
            "asset_id": 5,
            "code": "uuid-code",
            "is_active": true
        }
    ]
}
```

### GET `/assets/{asset}`

Mengambil detail asset milik user dengan relasi `qrCodes`, `activeSubscription`, dan `scanLogs`.

Path parameter:

- `asset`: ID asset

Jika asset bukan milik user, respons `403`.

### PUT `/assets/{asset}`

Memperbarui data asset milik user.

Request body:

```json
{
    "name": "Tas Kerja Baru",
    "description": "Tas laptop hitam ukuran 15 inci",
    "contact_info": {
        "phone": "08123456789",
        "email": "budi@example.com",
        "address": "Jakarta"
    }
}
```

Field:

- `name`: optional, string, max 255
- `description`: nullable, string
- `image`: nullable, file image, max 2048 KB
- `contact_info`: nullable, object/array

### PATCH `/assets/{asset}/toggle-status`

Mengubah status asset antara `normal` dan `lost`.

Contoh respons `200`:

```json
{
    "message": "Status updated to lost",
    "asset": {
        "id": 5,
        "status": "lost"
    }
}
```

## 9. Scan Log dan Chat Owner

### GET `/assets/{asset}/scan-logs`

Mengambil riwayat scan asset milik user.

Fitur:

- relasi `qrCode` ikut dimuat
- paginasi `20` item per halaman

Contoh respons `200`:

```json
{
    "current_page": 1,
    "data": [
        {
            "id": 1,
            "asset_id": 5,
            "qr_code_id": 8,
            "ip_address": "127.0.0.1",
            "latitude": "-6.2",
            "longitude": "106.8",
            "location_name": "Jakarta",
            "user_agent": "Mozilla/5.0",
            "qr_code": {
                "id": 8,
                "code": "uuid-code",
                "is_active": true
            }
        }
    ],
    "per_page": 20,
    "total": 1
}
```

### GET `/assets/{asset}/chats`

Mengambil seluruh chat anonim untuk asset milik user, dikelompokkan berdasarkan `session_id`.

Contoh respons `200`:

```json
{
    "finder-session-123": [
        {
            "id": 10,
            "sender_type": "finder",
            "message": "Halo, barang ini saya temukan.",
            "session_id": "finder-session-123"
        },
        {
            "id": 11,
            "sender_type": "owner",
            "message": "Terima kasih.",
            "session_id": "finder-session-123"
        }
    ]
}
```

### POST `/assets/{asset}/chats`

Mengirim balasan chat sebagai owner.

Request body:

```json
{
    "session_id": "finder-session-123",
    "message": "Terima kasih, saya akan ambil hari ini."
}
```

Field:

- `session_id`: required, string
- `message`: required, string, max 1000

Contoh respons `201`:

```json
{
    "id": 11,
    "asset_id": 5,
    "sender_type": "owner",
    "message": "Terima kasih, saya akan ambil hari ini.",
    "session_id": "finder-session-123",
    "created_at": "2026-03-14T10:17:00.000000Z",
    "updated_at": "2026-03-14T10:17:00.000000Z"
}
```

## 10. API Mobile Dashboard User (Prefix `/user`)

Endpoint di bawah ini dirancang untuk konsumsi mobile app dan semuanya memerlukan Bearer token.

### GET `/user/chats`

Mengambil daftar thread chat anonim milik user (owner) lintas aset.

Contoh respons `200`:

```json
{
    "data": [
        {
            "asset_id": "01JQ...",
            "asset_name": "Tas Kerja",
            "asset_status": "lost",
            "session_id": "finder-abc123-1742280000000",
            "last_message": "Apakah bisa saya antar malam ini?",
            "last_sender_type": "finder",
            "last_message_at": "2026-03-18T08:10:00.000000Z",
            "message_count": 4
        }
    ]
}
```

### GET `/user/chats/{asset}/{sessionId}`

Mengambil detail pesan untuk satu thread chat anonim.

Contoh respons `200`:

```json
{
    "asset": {
        "id": "01JQ...",
        "name": "Tas Kerja",
        "status": "lost"
    },
    "session_id": "finder-abc123-1742280000000",
    "data": [
        {
            "id": "01JQ...",
            "asset_id": "01JQ...",
            "sender_type": "finder",
            "message": "Halo, saya menemukan barang ini.",
            "session_id": "finder-abc123-1742280000000",
            "created_at": "2026-03-18T08:00:00.000000Z",
            "updated_at": "2026-03-18T08:00:00.000000Z"
        }
    ]
}
```

### POST `/user/chats/{asset}/{sessionId}/reply`

Mengirim balasan dari owner ke thread chat tertentu.

Request body:

```json
{
    "message": "Siap, terima kasih infonya."
}
```

Contoh respons `201`:

```json
{
    "message": "Balasan berhasil dikirim.",
    "data": {
        "id": "01JQ...",
        "asset_id": "01JQ...",
        "sender_type": "owner",
        "message": "Siap, terima kasih infonya.",
        "session_id": "finder-abc123-1742280000000",
        "created_at": "2026-03-18T08:12:00.000000Z",
        "updated_at": "2026-03-18T08:12:00.000000Z"
    }
}
```

### DELETE `/user/chats/{asset}/{sessionId}`

Menghapus seluruh thread chat anonim pada satu session finder.

Contoh respons `200`:

```json
{
    "message": "Percakapan berhasil dihapus.",
    "deleted_count": 4
}
```

### DELETE `/user/chats/{asset}/message/{chat}`

Menghapus satu pesan chat anonim tertentu (owner side).

Contoh respons `200`:

```json
{
    "message": "Pesan berhasil dihapus."
}
```

## 11. Order dan Checkout User (Update Mobile Checkout Apr 2026)

Flow checkout mobile sekarang mengikuti flow checkout web terbaru (multi-step, dukungan produk fisik + digital, renewal, dan manual bank transfer).

Endpoint utama checkout baru:

- `POST /user/shop/checkout`

Endpoint lama yang tetap tersedia (alias):

- `POST /orders/checkout`

### GET `/user/shop/checkout/context`

Mengambil data awal yang dibutuhkan sebelum user checkout.

Response utama:

- `customer` (nama/email/phone default)
- `midtrans` (`client_key`, `is_production`, `check_status_url`)
- `renewal_targets` (aset yang bisa dipilih untuk mode perpanjang)
- `active_qr_assets` (aset QR aktif untuk checkout produk fisik)
- `saved_addresses` (alamat tersimpan milik user)
- `available_shipping_couriers` (kurir yang aktif di sistem)

Catatan:

- Endpoint alias juga tersedia di `GET /orders/checkout/context`

### GET `/user/shop/checkout/addresses`

Mengambil daftar alamat tersimpan milik user untuk checkout.

### POST `/user/shop/checkout/addresses`

Menyimpan alamat baru milik user.

Request body:

```json
{
    "label": "Rumah",
    "shipping_address": "Jl. Melati No. 10",
    "shipping_postal_code": "40123",
    "province_id": 32,
    "regency_id": 3273,
    "district_id": 3273010,
    "district_name": "Coblong"
}
```

### DELETE `/user/shop/checkout/addresses/{address}`

Menghapus alamat tersimpan milik user.

### POST `/user/shop/checkout`

Membuat order checkout sesuai sistem checkout terbaru.

Request body contoh (Midtrans, produk fisik):

```json
{
    "items": [
        {
            "product_id": "01J...",
            "variant_id": "01J...",
            "quantity": 1
        }
    ],
    "payment_method": "midtrans",
    "selected_asset_id": "01J...",
    "customer_name": "Budi",
    "customer_email": "budi@example.com",
    "customer_phone": "08123456789",
    "shipping_address": "Jl. Melati No. 10",
    "shipping_city": "Kota Bandung",
    "shipping_province": "Jawa Barat",
    "shipping_postal_code": "40123",
    "regency_id": 3273,
    "district_id": 3273010,
    "shipping_cost": 12000,
    "shipping_courier": "jne",
    "shipping_service": "REG"
}
```

Request body contoh (manual bank transfer):

`multipart/form-data`

- semua field checkout biasa
- `payment_method=bank_transfer`
- `payment_bank_name`
- `payment_sender_name`
- `payment_proof` (jpg/jpeg/png/webp/pdf max 4 MB)

Field penting:

- `items`: required, array minimal 1 item
- `items[].product_id`: required
- `items[].variant_id`: optional (menjadi wajib jika produk punya varian aktif)
- `items[].quantity`: required, integer, min 1
- `payment_method`: optional, `midtrans` (default) atau `bank_transfer`
- `renewal_asset_id`: optional (mode perpanjang QR)
- `selected_asset_id`: required jika checkout mengandung produk fisik

Field pengiriman (wajib jika ada produk fisik):

- `shipping_address`, `shipping_city`, `shipping_province`, `shipping_postal_code`
- `regency_id`, `district_id`
- `shipping_cost`
- `shipping_courier` (harus termasuk kurir yang aktif)
- `shipping_service`

Aturan bisnis penting:

- Checkout produk fisik wajib memilih `selected_asset_id` yang aktif (punya subscription aktif + QR aktif).
- `renewal_asset_id` tidak boleh digabung dengan checkout produk fisik.
- Jika `renewal_asset_id` diisi, checkout harus tepat 1 item paket subscription dengan quantity 1.
- Produk digital non-package wajib punya template sticker aktif.

Contoh respons `201` (Midtrans):

```json
{
    "message": "Checkout berhasil dibuat.",
    "order_id": "01J...",
    "snap_token": "midtrans-snap-token",
    "check_status_url": "https://domain-anda/api/midtrans/check-status",
    "redirect_url": "https://app.sandbox.midtrans.com/snap/v2/vtweb/midtrans-snap-token",
    "order": {
        "id": "01J...",
        "status": "pending"
    }
}
```

Contoh respons `201` (bank transfer manual):

```json
{
    "manual_payment": true,
    "order_id": "01J...",
    "order_number": "FOMI-20260409-ABC123",
    "message": "Bukti transfer berhasil dikirim. Admin akan memverifikasi pembayaran Anda."
}
```

### GET `/orders`

Mengambil daftar order milik user.

Fitur:

- relasi `items.product`, `payment`, `shipping`, `renewalAsset`, `selectedAsset.qrCodes`
- paginasi `15` item per halaman

### GET `/orders/{order}`

Mengambil detail order milik user.

Relasi yang dimuat:

- `items.product`
- `payment`
- `shipping`
- `subscriptions.asset`
- `renewalAsset`
- `selectedAsset.qrCodes`

Jika order bukan milik user, respons `403`.

## 11. Aktivasi Merchandise

### POST `/merchandise/scan/verify`

Verifikasi barcode merchandise. Jika barcode masih `unused`, endpoint ini sekaligus mengaktifkan barcode untuk user.

Request body:

```json
{
    "barcode_code": "FOMI-MERCH-001",
    "activation_data": {
        "nickname": "Koper Abu",
        "notes": "Dipasang di handle koper",
        "color": "abu-abu"
    }
}
```

Field:

- `barcode_code`: required, string, max 255
- `activation_data`: nullable, object
- `activation_data.nickname`: nullable, string, max 255
- `activation_data.notes`: nullable, string, max 1000
- `activation_data.color`: nullable, string, max 100

Kemungkinan respons:

Barcode berhasil diaktifkan `200`:

```json
{
    "message": "Merchandise berhasil diverifikasi dan diaktifkan untuk 30 hari.",
    "barcode": {
        "id": 1,
        "barcode_code": "FOMI-MERCH-001",
        "status": "activated",
        "subscription_days": 30,
        "asset": {
            "id": 5,
            "name": "Koper Abu",
            "qr_codes": [
                {
                    "id": 8,
                    "code": "uuid-code",
                    "is_active": true
                }
            ]
        }
    },
    "activated": true
}
```

Barcode sudah aktif di akun yang sama `200`:

```json
{
    "message": "Barcode ini sudah aktif di akun Anda.",
    "barcode": {
        "id": 1,
        "status": "activated"
    },
    "activated": true
}
```

Barcode sudah dipakai user lain `409`:

```json
{
    "message": "Barcode sudah diaktifkan.",
    "barcode": {
        "id": 1,
        "status": "activated"
    }
}
```

### POST `/merchandise/activate`

Mengaktifkan barcode merchandise secara eksplisit.

Request body:

```json
{
    "barcode_code": "FOMI-MERCH-001",
    "activation_data": {
        "nickname": "Koper Abu",
        "notes": "Dipasang di handle koper",
        "color": "abu-abu"
    }
}
```

Field:

- `barcode_code`: required, string
- `activation_data`: required, object

### GET `/merchandise/my-items`

Mengambil daftar merchandise yang sudah aktif untuk user login.

Fitur:

- relasi `asset.qrCodes`
- paginasi `12` item per halaman

## 12. Mobile User Dashboard API

Endpoint pada grup ini berada di bawah prefix `/user`.

### GET `/user/dashboard`

Mengambil ringkasan dashboard user untuk aplikasi mobile.

Isi respons utama:

- `user`: profil ringkas user
- `stats.total_assets`
- `stats.lost_assets`
- `stats.active_qr_codes`
- `stats.total_orders`
- `stats.remaining_barcode_quota`
- `active_plan_subscription`
- `recent_assets`
- `expired_assets`
- `recent_orders`
- `renewal_packages`
- `midtrans.client_key`
- `midtrans.is_production`
- `midtrans.check_status_url`

### GET `/user/renewal/packages`

Mengambil daftar produk digital aktif yang memiliki `included_subscription_plan_id` untuk dipakai sebagai paket perpanjangan langganan.

Contoh respons `200`:

```json
{
    "data": [
        {
            "id": 7,
            "name": "Paket Renewal 30 Hari",
            "type": "digital",
            "price": 25000,
            "included_subscription_plan": {
                "id": 2,
                "duration_days": 30,
                "qr_quota": 1
            }
        }
    ]
}
```

### POST `/user/renewal/checkout`

Endpoint legacy khusus renewal yang masih dipertahankan untuk kompatibilitas aplikasi lama.

Untuk implementasi mobile baru, disarankan migrasi ke endpoint unified checkout:

- `POST /user/shop/checkout` dengan payload `items` + `renewal_asset_id`

### GET `/user/qrcodes`

Mengambil daftar asset user yang terkait QR code.

Query parameter:

- `per_page`: opsional, default `12`

Relasi yang dimuat:

- `qrCodes`
- `activeSubscription`
- `subscriptions`

### PUT `/user/qrcodes/{asset}`

Memperbarui data QR/asset untuk user.

Request body:

```json
{
    "name": "Tas Kerja",
    "description": "Tas laptop hitam",
    "contact_name": "Budi",
    "contact_phone": "08123456789",
    "contact_email": "budi@example.com",
    "contact_address": "Jakarta",
    "contact_note": "Hubungi via WhatsApp"
}
```

Field:

- `name`: required, string, max 255
- `description`: nullable, string, max 1000
- `contact_name`: nullable, string, max 255
- `contact_phone`: nullable, string, max 50
- `contact_email`: nullable, email, max 255
- `contact_address`: nullable, string, max 500
- `contact_note`: nullable, string, max 1000

Contoh respons `200`:

```json
{
    "message": "Data QR berhasil diperbarui.",
    "asset": {
        "id": 5,
        "name": "Tas Kerja",
        "description": "Tas laptop hitam",
        "contact_info": {
            "name": "Budi",
            "phone": "08123456789",
            "email": "budi@example.com",
            "address": "Jakarta",
            "note": "Hubungi via WhatsApp"
        }
    }
}
```

### PATCH `/user/qrcodes/{asset}/toggle-lost`

Mengubah status asset antara `lost` dan `normal`.

Contoh respons saat menjadi hilang:

```json
{
    "message": "Status barang diubah menjadi HILANG.",
    "asset": {
        "id": 5,
        "status": "lost"
    }
}
```

### GET `/user/orders`

Mengambil daftar order user untuk tampilan mobile.

Query parameter:

- `per_page`: opsional, default `10`

Relasi yang dimuat:

- `items.product`
- `shipping`
- `payment`
- `selectedAsset.qrCodes`
- `renewalAsset`

### GET `/user/orders/{order}`

Mengambil detail order user untuk tampilan mobile.

Relasi yang dimuat:

- `items.product`
- `shipping`
- `payment`
- `subscriptions.asset`
- `renewalAsset`

### GET `/user/profile`

Mengambil profil user versi mobile.

Contoh respons `200`:

```json
{
    "id": 1,
    "name": "Budi",
    "email": "budi@example.com",
    "phone": "08123456789",
    "address": "Jakarta",
    "privacy_settings": ["name", "phone"],
    "role": "user"
}
```

### PUT `/user/profile`

Memperbarui profil user versi mobile.

Request body:

```json
{
    "name": "Budi Santoso",
    "email": "budi@example.com",
    "phone": "08123456789",
    "address": "Jakarta"
}
```

Field:

- `name`: required, string, max 255
- `email`: required, email, unik kecuali milik user sendiri
- `phone`: nullable, string, max 20
- `address`: nullable, string, max 500

### PUT `/user/profile/password`

Mengubah password user.

Request body:

```json
{
    "current_password": "password123",
    "password": "passwordBaru123",
    "password_confirmation": "passwordBaru123"
}
```

Field:

- `current_password`: required
- `password`: required, string, min 8, confirmed

Contoh respons `200`:

```json
{
    "message": "Password berhasil diubah."
}
```

Jika password saat ini salah, respons `422`:

```json
{
    "message": "Password saat ini tidak sesuai."
}
```

### PUT `/user/profile/privacy`

Menyimpan pengaturan privasi field yang boleh ditampilkan saat QR discan.

Request body:

```json
{
    "privacy": ["name", "phone", "email"]
}
```

Field yang diizinkan:

- `name`
- `phone`
- `email`
- `address`

Contoh respons `200`:

```json
{
    "message": "Pengaturan privasi disimpan.",
    "privacy_settings": ["name", "phone", "email"]
}
```

## Ringkasan Endpoint

### Public

- `POST /register`
- `POST /login`
- `GET /products`
- `GET /products/{product}`
- `GET /scan/{code}`
- `POST /scan/{code}/chat`
- `GET /scan/{code}/chats/{sessionId}`
- `GET /faqs`
- `POST /contact-us`
- `POST /midtrans/check-status`

### Authenticated User

- `POST /logout`
- `GET /me`
- `GET /profile`
- `PUT /profile`
- `GET /assets`
- `POST /assets`
- `GET /assets/{asset}`
- `PUT /assets/{asset}`
- `PATCH /assets/{asset}/toggle-status`
- `GET /assets/{asset}/scan-logs`
- `GET /assets/{asset}/chats`
- `POST /assets/{asset}/chats`
- `GET /orders/checkout/context`
- `POST /orders/checkout`
- `GET /orders`
- `GET /orders/{order}`
- `POST /merchandise/scan/verify`
- `POST /merchandise/activate`
- `GET /merchandise/my-items`
- `GET /user/dashboard`
- `GET /user/shop/checkout/context`
- `POST /user/shop/checkout`
- `GET /user/shop/checkout/addresses`
- `POST /user/shop/checkout/addresses`
- `DELETE /user/shop/checkout/addresses/{address}`
- `GET /user/renewal/packages`
- `POST /user/renewal/checkout`
- `GET /user/qrcodes`
- `PUT /user/qrcodes/{asset}`
- `PATCH /user/qrcodes/{asset}/toggle-lost`
- `GET /user/orders`
- `GET /user/orders/{order}`
- `GET /user/profile`
- `PUT /user/profile`
- `PUT /user/profile/password`
- `PUT /user/profile/privacy`
