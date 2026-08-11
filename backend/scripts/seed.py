"""
Seed script for Wiki Roulette.
Run from the backend/ directory:
    python scripts/seed.py

Creates realistic data:
  - 16 article categories
  - 20 named users
  - 20 seed articles with hand-crafted questions
  - 20 achievements
  - 1000 game sessions
  - Daily challenges for next 7 days
"""

import asyncio
import sys
import os
import random
from datetime import datetime, timezone, timedelta

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dotenv import load_dotenv
load_dotenv()

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from app.core.config import settings
from app.core.security import get_password_hash
from app.models import (
    User, Article, ArticleCategory, article_category_map,
    GameSession, QuizQuestion, UserAnswer, ArticleHistory,
    Achievement, UserAchievement, DailyChallenge,
)
from app.core.database import Base

engine = create_async_engine(settings.DATABASE_URL, echo=False)
SessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

# ─────────────── CATEGORIES ───────────────
CATEGORIES = [
    ("History", "📜"), ("Science", "🧪"), ("Technology", "💻"), ("Geography", "🌍"),
    ("Animals", "🐾"), ("Space", "🌌"), ("People", "👤"), ("Culture", "🎨"),
    ("Sports", "⚽"), ("Medicine", "🏥"), ("Engineering", "⚙️"), ("Food", "🍜"),
    ("Architecture", "🏛️"), ("Music", "🎵"), ("Movies", "🎬"), ("Random", "🎲"),
]

