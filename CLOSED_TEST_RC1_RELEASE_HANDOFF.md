# FBS — Closed Test RC1 release handoff

Date: 2026-09-26. This is a release-only preparation, not M102 and not a new gameplay milestone.

## Verified source

- Baseline docs-only main: `4cc5f9e4550eb64fc7178b756995fc24abe35c10`.
- Unchanged executable product baseline: `76c785296aa70b754d90a28c130930293a7d3e1d`.
- Android applicationId: `com.zmilastudio.futbol_baskanlik_app`.
- First candidate version: `0.1.0+1` (versionCode 1).
- Existing Flutter debug APK/emulator CI is separate. Its success is not Play AAB/signing proof.
- No core, app/lib, app/test or persistence/schema changes are authorized by this release preparation.

## Owner-controlled prerequisites

1. Confirm that the Play Console application being prepared has **exactly** the application ID above and that versionCode 1 is unused. If either does not match, stop. Do not silently rename the package or bump the version.
2. Create/store a private Android **upload key** outside the repository; back up the keystore and passwords securely. Do not commit any keystore, key.properties, secret or password.
3. Configure these four GitHub Actions repository secrets (values must not be printed to logs):
   - `FBS_ANDROID_KEYSTORE_BASE64`: base64 of the upload keystore binary.
   - `FBS_ANDROID_KEYSTORE_PASSWORD`: keystore password.
   - `FBS_ANDROID_KEY_ALIAS`: alias.
   - `FBS_ANDROID_KEY_PASSWORD`: key password.
4. The draft PR must be reviewed; **merge requires explicit owner approval on its exact final HEAD**. No automatic merge.
5. After merge, manually dispatch `FBS Closed Test RC1 AAB` on the approved release source with confirmation `FBS_CLOSED_TEST_RC1`. The workflow fails closed when signing material is absent and cannot use the debug key.

## Validate before Play upload

- Check the workflow's exact source SHA and successful test/AAB/signature steps. Do not use an old run from a different SHA.
- Download `FBS-0.1.0-1-closed-test-rc1` artifact. Use the `.aab` file inside, **not the artifact ZIP**.
- Compare the AAB's SHA-256 with `reports/AAB_SHA256.txt`; retain `reports/UPLOAD_CERTIFICATE.txt` for upload-certificate comparison.
- Check versionCode, package identity, target SDK and Play Console app compatibility before submitting.
- Release/rollout, test track configuration, eligibility questions, country/tester list, store listing and Play declarations remain owner/Play Console actions. The GitHub workflow does **not** publish to Play or enroll testers.

## Stop conditions

- Source diverges in `lib/`, `test/`, `tool/`, `app/lib/` or `app/test/`.
- Store's package ID or existing versionCode differs from the proposed identity.
- Keystore/signature missing or mismatch, unsigned artifact, CI failure, or Play Console rejection.
- Any request to alter M65 or existing save authority, business logic, M102 scope, or repo protection settings.

No Play upload, rollout, merge, or 14-day testing clock is claimed until separately verified.
