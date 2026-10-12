import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  SENTRY_REDACT_CENSOR,
  scrubSentryEvent,
  sentryBeforeSend,
} from "./scrub.ts";

const EMAIL = "user@example.com";
const SECRET = "secret-token";
const AMOUNT = 150000;

describe("admin sentry scrub (INF-P1-001)", () => {
  it("drops user, request payload, and sensitive fields", () => {
    const scrubbed = scrubSentryEvent({
      message: `failed for ${EMAIL} Bearer ${SECRET}`,
      user: { email: EMAIL, ip_address: "203.0.113.5" },
      request: {
        method: "POST",
        url: `https://admin.example.com/lookup?token=${SECRET}`,
        data: { email: EMAIL, amountMinor: AMOUNT },
        headers: { authorization: `Bearer ${SECRET}` },
        cookies: { session: SECRET },
        query_string: `token=${SECRET}`,
      },
      extra: {
        email: EMAIL,
        amountMinor: AMOUNT,
        userId: "11111111-1111-4111-8111-111111111111",
      },
      breadcrumbs: [
        {
          type: "http",
          data: {
            method: "GET",
            url: `https://admin.example.com/api?email=${EMAIL}`,
            status_code: 500,
            request_body_size: 12,
          },
        },
      ],
    });

    const serialized = JSON.stringify(scrubbed);
    assert.equal(serialized.includes(EMAIL), false);
    assert.equal(serialized.includes(SECRET), false);
    assert.equal(serialized.includes(String(AMOUNT)), false);
    assert.equal(serialized.includes("203.0.113.5"), false);
    assert.equal(scrubbed.user, undefined);
    assert.deepEqual(scrubbed.request, {
      method: "POST",
      url: "https://admin.example.com/lookup",
    });
    assert.equal(
      scrubbed.extra?.userId,
      "11111111-1111-4111-8111-111111111111",
    );
    assert.deepEqual(scrubbed.breadcrumbs?.[0]?.data, {
      method: "GET",
      status_code: 500,
      url: "https://admin.example.com/api",
    });
  });

  it("drops client HTTP statuses and redacts server messages", () => {
    assert.equal(
      sentryBeforeSend(
        { contexts: { response: { status_code: 404 } } },
        {},
      ),
      null,
    );
    assert.equal(
      sentryBeforeSend({ message: "missing" }, { originalException: { status: 400 } }),
      null,
    );
    const kept = sentryBeforeSend({ message: `down ${EMAIL}` }, { originalException: { status: 503 } });
    assert.equal(kept?.message, `down ${SENTRY_REDACT_CENSOR}`);
  });
});