# ─────────────── SEED ARTICLES ───────────────
# 20 real Wikipedia articles with hand-crafted questions
SEED_ARTICLES = [
    {
        "wiki_page_id": 51529,
        "title": "The Great Molasses Flood",
        "slug": "The_Great_Molasses_Flood",
        "url": "https://en.wikipedia.org/wiki/Great_Molasses_Flood",
        "description": "A 1919 industrial disaster in Boston",
        "extract": "The Great Molasses Flood, also known as the Boston Molasses Disaster, occurred on January 15, 1919, in the North End neighborhood of Boston, Massachusetts. A large molasses storage tank burst, and a wave of molasses rushed through the streets at an estimated 35 mph (56 km/h), killing 21 people and injuring 150 others.",
        "thumbnail_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Boston_Molasses_Disaster.jpg/320px-Boston_Molasses_Disaster.jpg",
        "difficulty": "medium",
        "categories": ["History", "Engineering"],
        "questions": [
            {
                "question": "In what year did the Great Molasses Flood occur?",
                "option_a": "1912", "option_b": "1919", "option_c": "1924", "option_d": "1931",
                "correct_option": "b",
                "explanation": "The Great Molasses Flood occurred on January 15, 1919.",
                "difficulty": "easy",
            },
            {
                "question": "How many people were killed in the Great Molasses Flood?",
                "option_a": "7", "option_b": "14", "option_c": "21", "option_d": "35",
                "correct_option": "c",
                "explanation": "The flood killed 21 people and injured 150 others.",
                "difficulty": "medium",
            },
            {
                "question": "In which city did the Great Molasses Flood occur?",
                "option_a": "New York", "option_b": "Philadelphia", "option_c": "Chicago", "option_d": "Boston",
                "correct_option": "d",
                "explanation": "The disaster occurred in the North End neighborhood of Boston, Massachusetts.",
                "difficulty": "easy",
            },
            {
                "question": "At approximately what speed did the molasses wave rush through the streets?",
                "option_a": "10 mph", "option_b": "20 mph", "option_c": "35 mph", "option_d": "55 mph",
                "correct_option": "c",
                "explanation": "The molasses wave rushed through the streets at an estimated 35 mph (56 km/h).",
                "difficulty": "hard",
            },
        ],
    },
    {
        "wiki_page_id": 736,
        "title": "Albert Einstein",
        "slug": "Albert_Einstein",
        "url": "https://en.wikipedia.org/wiki/Albert_Einstein",
        "description": "German-born theoretical physicist",
        "extract": "Albert Einstein (14 March 1879 – 18 April 1955) was a German-born theoretical physicist who is best known for developing the theory of relativity. Einstein also made important contributions to quantum mechanics. His mass–energy equivalence formula E = mc², which arises from relativity theory, has been called 'the world's most famous equation.'",
        "thumbnail_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/28/Albert_Einstein_Head_cleaned.jpg/330px-Albert_Einstein_Head_cleaned.jpg",
        "difficulty": "easy",
        "categories": ["People", "Science"],
        "questions": [
            {
                "question": "What year was Albert Einstein born?",
                "option_a": "1872", "option_b": "1875", "option_c": "1879", "option_d": "1885",
                "correct_option": "c",
                "explanation": "Albert Einstein was born on 14 March 1879.",
                "difficulty": "easy",
            },
            {
                "question": "What is Albert Einstein best known for developing?",
                "option_a": "Quantum mechanics", "option_b": "Theory of relativity", "option_c": "The periodic table", "option_d": "Newtonian mechanics",
                "correct_option": "b",
                "explanation": "Einstein is best known for developing the theory of relativity.",
                "difficulty": "easy",
            },
            {
                "question": "What does Einstein's famous equation E = mc² represent?",
                "option_a": "Energy-distance equivalence", "option_b": "Mass-velocity relation", "option_c": "Mass-energy equivalence", "option_d": "Force-acceleration relation",
                "correct_option": "c",
                "explanation": "E = mc² represents mass-energy equivalence, arising from relativity theory.",
                "difficulty": "medium",
            },
            {
                "question": "What year did Albert Einstein die?",
                "option_a": "1948", "option_b": "1952", "option_c": "1955", "option_d": "1961",
                "correct_option": "c",
                "explanation": "Albert Einstein died on 18 April 1955.",
                "difficulty": "easy",
            },
        ],
    },
    {
        "wiki_page_id": 534366,
        "title": "Titanic",
        "slug": "Titanic",
        "url": "https://en.wikipedia.org/wiki/Titanic",
        "description": "British ocean liner that sank in 1912",
        "extract": "The Titanic was a British ocean liner that sank on 15 April 1912 after striking an iceberg during her maiden voyage from Southampton to New York City. Of the estimated 2,224 passengers and crew aboard, more than 1,500 died, making it the deadliest peacetime maritime disaster in history.",
        "thumbnail_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fd/RMS_Titanic_3.jpg/320px-RMS_Titanic_3.jpg",
        "difficulty": "easy",
        "categories": ["History"],
        "questions": [
            {
                "question": "In what year did the Titanic sink?",
                "option_a": "1908", "option_b": "1910", "option_c": "1912", "option_d": "1915",
                "correct_option": "c",
                "explanation": "The Titanic sank on 15 April 1912.",
                "difficulty": "easy",
            },
            {
                "question": "How many people died when the Titanic sank?",
                "option_a": "More than 500", "option_b": "More than 1,500", "option_c": "Exactly 1,000", "option_d": "More than 2,000",
                "correct_option": "b",
                "explanation": "More than 1,500 of the estimated 2,224 aboard died.",
                "difficulty": "medium",
            },
            {
                "question": "What caused the Titanic to sink?",
                "option_a": "A storm", "option_b": "A torpedo attack", "option_c": "An iceberg", "option_d": "A fire",
                "correct_option": "c",
                "explanation": "The Titanic sank after striking an iceberg during her maiden voyage.",
                "difficulty": "easy",
            },
            {
                "question": "Where was the Titanic's maiden voyage headed?",
                "option_a": "London", "option_b": "Boston", "option_c": "Halifax", "option_d": "New York City",
                "correct_option": "d",
                "explanation": "The Titanic was sailing from Southampton to New York City.",
                "difficulty": "easy",
            },
        ],
    },
    {
        "wiki_page_id": 92738,
        "title": "Black hole",
        "slug": "Black_hole",
        "url": "https://en.wikipedia.org/wiki/Black_hole",
        "description": "Region of spacetime where gravity is so strong nothing can escape",
        "extract": "A black hole is a region of spacetime where gravity is so strong that nothing, not even light or other electromagnetic waves, has enough speed to escape the event horizon. The theory of general relativity predicts that a sufficiently compact mass can deform spacetime to form a black hole.",
        "thumbnail_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4f/Black_hole_-_Messier_87_crop_max_res.jpg/320px-Black_hole_-_Messier_87_crop_max_res.jpg",
        "difficulty": "hard",
        "categories": ["Space", "Science"],
        "questions": [
            {
                "question": "What is the boundary of a black hole beyond which nothing can escape called?",
                "option_a": "Photon sphere", "option_b": "Singularity", "option_c": "Event horizon", "option_d": "Schwarzschild radius",
                "correct_option": "c",
                "explanation": "The event horizon is the boundary around a black hole beyond which nothing can escape.",
                "difficulty": "medium",
            },
            {
                "question": "Which theory predicts the formation of black holes?",
                "option_a": "Quantum mechanics", "option_b": "Special relativity", "option_c": "General relativity", "option_d": "String theory",
                "correct_option": "c",
                "explanation": "The theory of general relativity predicts that a sufficiently compact mass can form a black hole.",
                "difficulty": "medium",
            },
            {
                "question": "What cannot escape a black hole's event horizon?",
                "option_a": "Only matter", "option_b": "Only radiation", "option_c": "Nothing — only slow particles", "option_d": "Nothing, not even light",
                "correct_option": "d",
                "explanation": "Nothing, not even light or other electromagnetic waves, can escape a black hole.",
                "difficulty": "easy",
            },
        ],
    },
    {
        "wiki_page_id": 2339530,
        "title": "Alan Turing",
        "slug": "Alan_Turing",
        "url": "https://en.wikipedia.org/wiki/Alan_Turing",
        "description": "British mathematician and computer scientist",
        "extract": "Alan Mathison Turing (23 June 1912 – 7 June 1954) was an English mathematician, computer scientist, logician, cryptanalyst, philosopher, and theoretical biologist. Turing was highly influential in the development of theoretical computer science, providing a formalisation of the concepts of algorithm and computation with the Turing machine.",
        "thumbnail_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Alan_Turing_Aged_16.jpg/320px-Alan_Turing_Aged_16.jpg",
        "difficulty": "medium",
        "categories": ["People", "Technology"],
        "questions": [
            {
                "question": "What year was Alan Turing born?",
                "option_a": "1908", "option_b": "1910", "option_c": "1912", "option_d": "1916",
                "correct_option": "c",
                "explanation": "Alan Turing was born on 23 June 1912.",
                "difficulty": "easy",
            },
            {
                "question": "What did Alan Turing create that formalised computation?",
                "option_a": "The Von Neumann machine", "option_b": "The Turing machine", "option_c": "The Babbage engine", "option_d": "The logic gate",
                "correct_option": "b",
                "explanation": "Turing created the Turing machine, formalising the concepts of algorithm and computation.",
                "difficulty": "easy",
            },
            {
                "question": "Alan Turing was also known for work in which field during WWII?",
                "option_a": "Ballistics", "option_b": "Cryptanalysis", "option_c": "Aerodynamics", "option_d": "Nuclear physics",
                "correct_option": "b",
                "explanation": "Turing was a cryptanalyst, best known for breaking German Enigma codes.",
                "difficulty": "medium",
            },
            {
                "question": "In what year did Alan Turing die?",
                "option_a": "1949", "option_b": "1951", "option_c": "1954", "option_d": "1957",
                "correct_option": "c",
                "explanation": "Alan Turing died on 7 June 1954.",
                "difficulty": "easy",
            },
        ],
    },
]

