# 📦 Dokumentasi API Shop — FOMI Mobile

> Base URL: `https://your-domain.com/api`
> Format: JSON (`Accept: application/json`)
> Auth: Bearer Token via Sanctum (`Authorization: Bearer {token}`)

---

## 📋 Ringkasan Endpoint

| # | Method | Endpoint | Auth | Fungsi |
|---|--------|----------|------|--------|
| 1 | GET | `/dashboard` | ❌ | Data homepage Shop |
| 2 | GET | `/products` | ❌ | Daftar semua produk |
| 3 | GET | `/products/{id}` | ❌ | Detail produk + varian |
| 4 | POST | `/orders/checkout` | ✅ | Buat order & Midtrans token |
| 5 | GET | `/orders` | ✅ | Riwayat order user |
| 6 | GET | `/orders/{id}` | ✅ | Detail order |
| 7 | POST | `/midtrans/webhook` | ❌ | Webhook Midtrans (server-to-server) |
| 8 | POST | `/midtrans/check-status` | ❌ | Cek status pembayaran |

---

## 1. GET `/dashboard` — Homepage Shop

Mengambil data untuk halaman beranda Shop (hero section, kategori, produk unggulan, social proof).

- **Auth**: Tidak diperlukan
- **Method**: `GET`

### Response `200 OK`

```json
{
  "status": "success",
  "data": {
    "hero_section": {
      "title": "If Found... Scan Me Home",
      "subtitle": "Gunakan teknologi FOMI untuk...",
      "cta_primary": {
        "label": "Daftar Gratis",
        "link": "/register"
      },
      "cta_secondary": {
        "label": "Ubah Akun Anak",
        "link": "/profile/child"
      },
      "left_card": {
        "tag": "ORANG",
        "image_url": "https://..."
      },
      "right_card": {
        "tag": "BARANG",
        "image_url": null
      }
    },
    "categories": [
      {
        "id": "1",
        "name": "GELANG",
        "icon_url": null,
        "image_url": "https://..."
      }
    ],
    "merchandise": {
      "filters": ["Gelang", "Gantungan", "Stiker"],
      "products": [
        {
          "id": "01hx...",
          "name": "Gelang FOMI Kids",
          "price": 75000,
          "currency": "Rp",
          "image_url": "https://...",
          "category": "Gelang"
        }
      ]
    },
    "social_proof": {
      "customer_count": 500,
      "rating": 4.9,
      "total_reviews": 1200,
      "avatars": [
        "https://i.pravatar.cc/80?img=12"
      ]
    }
  }
}
```

> **Catatan Mobile**: Gunakan `merchandise.filters` untuk filter chip/tab kategori. Gunakan `merchandise.products` untuk grid produk di homepage.

---

## 2. GET `/products` — Daftar Produk

Mengambil semua produk aktif. Mendukung filter berdasarkan kategori.

- **Auth**: Tidak diperlukan
- **Method**: `GET`
- **Query Params**:

| Param | Tipe | Wajib | Keterangan |
|-------|------|-------|-----------|
| `category` | string | ❌ | Slug kategori untuk filter |

### Response `200 OK`

```json
[
  {
    "id": "01hx...",
    "category_id": "01hx...",
    "name": "Gelang FOMI Kids",
    "description": "Gelang silikon dengan QR Code...",
    "price": 75000,
    "stock": 50,
    "image": "products/gelang.jpg",
    "image_url": "https://...",
    "type": "physical",
    "duration_days": null,
    "is_active": true,
    "variants": [
      {
        "id": "01hx...",
        "product_id": "01hx...",
        "display_name": "Merah - S",
        "attribute_name": "Warna",
        "attribute_value": "Merah",
        "secondary_attribute_name": "Ukuran",
        "secondary_attribute_value": "S",
        "price": 75000,
        "stock": 20,
        "is_active": true,
        "sort_order": 1
      }
    ]
  }
]
```

> **Catatan Mobile**: Field `type` bisa bernilai `"physical"` (barang fisik) atau `"digital"` (langganan/subscription). Cek `variants` untuk menentukan apakah perlu menampilkan variant picker.

---

## 3. GET `/products/{id}` — Detail Produk

Mengambil detail lengkap satu produk beserta semua variannya.

- **Auth**: Tidak diperlukan
- **Method**: `GET`
- **Path Param**: `{id}` — ULID produk

### Response `200 OK`

