import { supabase } from "@/integrations/supabase/client";

export type AdminListingType = "stay" | "vehicle" | "event" | "property" | "social" | "sme";
export type ModerationStatus = "pending" | "approved" | "rejected" | "suspended";
export type ReportStatus = "pending" | "investigating" | "resolved" | "dismissed";

export interface AdminModerationUpdateInput {
  listingType: AdminListingType;
  listingId: string;
  moderationStatus: ModerationStatus;
  adminNote?: string;
  active?: boolean;
}

export interface AdminReportResolutionInput {
  reportId: string;
  status: ReportStatus;
  adminNote?: string;
}

export interface AdminFeatureFlag {
  id: string;
  flag_key: string;
  enabled: boolean;
  payload: Record<string, unknown>;
  description: string;
  updated_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface AdminMetrics {
  window_days: number;
  generated_at: string;
  users_total: number;
  providers_total: number;
  bookings_total: number;
  bookings_completed: number;
  bookings_cancelled: number;
  gmv_lkr_window: number;
  reports_open: number;
  moderation_pending: number;
  rides_open: number;
  wallet_volume_lkr_window: number;
}

export async function fetchAdminMetrics(days = 30): Promise<AdminMetrics> {
  const { data, error } = await supabase.rpc("admin_dashboard_metrics", { p_days: days });

  if (error) {
    throw new Error(error.message || "Failed to fetch admin metrics");
  }

  return data as AdminMetrics;
}

export async function updateListingModeration(input: AdminModerationUpdateInput): Promise<void> {
  const { error } = await supabase.rpc("admin_update_listing_moderation", {
    p_listing_type: input.listingType,
    p_listing_id: input.listingId,
    p_moderation_status: input.moderationStatus,
    p_admin_note: input.adminNote ?? "",
    p_active: input.active ?? true,
  });

  if (error) {
    throw new Error(error.message || "Failed to update listing moderation");
  }
}

export async function resolveUserReport(input: AdminReportResolutionInput): Promise<void> {
  const { error } = await supabase.rpc("admin_resolve_user_report", {
    p_report_id: input.reportId,
    p_status: input.status,
    p_admin_note: input.adminNote ?? "",
  });

  if (error) {
    throw new Error(error.message || "Failed to resolve user report");
  }
}

export async function fetchFeatureFlags(): Promise<AdminFeatureFlag[]> {
  const { data, error } = await supabase
    .from("admin_feature_flags")
    .select("id, flag_key, enabled, payload, description, updated_by, created_at, updated_at")
    .order("flag_key", { ascending: true });

  if (error) {
    throw new Error(error.message || "Failed to fetch admin feature flags");
  }

  return (data ?? []) as AdminFeatureFlag[];
}

export async function setFeatureFlag(
  flagKey: string,
  enabled: boolean,
  payload: Record<string, unknown> = {},
  description = ""
): Promise<void> {
  const { data: authData, error: authError } = await supabase.auth.getUser();
  if (authError) throw new Error(authError.message);

  const userId = authData.user?.id;
  if (!userId) {
    throw new Error("No active user session");
  }

  const { error } = await supabase.from("admin_feature_flags").upsert(
    {
      flag_key: flagKey,
      enabled,
      payload,
      description,
      updated_by: userId,
      updated_at: new Date().toISOString(),
    },
    { onConflict: "flag_key" }
  );

  if (error) {
    throw new Error(error.message || "Failed to set feature flag");
  }
}