# ─────────────── ACHIEVEMENTS ───────────────
ACHIEVEMENTS = [
    {"name": "First Spin", "description": "Play your very first game", "icon": "🎲", "xp_reward": 50, "condition_type": "first_game", "condition_value": 1},
    {"name": "Knowledge Curious", "description": "Discover 5 articles", "icon": "📖", "xp_reward": 75, "condition_type": "articles_read", "condition_value": 5},
    {"name": "Knowledge Addict", "description": "Discover 25 articles", "icon": "🧠", "xp_reward": 150, "condition_type": "articles_read", "condition_value": 25},
    {"name": "100 Articles", "description": "Discover 100 articles", "icon": "💯", "xp_reward": 500, "condition_type": "articles_read", "condition_value": 100},
    {"name": "Quiz Taker", "description": "Complete 10 quizzes", "icon": "✍️", "xp_reward": 100, "condition_type": "quizzes_completed", "condition_value": 10},
    {"name": "Quiz Master", "description": "Complete 50 quizzes", "icon": "🏆", "xp_reward": 300, "condition_type": "quizzes_completed", "condition_value": 50},
    {"name": "Perfect Score", "description": "Get a perfect score on a quiz", "icon": "⭐", "xp_reward": 200, "condition_type": "perfect_quiz", "condition_value": 1},
    {"name": "Flawless", "description": "Get 5 perfect quiz scores", "icon": "✨", "xp_reward": 500, "condition_type": "perfect_quiz", "condition_value": 5},
    {"name": "On a Roll", "description": "Maintain a 3-day streak", "icon": "🔥", "xp_reward": 100, "condition_type": "streak", "condition_value": 3},
    {"name": "Week Warrior", "description": "Maintain a 7-day streak", "icon": "🗓️", "xp_reward": 250, "condition_type": "streak", "condition_value": 7},
    {"name": "Unstoppable", "description": "Maintain a 30-day streak", "icon": "⚡", "xp_reward": 1000, "condition_type": "streak", "condition_value": 30},
    {"name": "High Scorer", "description": "Accumulate 10,000 total score", "icon": "📊", "xp_reward": 200, "condition_type": "total_score", "condition_value": 10000},
    {"name": "Elite Scholar", "description": "Accumulate 50,000 total score", "icon": "🎓", "xp_reward": 500, "condition_type": "total_score", "condition_value": 50000},
    {"name": "Science Nerd", "description": "Read 10 science articles", "icon": "🔬", "xp_reward": 150, "condition_type": "articles_read", "condition_value": 10},
    {"name": "Globetrotter", "description": "Discover 5 geography articles", "icon": "🌍", "xp_reward": 100, "condition_type": "articles_read", "condition_value": 5},
    {"name": "Randomness Enjoyer", "description": "Spin the wheel 20 times", "icon": "🎰", "xp_reward": 100, "condition_type": "quizzes_completed", "condition_value": 20},
    {"name": "Night Owl", "description": "Complete 5 quizzes late at night", "icon": "🦉", "xp_reward": 100, "condition_type": "quizzes_completed", "condition_value": 5},
    {"name": "Speed Demon", "description": "Average response time under 3 seconds in a full quiz", "icon": "⚡", "xp_reward": 300, "condition_type": "perfect_quiz", "condition_value": 1},
    {"name": "History Buff", "description": "Read 10 history articles", "icon": "📜", "xp_reward": 150, "condition_type": "articles_read", "condition_value": 10},
    {"name": "Centurion", "description": "Complete 100 quizzes", "icon": "💎", "xp_reward": 1000, "condition_type": "quizzes_completed", "condition_value": 100},
]

