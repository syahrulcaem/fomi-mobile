export interface ApiEnvelope<T> {
  message?: string;
  data: T;
}

export interface User {
  id: string;
  name: string;
  email: string;
  phone?: string | null;
  address?: string | null;
  role?: string | null;
}

export interface AuthResponse {
  token: string;
  user: User;
}

export interface DashboardStats {
  total_assets: number;
  lost_assets: number;
  active_qr_codes: number;
  total_orders: number;
  remaining_barcode_quota: number;
}

export interface ContactInfo {
  name?: string;
  phone?: string;
  email?: string;
}

export interface QrCode {
  id: number;
  name: string;
  description?: string;
  status: "normal" | "lost" | string;
  code?: string;
  contact_info?: ContactInfo;
  scan_logs_count?: number;
}

export interface OrderItem {
  name: string;
  quantity: number;
  price: number;
}

export interface Order {
  id: number;
  order_number: string;
  status: "pending" | "paid" | "processing" | "shipped" | "completed" | "cancelled" | string;
  total_amount: number;
  created_at?: string;
  payment_method?: string;
  items?: OrderItem[];
}

export interface PrivacySettings {
  show_phone: boolean;
  show_email: boolean;
  allow_finder_contact: boolean;
}

export interface ProfileResponse extends User {
  privacy?: PrivacySettings;
}

export interface RenewalPackage {
  // Preferred identifier for new contract.
  subscription_plan_id?: string | number;
  // Legacy / fallback id from older payloads.
  id?: string | number;
  name: string;
  description?: string;
  price: number;
  barcode_quota?: number;
  qr_quota?: number;
}

export interface CheckoutResponse {
  order_id?: string;
  snap_url?: string;
  snap_token?: string;
  transaction_status?: string;
}

export interface CheckoutProvince {
  id: number;
  name: string;
  rajaongkir_id?: number;
}

export interface CheckoutCity {
  id: number;
  province_id: number;
  type?: string;
  name: string;
  rajaongkir_id?: number;
}

export interface CheckoutDistrict {
  id: number;
  name: string;
  type?: string;
}

export interface MidtransStatusResponse {
  order_id?: string;
  transaction_status: string;
  fraud_status?: string;
  payment_type?: string;
}

export interface MerchandiseItem {
  id: number;
  barcode: string;
  name: string;
  is_active: boolean;
  activated_at?: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  current_page: number;
  last_page: number;
  per_page: number;
  total: number;
}