```json
{
  "id": "01hx...",
  "name": "Gelang FOMI Kids",
  "description": "Gelang silikon dengan QR Code yang dapat dipindai...",
  "price": 75000,
  "stock": 50,
  "image_url": "https://...",
  "type": "physical",
  "duration_days": null,
  "is_active": true,
  "variants": [
    {
      "id": "01hx...",
      "display_name": "Merah - S",
      "attribute_name": "Warna",
      "attribute_value": "Merah",
      "secondary_attribute_name": "Ukuran",
      "secondary_attribute_value": "S",
      "price": 75000,
      "stock": 20,
      "is_active": true
    }
  ]
}
```

### Response `404 Not Found`
```json
{ "message": "Not Found" }
```

> **Catatan Mobile**: 
> - Jika `variants` kosong → tampilkan harga `price` dan stok dari `stock` produk langsung.
> - Jika `variants` ada → paksa user memilih varian sebelum bisa add to cart.
> - Untuk produk `type: "digital"`, `duration_days` berisi lamanya berlangganan (misal 365).

---

## 4. POST `/orders/checkout` — Buat Order & Ambil Midtrans Token

Membuat order baru dan mendapatkan Snap Token Midtrans untuk proses pembayaran.

- **Auth**: ✅ Wajib (Bearer Token)
- **Method**: `POST`
- **Content-Type**: `application/json`

### Request Body

```json
{
  "items": [
    {
      "product_id": "01hx...",
      "variant_id": "01hx...",
      "quantity": 2
    },
    {
      "product_id": "01hx...",
      "variant_id": null,
      "quantity": 1
    }
  ],
  "customer_name": "Budi Santoso",
  "customer_email": "budi@email.com",
  "customer_phone": "081234567890",
  "shipping_address": "Jl. Sudirman No. 10",
  "shipping_city": "Jakarta",
  "shipping_province": "DKI Jakarta",
  "shipping_postal_code": "10110",
  "renewal_asset_id": null
}
```

| Field | Tipe | Wajib | Keterangan |
|-------|------|-------|-----------|
| `items` | array | ✅ | Min 1 item |
| `items[].product_id` | string | ✅ | ULID produk |
| `items[].variant_id` | string\|null | ❌ | ULID varian (jika ada) |
| `items[].quantity` | integer | ✅ | Min 1 |
| `customer_name` | string | ✅ | Nama penerima |
| `customer_email` | string | ✅ | Email penerima |
| `customer_phone` | string | ✅ | Nomor HP penerima |
| `shipping_address` | string | ⚠️ | Wajib jika ada produk `physical` |
| `shipping_city` | string | ⚠️ | Wajib jika ada produk `physical` |
| `shipping_province` | string | ⚠️ | Wajib jika ada produk `physical` |
| `shipping_postal_code` | string | ⚠️ | Wajib jika ada produk `physical` |
| `renewal_asset_id` | string\|null | ❌ | Untuk perpanjangan QR Code |

### Response `201 Created`

```json
{
  "order": {
    "id": "01hx...",
    "order_number": "FOMI-20240318-001",
    "total_amount": 150000,
    "status": "pending",
    "items": [
      {
        "id": 1,
        "product_id": "01hx...",
        "quantity": 2,
        "price": 75000,
        "product": { ... }
      }
    ],
    "payment": {
      "id": "01hx...",
      "midtrans_order_id": "FOMI-1-1710720000",
      "snap_token": "abc123...",
      "status": "pending"
    }
  },
  "snap_token": "abc123...",
  "redirect_url": "https://app.sandbox.midtrans.com/snap/v2/vtweb/abc123..."
}
```

### Response `422 Unprocessable`
```json
{ "message": "Insufficient stock for Gelang FOMI Kids" }
```
atau
```json
{
  "errors": {
    "items": ["The items field is required."],
    "customer_name": ["The customer name field is required."]
  }
}
```

> **Catatan Mobile**:
> - Gunakan `snap_token` dengan Midtrans Mobile SDK.
> - Atau redirect ke `redirect_url` untuk Snap WebView.
> - Setelah pembayaran sukses, hapus keranjang lokal dan panggil endpoint `/midtrans/check-status`.

---

## 5. POST `/midtrans/check-status` — Cek Status Pembayaran

Cek status pembayaran setelah Midtrans mengirim callback onSuccess.

- **Auth**: Tidak diperlukan
- **Method**: `POST`

### Request Body
```json
{ "order_id": "FOMI-1-1710720000" }
```

### Response `200 OK`
```json
{
  "status": "paid",
  "order_id": "FOMI-1-1710720000"
}
```

| Status | Keterangan |
|--------|-----------|
| `paid` | Pembayaran selesai |
| `processing` | Sedang diproses |
| `shipped` | Sudah dikirim |
| `completed` | Order selesai |
| `pending` | Menunggu pembayaran |
| `failed` | Gagal |

