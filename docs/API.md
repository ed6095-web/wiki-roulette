# Wiki Roulette — REST API Specification

Base URL: `http://localhost:8000` (or `http://10.0.2.2:8000` on Android Emulator)

---

## 1. Authentication

### `POST /auth/register`
Creates a new player account.
- **Request Body**:
  ```json
  {
    "username": "scholar42",
    "email": "scholar42@example.com",
    "password": "StrongPassword123!"
  }
  ```
- **Response** `201 Created`:
  ```json
  {
    "access_token": "eyJhbGciOi...",
    "token_type": "bearer",
    "user_id": 1,
    "username": "scholar42"
  }
  ```

### `POST /auth/login`
Authenticates existing player with email and password.
- **Response** `200 OK`:
  ```json
  {
    "access_token": "eyJhbGciOi...",
    "token_type": "bearer",
    "user_id": 1,
    "username": "scholar42"
  }
  ```

### `GET /auth/me`
Retrieves currently authenticated user profile and stats. (Requires `Authorization: Bearer <token>`)

---

## 2. Articles

### `GET /articles/random`
Discovers a random Wikipedia article filtered to main namespace (`rnnamespace=0`) and ensures question readiness.
- **Response** `200 OK`:
  ```json
  {
    "id": 4,
    "wiki_page_id": 51529,
    "title": "The Great Molasses Flood",
    "slug": "The_Great_Molasses_Flood",
    "url": "https://en.wikipedia.org/wiki/Great_Molasses_Flood",
    "description": "A 1919 industrial disaster in Boston",
    "extract": "The Great Molasses Flood occurred on January 15, 1919...",
    "thumbnail_url": "https://upload.wikimedia.org/...",
    "difficulty": "medium",
    "quiz_available": true,
    "categories": [{"id": 1, "name": "History", "icon": "📜"}]
  }
  ```

### `GET /articles/search?q={query}`
Searches Wikipedia articles via OpenSearch.

---

## 3. Game & Quiz Engine

### `POST /games/start`
Initializes a new game session and returns selected questions (answers masked).
- **Request Body**:
  ```json
  {
    "article_id": 4,
    "game_type": "roulette",
    "is_daily": false
  }
  ```
- **Response** `200 OK`:
  ```json
  {
    "session_id": 102,
    "article_id": 4,
    "game_type": "roulette",
    "questions": [
      {
        "id": 12,
        "question": "In what year did the Great Molasses Flood occur?",
        "option_a": "1912",
        "option_b": "1919",
        "option_c": "1924",
        "option_d": "1931",
        "difficulty": "easy"
      }
    ],
    "started_at": "2026-08-11T18:00:00Z"
  }
  ```

### `POST /games/{session_id}/answer`
Submits an answer for a specific question within an active session.
- **Request Body**:
  ```json
  {
    "question_id": 12,
    "selected_option": "b",
    "response_time_ms": 2400
  }
  ```
- **Response** `200 OK`:
  ```json
  {
    "correct": true,
    "correct_option": "b",
    "explanation": "The Great Molasses Flood occurred on January 15, 1919.",
    "score_delta": 150,
    "xp_delta": 15
  }
  ```

### `POST /games/{session_id}/complete`
Concludes a game session, awards final XP, updates streaks, computes level progression, and unlocks eligible achievements.
- **Response** `200 OK`:
  ```json
  {
    "session_id": 102,
    "score_breakdown": {
      "correct_answers": 4,
      "total_questions": 4,
      "base_score": 400,
      "speed_bonus": 120,
      "perfect_bonus": 200,
      "daily_multiplier": 1.0,
      "final_score": 720,
      "xp_earned": 72,
      "level_before": 1,
      "level_after": 2,
      "leveled_up": true,
      "new_achievements": ["Perfect Score"]
    },
    "new_streak": 3
  }
  ```

---

## 4. Leaderboard & Profile

### `GET /leaderboard?period={daily|weekly|monthly|alltime}`
Returns aggregated top players for the requested period, along with the requesting user's live rank.

### `GET /profile/stats`
Returns total articles discovered, quizzes completed, perfect quizzes count, average response time, and accuracy.

### `GET /profile/achievements`
Returns the full achievement catalogue with unlock status and timestamps.
