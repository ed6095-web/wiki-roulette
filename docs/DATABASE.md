# Wiki Roulette — Database Schema (Supabase PostgreSQL)

## Entity Relationship Overview

The database uses PostgreSQL hosted on Supabase.

```
+------------------+         +-----------------------+
|      users       |         |   article_categories  |
+------------------+         +-----------------------+
| id (PK)          |         | id (PK)               |
| username (UQ)    |         | name (UQ)             |
| email (UQ)       |         | description           |
| hashed_password  |         | icon                  |
| avatar_url       |         +-----------------------+
| xp               |                     |
| level            |                     | (Many-to-Many)
| total_games      |                     v
| total_score      |         +-----------------------+
| current_streak   |         | article_category_map  |
| longest_streak   |         +-----------------------+
| last_played_at   |                     |
| created_at       |                     v
+------------------+         +-----------------------+
        |                    |       articles        |
        |                    +-----------------------+
        |                    | id (PK)               |
        |                    | wiki_page_id (UQ)     |
        |                    | title                 |
        |                    | slug                  |
        |                    | url                   |
        |                    | description           |
        |                    | extract               |
        |                    | thumbnail_url         |
        |                    | difficulty            |
        |                    | quiz_available        |
        |                    | cached_at             |
        |                    +-----------------------+
        |                                |
        +---------------+                |
        |               |                |
        v               v                v
+----------------+  +----------------+  +-----------------+
| game_sessions  |  | article_history|  | quiz_questions  |
+----------------+  +----------------+  +-----------------+
| id (PK)        |  | id (PK)        |  | id (PK)         |
| user_id (FK)   |  | user_id (FK)   |  | article_id (FK) |
| article_id(FK) |  | article_id (FK)|  | question        |
| game_type      |  | source         |  | option_a..d     |
| score          |  | completed      |  | correct_option  |
| xp_earned      |  | visited_at     |  | explanation     |
| started_at     |  +----------------+  | difficulty      |
| completed      |                      | source          |
+----------------+                      +-----------------+
        |                                       |
        +-------------------+-------------------+
                            |
                            v
                    +----------------+
                    |  user_answers  |
                    +----------------+
                    | id (PK)        |
                    | user_id (FK)   |
                    | session_id(FK) |
                    | question_id(FK)|
                    | selected_opt   |
                    | correct        |
                    | resp_time_ms   |
                    +----------------+
```

---

## Tables Reference

### 1. `users`
Tracks user credentials, game experience points (XP), derived level, streaks, and cumulative stats.

### 2. `articles`
Caches fetched Wikipedia articles along with their extracted summary, thumbnail URL, and computed difficulty.

### 3. `quiz_questions`
Stores verified questions (handcrafted or deterministically generated) associated with an article. `correct_option` is hidden from unauthenticated responses.

### 4. `game_sessions` & `user_answers`
Maintains individual session runs, per-question responses, response latencies (in milliseconds for speed bonuses), and completion timestamps.

### 5. `achievements` & `user_achievements`
Gamification milestones with XP rewards, condition thresholds (e.g. `articles_read`, `perfect_quiz`, `streak`), and unlocked dates.
