import type { NextConfig } from "next";
import { withSentryConfig } from "@sentry/nextjs/config";

const nextConfig: NextConfig = {
  agentRules: false,
};

export default withSentryConfig(nextConfig, {
  telemetry: false,
  silent: true,
  sourcemaps: {
    disable: true,
  },
  suppressOnRouterTransitionStartWarning: true,
});
