import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { apiBase } from "./api_base.ts";

describe("apiBase", () => {
  it("defaults to the local API outside production", () => {
    assert.equal(apiBase({ NODE_ENV: "development" }), "http://localhost:4000");
  });

  it("refuses a missing URL in production", () => {
    assert.throws(() => apiBase({ NODE_ENV: "production" }), /not set/);
  });

  it("refuses plain http to a remote host in production", () => {
    assert.throws(
      () => apiBase({ NODE_ENV: "production", NEXT_PUBLIC_API_BASE_URL: "http://api.example.test" }),
      /https/,
    );
  });

  it("accepts https and local http, without a trailing slash", () => {
    assert.equal(
      apiBase({ NODE_ENV: "production", NEXT_PUBLIC_API_BASE_URL: "https://api.example.test/" }),
      "https://api.example.test",
    );
    assert.equal(
      apiBase({ NODE_ENV: "production", NEXT_PUBLIC_API_BASE_URL: "http://localhost:4000" }),
      "http://localhost:4000",
    );
  });
});
