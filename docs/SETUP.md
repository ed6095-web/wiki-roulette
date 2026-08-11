# Wiki Roulette — Setup & Deployment Guide

## Prerequisites

- **Python**: 3.10+ (FastAPI backend)
- **Flutter SDK**: 3.19+ with Dart 3.3+
- **Supabase Account**: A free Supabase PostgreSQL instance

---

## 1. Supabase PostgreSQL Configuration

1. In the Supabase Dashboard, create a new project.
2. Under **Project Settings > Database**, obtain the **Connection Pooling** URL (Transaction mode on port 6543) and **Direct Connection** URL (port 5432).
3. Create `backend/.env` from `.env.example`:
   ```bash
   cp backend/.env.example backend/.env
   ```
4. Set the following variables in `backend/.env`:
   ```env
   # Async connection for FastAPI runtime (using connection pooler)
   DATABASE_URL=postgresql+asyncpg://postgres.[REF]:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres

   # Sync connection for Alembic migrations (direct connection)
   DATABASE_URL_SYNC=postgresql+psycopg2://postgres.[REF]:[PASSWORD]@aws-0-[REGION].db.supabase.com:5432/postgres

   JWT_SECRET=your-secure-random-jwt-secret
   ENVIRONMENT=development
   ```

---

## 2. Backend Installation & Migration

```bash
cd backend

# Create and activate a virtual environment
python -m venv venv
# On Windows:
.\venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Apply schema migrations to Supabase
alembic upgrade head

# Seed initial categories, users, achievements, and hand-crafted questions
python scripts/seed.py

# Start FastAPI server
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

---

## 3. Frontend Mobile App Setup

```bash
cd frontend

# Fetch packages
flutter pub get

# Run test suite
flutter test

# Run app on connected device or simulator
flutter run
```

> **Note for Android Emulator**: The app default base URL `http://10.0.2.2:8000` is mapped to your host machine's `localhost:8000`. For iOS simulator or web, configure `AppConstants.apiBaseUrl` in `lib/core/constants/app_text_styles.dart`.
