"""
XP and leveling service.

Level formula: XP required for level N = BASE * (N ^ EXPONENT)
BASE = 300, EXPONENT = 1.5
"""

import math
from app.core.config import settings


def xp_for_level(level: int) -> int:
    """Total XP required to reach this level (cumulative)."""
    if level <= 1:
        return 0
    return int(settings.XP_BASE * (level ** settings.XP_LEVEL_EXPONENT))


def level_for_xp(total_xp: int) -> int:
    """Compute level from total XP."""
    level = 1
    while xp_for_level(level + 1) <= total_xp:
        level += 1
    return level


def xp_progress(total_xp: int) -> dict:
    """Returns current level, XP within level, XP needed for next level."""
    current_level = level_for_xp(total_xp)
    current_level_xp = xp_for_level(current_level)
    next_level_xp = xp_for_level(current_level + 1)
    return {
        "level": current_level,
        "current_xp": total_xp,
        "level_start_xp": current_level_xp,
        "next_level_xp": next_level_xp,
        "xp_in_level": total_xp - current_level_xp,
        "xp_needed": next_level_xp - total_xp,
        "progress_pct": (total_xp - current_level_xp) / (next_level_xp - current_level_xp)
            if next_level_xp > current_level_xp else 1.0,
    }


def calculate_score(
    correct_answers: int,
    total_questions: int,
    response_times_ms: list[int],
    is_daily: bool = False,
) -> dict:
    """
    Calculates final score and XP from a completed quiz session.

    Scoring:
      - Correct answer: +100
      - Speed bonus: < 3s = +50, < 5s = +30, < 10s = +10
      - Perfect quiz bonus: +200
      - Daily multiplier: 1.5x on final score
    """
    base_score = correct_answers * settings.BASE_SCORE_CORRECT
    speed_bonus = 0

    for t in response_times_ms:
        if t < 3000:
            speed_bonus += settings.SPEED_BONUS_3S
        elif t < 5000:
            speed_bonus += settings.SPEED_BONUS_5S
        elif t < 10000:
            speed_bonus += settings.SPEED_BONUS_10S

    perfect_bonus = settings.PERFECT_QUIZ_BONUS if correct_answers == total_questions else 0
    subtotal = base_score + speed_bonus + perfect_bonus

    multiplier = settings.DAILY_MULTIPLIER if is_daily else 1.0
    final_score = int(subtotal * multiplier)

    # XP = 10% of score, minimum 10 per correct answer
    xp_earned = max(correct_answers * 10, final_score // 10)

    return {
        "correct_answers": correct_answers,
        "total_questions": total_questions,
        "base_score": base_score,
        "speed_bonus": speed_bonus,
        "perfect_bonus": perfect_bonus,
        "daily_multiplier": multiplier,
        "final_score": final_score,
        "xp_earned": xp_earned,
    }
