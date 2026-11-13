"use server";

import { apiBase } from "../../lib/api_base";
import type { ConfigDefinition, ConfigValue, FlagInput } from "./app_config_format";

// WA-P5-001: staff calls to the BE-P5-E08 admin API. The staff credential is typed on the page,
// kept only in page memory and sent with each call; nothing is stored or logged here.

export type LastChange = { updatedAt: string; updatedBy: string } | null;

export type AdminFlag = {
  key: string;
  description: string;
  enabled: boolean;
  userIds: string[];
  percentage: number;
  version: number;
  lastChange: LastChange;
};

export type AdminConfigEntry = {
  key: string;
  definition: ConfigDefinition;
  value: ConfigValue;
  isDefault: boolean;
  version: number;
  lastChange: LastChange;
};

export type AdminAppConfig = { version: number; flags: AdminFlag[]; config: AdminConfigEntry[] };

export type AdminResult =
  | { status: "ok"; data: AdminAppConfig }
  | { status: "error"; code: string; message: string; reason?: string };

async function call(token: string, method: string, path: string, body?: unknown): Promise<AdminResult> {
  if (!token.trim()) return { status: "error", code: "STAFF_AUTH_INVALID", message: "Nhập credential staff." };
  try {
    const response = await fetch(`${apiBase()}/api/admin/app-config${path}`, {
      method,
      cache: "no-store",
      headers: {
        Authorization: `Bearer ${token.trim()}`,
        ...(body === undefined ? {} : { "Content-Type": "application/json" }),
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    const payload: unknown = await response.json().catch(() => null);
    if (response.ok) return { status: "ok", data: payload as AdminAppConfig };
    const error = (payload as { error?: { code?: string; details?: { reason?: string }[] } } | null)?.error;
    const code = error?.code ?? "UNKNOWN";
    return { status: "error", code, message: messageFor(response.status, code), reason: error?.details?.[0]?.reason };
  } catch {
    return { status: "error", code: "NETWORK", message: "Không kết nối được API. Kiểm tra dịch vụ backend." };
  }
}

function messageFor(status: number, code: string): string {
  if (code === "CONFIG_CONFLICT") return "Khóa này vừa được người khác sửa. Tải lại rồi sửa lại.";
  if (code === "CONFIG_VALUE_INVALID") return "Giá trị không hợp với khóa này.";
  if (code === "CONFIG_KEY_UNKNOWN") return "Khóa không còn tồn tại trên server.";
  if (status === 401) return "Credential staff không hợp lệ.";
  if (status === 503) return "Server tạm thời không khả dụng hoặc chưa cấu hình staff auth.";
  if (status === 400) return "Dữ liệu gửi lên không hợp lệ.";
  return "Thao tác thất bại. Thử lại.";
}

export async function loadAppConfig(token: string): Promise<AdminResult> {
  return call(token, "GET", "");
}

export async function saveFlag(token: string, key: string, input: FlagInput, version: number): Promise<AdminResult> {
  return call(token, "PUT", `/flags/${encodeURIComponent(key)}`, { ...input, version });
}

export async function saveConfigValue(token: string, key: string, value: ConfigValue, version: number): Promise<AdminResult> {
  return call(token, "PUT", `/values/${encodeURIComponent(key)}`, { value, version });
}

export async function resetConfigValue(token: string, key: string, version: number): Promise<AdminResult> {
  return call(token, "DELETE", `/values/${encodeURIComponent(key)}?version=${version}`);
}
