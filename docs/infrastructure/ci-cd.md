# CI/CD

GitHub Actions [ci.yml](../../.github/workflows/ci.yml):

- `web-admin`: lint + build
- `api`: test + build
- `mobile`: `flutter pub get` + analyze + test

CD staging/prod chưa có — `INF-P0` còn lại / `INF-P1`.

Release app store: quy trình [../process/release.md](../process/release.md).
