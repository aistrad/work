Testing VibeLife (API-only minimal)

Overview
- API tests run without Postgres by setting `VIBELIFE_ENV=test`.
- DB access is stubbed in `apps/api/stores/db.py` (in-memory dummy pool).
- Heavy routers are skipped in test mode; minimal routers: `account`, `notifications`.

Quick start
- Create venv and install minimal deps:
  - `python3 -m venv .venv && source .venv/bin/activate`
  - `pip install -r apps/api/requirements.txt` (or install the subset used in CI)
- Run a subset of tests:
  - `VIBELIFE_ENV=test VIBELIFE_JWT_SECRET=testsecret pytest -q apps/api/tests/integration/routes/test_account.py`

Notes
- If you need full DB tests, unset `VIBELIFE_ENV` and ensure Postgres is available.
- Knowledge builder, chat, skills routes are excluded in TEST mode to keep deps light.
