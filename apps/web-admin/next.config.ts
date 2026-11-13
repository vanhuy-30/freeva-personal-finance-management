import type { NextConfig } from "next";
import { withSentryConfig } from "@sentry/nextjs/config";

// SEC-P6-002: the admin pages take the staff credential and change live config,
// so they must never be framed by another site (clickjacking) or leak the URL.
const securityHeaders = [
  {
    key: "Content-Security-Policy",
    value: "frame-ancestors 'none'; base-uri 'self'; form-action 'self'; object-src 'none'",
  },
  { key: "X-Frame-Options", value: "DENY" },
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "Referrer-Policy", value: "no-referrer" },
  { key: "Strict-Transport-Security", value: "max-age=63072000; includeSubDomains" },
];

const nextConfig: NextConfig = {
  agentRules: false,
  async headers() {
    return [{ source: "/:path*", headers: securityHeaders }];
  },
};

export default withSentryConfig(nextConfig, {
  telemetry: false,
  silent: true,
  sourcemaps: {
    disable: true,
  },
  suppressOnRouterTransitionStartWarning: true,
});
