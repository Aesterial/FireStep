/* eslint-disable import/no-extraneous-dependencies */
// eslint-disable-next-line @typescript-eslint/no-var-requires
const withBundleAnalyzer = require('@next/bundle-analyzer')({
  enabled: process.env.ANALYZE === 'true',
});

module.exports = withBundleAnalyzer({
  poweredByHeader: false,
  trailingSlash: true,
  basePath: '',
  output: process.env.BUILD_STATIC === 'true' ? 'export' : undefined,
  allowedDevOrigins:
    process.env.NODE_ENV === 'development' ? ['127.0.0.1'] : undefined,
  // The project loads assets from `public` using the same base path semantics
  // as application routes, so the code remains basePath-ready if needed later.
  reactStrictMode: true,
});
