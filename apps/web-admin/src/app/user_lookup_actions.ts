"use server";

export type UserAccountSummary = {
  id: string;
  email: string;
  locale: string;
  timezone: string;
  defaultCurrencyCode: string;
  fiscalMonthStartDay: number;
  createdAt: string;
};

export type UserLookupState =
  | { status: "idle" }
  | { status: "success"; user: UserAccountSummary }
  | { status: "error"; message: string };

export async function lookupUserAccount(
  _previousState: UserLookupState,
  formData: FormData,
): Promise<UserLookupState> {
  const staffToken = formValue(formData, "staffToken");
  const lookupType = formValue(formData, "lookupType");
  const lookupValue = formValue(formData, "lookupValue");

  if (!staffToken || !lookupValue) {
    return {
      status: "error",
      message: "Nhập credential staff và giá trị cần tra cứu.",
    };
  }
  if (lookupType !== "email" && lookupType !== "userId") {
    return {
      status: "error",
      message: "Tiêu chí tra cứu không hợp lệ.",
    };
  }

  const apiBase =
    process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:4000";
  try {
    const response = await fetch(`${apiBase}/api/admin/user-lookups`, {
      method: "POST",
      cache: "no-store",
      headers: {
        Authorization: `Bearer ${staffToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ [lookupType]: lookupValue }),
    });

    if (response.ok) {
      return {
        status: "success",
        user: (await response.json()) as UserAccountSummary,
      };
    }
    return {
      status: "error",
      message: messageForStatus(response.status),
    };
  } catch {
    return {
      status: "error",
      message: "Không kết nối được API. Kiểm tra dịch vụ backend.",
    };
  }
}

function formValue(formData: FormData, key: string): string {
  const value = formData.get(key);
  return typeof value === "string" ? value.trim() : "";
}

function messageForStatus(status: number): string {
  switch (status) {
    case 400:
      return "Giá trị tra cứu không đúng định dạng.";
    case 401:
      return "Credential staff không hợp lệ.";
    case 404:
      return "Không tìm thấy tài khoản phù hợp.";
    case 503:
      return "Tra cứu tạm thời không khả dụng hoặc không thể ghi audit.";
    default:
      return "Tra cứu thất bại. Vui lòng thử lại.";
  }
}
