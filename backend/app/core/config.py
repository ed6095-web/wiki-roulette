from pydantic_settings import BaseSettings
from typing import List
import json


class Settings(BaseSettings):
    DATABASE_URL: str
    DATABASE_URL_SYNC: str = ""
    JWT_SECRET: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 43200  # 30 days

    WIKIPEDIA_USER_AGENT: str = "WikiRoulette/1.0"
    WIKIPEDIA_BASE_URL: str = "https://en.wikipedia.org"
    MEDIAWIKI_API_URL: str = "https://en.wikipedia.org/w/api.php"
    WIKIPEDIA_REST_URL: str = "https://en.wikipedia.org/api/rest_v1"

    ENVIRONMENT: str = "development"
    CORS_ORIGINS: str = '["http://localhost:3000"]'

    # XP / level config
    XP_BASE: int = 300
    XP_LEVEL_EXPONENT: float = 1.5

    # Quiz config
    QUIZ_MIN_QUESTIONS: int = 3
    QUIZ_MAX_QUESTIONS: int = 5

    # Scoring
    BASE_SCORE_CORRECT: int = 100
    SPEED_BONUS_3S: int = 50
    SPEED_BONUS_5S: int = 30
    SPEED_BONUS_10S: int = 10
    PERFECT_QUIZ_BONUS: int = 200
    DAILY_MULTIPLIER: float = 1.5

    @property
    def cors_origins_list(self) -> List[str]:
        return json.loads(self.CORS_ORIGINS)

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