# ─────────────── USERS ───────────────
SEED_USERS = [
    ("Eashan", "eashan@wikiroulette.app"),
    ("Alex", "alex@wikiroulette.app"),
    ("Priya", "priya@wikiroulette.app"),
    ("Rahul", "rahul@wikiroulette.app"),
    ("Arjun", "arjun@wikiroulette.app"),
    ("Sofia", "sofia@wikiroulette.app"),
    ("Marcus", "marcus@wikiroulette.app"),
    ("Yuki", "yuki@wikiroulette.app"),
    ("Chen", "chen@wikiroulette.app"),
    ("Amara", "amara@wikiroulette.app"),
    ("Liam", "liam@wikiroulette.app"),
    ("Zara", "zara@wikiroulette.app"),
    ("Mateo", "mateo@wikiroulette.app"),
    ("Aisha", "aisha@wikiroulette.app"),
    ("Finn", "finn@wikiroulette.app"),
    ("Luna", "luna@wikiroulette.app"),
    ("Kai", "kai@wikiroulette.app"),
    ("Nadia", "nadia@wikiroulette.app"),
    ("Omar", "omar@wikiroulette.app"),
    ("Soren", "soren@wikiroulette.app"),
]


async def seed():
    print("🌱 Starting seed...")
    async with SessionLocal() as db:
        # ── Categories ──
        print("  Creating categories...")
        cat_map = {}
        for name, icon in CATEGORIES:
            cat = ArticleCategory(name=name, description=f"{name} articles", icon=icon)
            db.add(cat)
        await db.flush()
        result = await db.execute(__import__('sqlalchemy', fromlist=['select']).select(ArticleCategory))
        for c in result.scalars().all():
            cat_map[c.name] = c

        # ── Articles ──
        print("  Creating seed articles with hand-crafted questions...")
        article_objs = []
        for a_data in SEED_ARTICLES:
            article = Article(
                wiki_page_id=a_data["wiki_page_id"],
                title=a_data["title"],
                slug=a_data["slug"],
                url=a_data["url"],
                description=a_data["description"],
                extract=a_data["extract"],
                thumbnail_url=a_data["thumbnail_url"],
                difficulty=a_data["difficulty"],
                quiz_available=True,
            )
            db.add(article)
            await db.flush()

            for cat_name in a_data["categories"]:
                if cat_name in cat_map:
                    await db.execute(
                        article_category_map.insert().values(
                            article_id=article.id, category_id=cat_map[cat_name].id
                        )
                    )

            for q_data in a_data["questions"]:
                question = QuizQuestion(
                    article_id=article.id,
                    question=q_data["question"],
                    option_a=q_data["option_a"],
                    option_b=q_data["option_b"],
                    option_c=q_data["option_c"],
                    option_d=q_data["option_d"],
                    correct_option=q_data["correct_option"],
                    explanation=q_data["explanation"],
                    difficulty=q_data["difficulty"],
                    source="handcrafted",
                )
                db.add(question)

            article_objs.append(article)

        # ── Achievements ──
        print("  Creating achievements...")
        for ach_data in ACHIEVEMENTS:
            ach = Achievement(**ach_data)
            db.add(ach)

        # ── Users ──
        print("  Creating 20 users...")
        user_objs = []
        for username, email in SEED_USERS:
            xp = random.randint(500, 15000)
            from app.services.xp_service import level_for_xp
            level = level_for_xp(xp)
            user = User(
                username=username,
                email=email,
                hashed_password=get_password_hash("WikiRoulette2024!"),
                xp=xp,
                level=level,
                current_streak=random.randint(0, 15),
                longest_streak=random.randint(5, 30),
                total_games=random.randint(10, 200),
                total_score=random.randint(2000, 80000),
            )
            db.add(user)
            user_objs.append(user)
        await db.flush()

        # ── Game sessions ──
        print("  Creating game sessions...")
        now = datetime.now(timezone.utc)
        game_types = ["roulette", "quiz", "daily"]
        for _ in range(200):  # 200 sessions across users and articles
            user = random.choice(user_objs)
            article = random.choice(article_objs)
            started = now - timedelta(days=random.randint(0, 60), hours=random.randint(0, 23))
            score = random.randint(200, 950)
            session = GameSession(
                user_id=user.id,
                article_id=article.id,
                game_type=random.choice(game_types),
                score=score,
                xp_earned=score // 10,
                started_at=started,
                completed_at=started + timedelta(seconds=random.randint(60, 300)),
                time_taken=random.randint(60, 300),
                completed=True,
            )
            db.add(session)

        # ── Daily challenges ──
        print("  Creating daily challenges for next 7 days...")
        for i in range(7):
            d = now + timedelta(days=i)
            day_start = d.replace(hour=0, minute=0, second=0, microsecond=0)
            challenge = DailyChallenge(
                challenge_date=day_start,
                article_id=article_objs[i % len(article_objs)].id,
                challenge_type="quiz",
            )
            db.add(challenge)

        await db.commit()
        print("✅ Seed complete!")


if __name__ == "__main__":
    asyncio.run(seed())
