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

Mengambil daftar produk aktif.

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

## 10. Order dan Checkout User

### POST `/orders/checkout`

Membuat order checkout biasa dari daftar produk dan menghasilkan Snap token Midtrans.

Request body:

```json
{
    "items": [
        {
            "product_id": 1,
            "quantity": 2
        },
        {
            "product_id": 3,
            "quantity": 1
        }
    ]
}
```

Field:

- `items`: required, array, minimal 1 item
- `items[].product_id`: required, harus ada di tabel products
- `items[].quantity`: required, integer, min 1

Catatan proses:

- Untuk produk fisik, stok dicek sebelum order dibuat
- Order dibuat dengan status awal `pending`
- Payment dibuat dengan status awal `pending`
- Respons mengembalikan `snap_token` dan `redirect_url`

Contoh respons `201`:

```json
{
    "order": {
        "id": 123,
        "order_number": "FOMI-20260314-ABC123",
        "total_amount": 150000,
        "status": "pending",
        "items": [
            {
                "id": 1,
                "product_id": 1,
                "quantity": 2,
                "price": 50000,
                "product": {
                    "id": 1,
                    "name": "QR Tag Basic"
                }
            }
        ],
        "payment": {
            "id": 5,
            "midtrans_order_id": "FOMI-123-1710400000",
            "snap_token": "midtrans-snap-token",
            "status": "pending"
        }
    },
    "snap_token": "midtrans-snap-token",
    "redirect_url": "https://app.sandbox.midtrans.com/snap/v2/vtweb/midtrans-snap-token"
}
```

### GET `/orders`

Mengambil daftar order milik user.

Fitur:

- relasi `items.product`, `payment`, `shipping`
- paginasi `15` item per halaman

### GET `/orders/{order}`

Mengambil detail order milik user.

Relasi yang dimuat:

- `items.product`
- `payment`
- `shipping`
- `subscriptions.asset`

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

Checkout paket perpanjangan langganan dan menghasilkan Snap token Midtrans.

Request body:

```json
{
    "product_id": 7,
    "quantity": 1,
    "renewal_asset_id": 5,
    "customer_name": "Budi",
    "customer_email": "budi@example.com",
    "customer_phone": "08123456789"
}
```

Field:

- `product_id`: required, harus ada di products
- `quantity`: nullable, integer, min 1, max 10, default `1`
- `renewal_asset_id`: nullable, asset milik user
- `customer_name`: nullable, string, max 255
- `customer_email`: nullable, email, max 255
- `customer_phone`: nullable, string, max 20

Contoh respons `201`:

```json
{
    "message": "Checkout renewal berhasil dibuat.",
    "order_id": 124,
    "snap_token": "midtrans-snap-token",
    "midtrans_order_id": "FOMI-124-1710400500",
    "check_status_url": "https://domain-anda/api/midtrans/check-status"
}
```

Catatan:

- Jika `renewal_asset_id` diisi, sistem memastikan asset tersebut milik user login
- Produk harus bertipe `digital` dan punya paket subscription bawaan

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
- `POST /orders/checkout`
- `GET /orders`
- `GET /orders/{order}`
- `POST /merchandise/scan/verify`
- `POST /merchandise/activate`
- `GET /merchandise/my-items`
- `GET /user/dashboard`
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