---

## 6. GET `/orders` — Riwayat Order

Mengambil daftar order milik user yang sedang login (paginated).

- **Auth**: ✅ Wajib (Bearer Token)
- **Method**: `GET`

### Response `200 OK`
```json
{
  "current_page": 1,
  "data": [
    {
      "id": "01hx...",
      "order_number": "FOMI-20240318-001",
      "total_amount": 150000,
      "status": "pending",
      "created_at": "2024-03-18T07:00:00.000000Z",
      "items": [ ... ],
      "payment": {
        "status": "paid",
        "snap_token": "abc123..."
      },
      "shipping": null
    }
  ],
  "per_page": 15,
  "total": 5
}
```

---

## 7. GET `/orders/{id}` — Detail Order

Mengambil detail lengkap satu order milik user.

- **Auth**: ✅ Wajib (Bearer Token)
- **Method**: `GET`
- **Path Param**: `{id}` — ULID order

### Response `200 OK`
```json
{
  "id": "01hx...",
  "order_number": "FOMI-20240318-001",
  "total_amount": 150000,
  "status": "pending",
  "created_at": "2024-03-18T07:00:00.000000Z",
  "items": [
    {
      "id": 1,
      "quantity": 2,
      "price": 75000,
      "product": {
        "id": "01hx...",
        "name": "Gelang FOMI Kids",
        "image_url": "https://..."
      }
    }
  ],
  "payment": {
    "status": "paid",
    "midtrans_order_id": "FOMI-1-1710720000"
  },
  "shipping": {
    "tracking_number": "JNE123456789",
    "courier": "JNE",
    "status": "shipped"
  },
  "subscriptions": [
    {
      "id": 1,
      "asset": { "id": "01hx...", "name": "Gelang Andi" }
    }
  ]
}
```

### Response `403 Forbidden`
```json
{ "message": "Unauthorized" }
```

---

## 🛒 Manajemen Keranjang (Local Storage)

> **Keranjang disimpan di sisi client** menggunakan `localStorage` dengan key `fomi_cart`. Tidak ada endpoint API khusus untuk keranjang — semua operasi dilakukan lokal.

### Struktur Item Keranjang

```json
[
  {
    "id": "01hx...",
    "product_id": "01hx...",
    "cart_key": "01hx...:01hx...",
    "name": "Gelang FOMI Kids (Merah - S)",
    "base_name": "Gelang FOMI Kids",
    "variant_id": "01hx...",
    "variant_label": "Merah - S",
    "attribute_name": "Warna",
    "attribute_value": "Merah",
    "price": 75000,
    "image_url": "https://...",
    "type": "physical",
    "stock": 20,
    "quantity": 1
  }
]
```

### Logika Keranjang di Mobile

| Aksi | Logika |
|------|--------|
| **Add to cart** | Cek `cart_key = product_id:variant_id` (atau `product_id:base`) |
| **Duplikat** | Jika `cart_key` sudah ada, increment `quantity` |
| **Stok habis** | Jika `type=physical` dan `stock ≤ 0`, tolak penambahan |
| **Varian wajib** | Jika produk punya variant aktif, user harus pilih dulu |
| **Checkout** | Kirim ke `POST /orders/checkout` dengan array `items` |
| **Setelah bayar** | Hapus `localStorage fomi_cart` |

---

## 🔑 Authentication Flow

Endpoint shop yang memerlukan auth menggunakan **Laravel Sanctum** (Bearer Token).

```
POST /api/login
Body: { "email": "...", "password": "..." }
Response: { "token": "1|abc123...", "user": { ... } }

// Gunakan token di header:
Authorization: Bearer 1|abc123...
```

---

## 📱 Alur Lengkap Mobile Shop

```mermaid
graph TD
    A[Buka App] --> B[GET /dashboard]
    B --> C[Homepage: Hero + Kategori + Produk]
    C --> D[Tap Produk]
    D --> E[GET /products/{id}]
    E --> F{Punya Varian?}
    F -->|Ya| G[Tampilkan Variant Picker]
    F -->|Tidak| H[Langsung ke keranjang]
    G --> I[User pilih varian]
    I --> H
    H --> J[Simpan ke localStorage]
    J --> K[Halaman Keranjang]
    K --> L[Isi form penerima]
    L --> M[POST /orders/checkout]
    M --> N[Dapat snap_token]
    N --> O[Buka Midtrans SDK/WebView]
    O -->|Sukses| P[POST /midtrans/check-status]
    P -->|paid| Q[Hapus keranjang → Halaman Sukses]
    P -->|pending| R[Redirect ke riwayat order]
```
