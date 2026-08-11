# 🎲 Wiki Roulette

> **"You don't choose what you learn. The internet does."**

Wiki Roulette is a mobile application and gamified Wikipedia exploration platform that turns random discovery into knowledge games, quizzes, streak tracking, and global leaderboard competition.

---

## ✨ Features

- 🎰 **Cinematic Roulette Discovery**: Interactive spin animation cycling across topics before revealing genuinely random Wikipedia articles.
- 🧠 **Three-Tier Quiz Engine**:
  - **Tier 1 (Seeded)**: Curated, hand-crafted questions for core articles.
  - **Tier 2 (Cached)**: High-speed retrieval of previously verified questions.
  - **Tier 3 (Deterministic Fact Extraction)**: Unambiguous algorithmic generation (years, quantities, subjects) with zero hallucinations. Never invents facts.
- ⚡ **Dynamic Scoring & XP**: Base score, sub-3s/5s/10s speed bonuses, perfect game bonuses, and 1.5× daily multipliers.
- 🏆 **Global Leaderboards**: Real-time rank calculation across daily, weekly, monthly, and all-time timeframes.
- 🎯 **Daily Challenges**: Hand-picked daily articles with dedicated bonus multipliers.
- 🔥 **Streak & Progression**: Daily streak tracking and milestone achievements.
- 🎨 **Design System**: Dark glassmorphism, fluid micro-interactions, responsive typography, and glowing radial ambient backgrounds.

---

## 🏗 Architecture

```
wiki-roulette/
├── backend/                  # FastAPI + SQLAlchemy + Alembic
│   ├── app/
│   │   ├── core/             # Database, config, security, auth deps
│   │   ├── models/           # SQLAlchemy ORM models (PostgreSQL)
│   │   ├── schemas/          # Pydantic validation & response models
│   │   ├── services/         # Wikipedia API, 3-tier quiz, XP, achievements
│   │   ├── routers/          # Auth, Articles, Games, Profile, Leaderboard, Daily
│   │   └── main.py           # FastAPI entrypoint & middleware
│   ├── alembic/              # Database migrations (Supabase target)
│   ├── scripts/              # Seed script (20 users, 200 sessions, 20 achievements)
│   └── tests/                # Pytest unit & integration test suites
│
├── frontend/                 # Flutter Mobile App (iOS / Android)
│   ├── lib/
│   │   ├── core/             # Theme, router, network client, glassmorphism widgets
│   │   ├── data/             # Models, repository patterns
│   │   └── features/         # Auth, Home, Article, Quiz, Leaderboard, Profile, Discover
│   └── test/                 # Flutter unit & widget tests
│
└── docker-compose.yml        # Container orchestration for FastAPI
```

---

## 🚀 Quick Start

### 1. Backend Setup
```bash
cd backend
cp .env.example .env
# Edit .env with your Supabase PostgreSQL connection strings

# Install dependencies
pip install -r requirements.txt

# Run migrations against Supabase
alembic upgrade head

# Seed initial data
python scripts/seed.py

# Start FastAPI dev server
uvicorn app.main:app --reload --port 8000
```

### 2. Frontend Setup
```bash
cd frontend

# Install Flutter dependencies
flutter pub get

# Run unit and widget tests
flutter test

# Launch mobile application
flutter run
```

---

## 🛡 Tech Stack

- **Backend**: FastAPI, SQLAlchemy 2.0 (async), Pydantic v2, Alembic, HTTPX, SlowAPI, Passlib (bcrypt), PyJWT.
- **Database**: Supabase PostgreSQL (Connection Pooling + Direct Migration URL).
- **Mobile Frontend**: Flutter 3.x, Dart 3.x, Flutter Riverpod, GoRouter, Dio, Google Fonts (Poppins), Flutter Animate, CachedNetworkImage.
