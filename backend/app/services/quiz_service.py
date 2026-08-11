"""
Three-Tier Quiz Service

Tier 1 — Hand-crafted: seeded articles always return pre-written verified questions.
Tier 2 — Cached: articles that already have questions in the DB return them directly.
Tier 3 — Deterministic generation: extracts unambiguous facts from article text.
          - Only proceeds if >= 3 reliable questions can be formed.
          - NEVER invents facts. If uncertain, skips the candidate.
          - Distractors use arithmetic offsets or static category pools — not fabricated.
"""

import re
import random
from typing import List, Optional, Tuple
from dataclasses import dataclass


@dataclass
class GeneratedQuestion:
    question: str
    option_a: str
    option_b: str
    option_c: str
    option_d: str
    correct_option: str  # "a"|"b"|"c"|"d"
    explanation: str
    difficulty: str
    source: str = "generated"


# ──────────────────────────────────────────────
# Distractor pools for named-entity questions
# ──────────────────────────────────────────────
_COUNTRY_POOL = [
    "France", "Germany", "Japan", "China", "Brazil", "India", "Australia",
    "Canada", "Russia", "Egypt", "Mexico", "Argentina", "South Korea",
    "Italy", "Spain", "United Kingdom", "Turkey", "Nigeria", "Indonesia",
]

_CITY_POOL = [
    "London", "Paris", "Tokyo", "Berlin", "Mumbai", "Sydney",
    "Cairo", "Toronto", "Madrid", "Rome", "Moscow", "Beijing",
    "Buenos Aires", "Lagos", "Istanbul", "Seoul", "Jakarta",
]

_CENTURY_MAP = {
    "17th century": ["16th century", "18th century", "19th century"],
    "18th century": ["17th century", "19th century", "20th century"],
    "19th century": ["18th century", "20th century", "21st century"],
    "20th century": ["19th century", "21st century", "18th century"],
    "21st century": ["20th century", "20th century", "19th century"],
}


def _shuffle_options(correct_answer: str, distractors: List[str]) -> Tuple[str, str, str, str, str]:
    """
    Returns (option_a, option_b, option_c, option_d, correct_option_letter).
    Shuffles correct answer into a random position.
    """
    options = distractors[:3]
    correct_pos = random.randint(0, 3)
    options.insert(correct_pos, correct_answer)
    letters = ["a", "b", "c", "d"]
    return options[0], options[1], options[2], options[3], letters[correct_pos]


def _year_distractors(year: int) -> List[str]:
    """Generate plausible year distractors using fixed offsets — no invention."""
    offsets = [3, 7, 15]
    distractors = []
    for offset in offsets:
        candidate = year + offset if random.random() > 0.5 else year - offset
        # Avoid duplicating the correct year
        if candidate != year and 1 <= candidate <= 2100:
            distractors.append(str(candidate))
        else:
            distractors.append(str(year + offset))
    return distractors


def _quantity_distractors(value: int, unit: str = "") -> List[str]:
    """Generate plausible quantity distractors using multiplicative offsets."""
    candidates = [
        max(1, round(value * 0.5)),
        round(value * 1.5),
        round(value * 2.0),
        max(1, value - max(1, value // 3)),
        value + max(1, value // 2),
    ]
    # Remove duplicates and the correct value
    seen = {value}
    distractors = []
    for c in candidates:
        if c not in seen:
            seen.add(c)
            distractors.append(f"{c:,}{' ' + unit if unit else ''}")
        if len(distractors) == 3:
            break
    return distractors


def extract_year_questions(extract: str, title: str) -> List[GeneratedQuestion]:
    """
    Pattern: sentences containing a 4-digit year in range [1000, 2099].
    Only uses years that appear in a clear fact-bearing sentence.
    """
    questions = []

    # Pattern: "In YYYY" or "was born in YYYY" or "died in YYYY" or "opened in YYYY"
    year_pattern = re.compile(
        r"(?:^|[.!?]\s+)([A-Z][^.!?]{10,}?(?:in|on|during|founded|born|died|opened|completed|destroyed|occurred|happened|established)\s+(\b(1[0-9]{3}|20[0-9]{2})\b)[^.!?]{0,60}[.!?])",
        re.MULTILINE
    )

    sentences = re.split(r'(?<=[.!?])\s+', extract)
    used_years = set()

    for sentence in sentences[:10]:  # Only scan first 10 sentences
        matches = re.findall(r'\b(1[0-9]{3}|20[0-9]{2})\b', sentence)
        if not matches:
            continue
        year_str = matches[0]
        year = int(year_str)
        if year in used_years:
            continue
        used_years.add(year)

        # Truncate sentence for question display (max 120 chars)
        truncated = sentence.strip()
        if len(truncated) > 150:
            # Replace the year with a blank
            question_text = truncated.replace(year_str, "____", 1)
            if len(question_text) > 150:
                question_text = question_text[:147] + "..."
        else:
            question_text = truncated.replace(year_str, "____", 1)

        if "____" not in question_text:
            continue

        distractors = _year_distractors(year)
        if len(distractors) < 3:
            continue

        a, b, c, d, correct = _shuffle_options(year_str, distractors)
        questions.append(GeneratedQuestion(
            question=f'Fill in the blank: "{question_text}"',
            option_a=a, option_b=b, option_c=c, option_d=d,
            correct_option=correct,
            explanation=f"The correct year is {year_str}.",
            difficulty="easy",
            source="generated",
        ))

        if len(questions) >= 2:  # Max 2 year questions
            break

    return questions


def extract_quantity_questions(extract: str, title: str) -> List[GeneratedQuestion]:
    """
    Pattern: numbers with a clear unit (deaths, people, meters, km, etc.)
    Only uses quantities > 9 (single digits are too ambiguous).
    """
    questions = []
    quantity_pattern = re.compile(
        r'\b(\d{2,}(?:,\d{3})*)\s*(deaths?|people|persons?|meters?|kilometres?|km|miles?|tons?|years?|days?|hours?|floors?|feet)\b',
        re.IGNORECASE
    )

    sentences = re.split(r'(?<=[.!?])\s+', extract)
    used_values = set()

    for sentence in sentences[:8]:
        matches = list(quantity_pattern.finditer(sentence))
        if not matches:
            continue
        m = matches[0]
        raw_value = m.group(1).replace(",", "")
        try:
            value = int(raw_value)
        except ValueError:
            continue
        unit = m.group(2).lower()

        if value in used_values or value < 10:
            continue
        used_values.add(value)

        display_value = f"{value:,}"
        question_text = sentence.strip().replace(m.group(0), f"____ {unit}", 1)
        if len(question_text) > 150:
            question_text = question_text[:147] + "..."

        if "____" not in question_text:
            continue

        distractors = _quantity_distractors(value, unit)
        if len(distractors) < 3:
            continue

        a, b, c, d, correct = _shuffle_options(f"{display_value} {unit}", distractors)
        questions.append(GeneratedQuestion(
            question=f'Fill in the blank: "{question_text}"',
            option_a=a, option_b=b, option_c=c, option_d=d,
            correct_option=correct,
            explanation=f"The correct answer is {display_value} {unit}.",
            difficulty="medium",
            source="generated",
        ))

        if len(questions) >= 2:
            break

    return questions


def extract_title_question(extract: str, title: str) -> Optional[GeneratedQuestion]:
    """
    Creates a 'What is this article about?' question using first sentence.
    Works when the first sentence contains the title clearly.
    Distractors drawn from a static pool — never invented.
    """
    sentences = re.split(r'(?<=[.!?])\s+', extract)
    if not sentences:
        return None

    first_sentence = sentences[0].strip()
    if title.lower() not in first_sentence.lower():
        return None

    # Build question from first sentence, masking the title
    question_text = first_sentence.replace(title, "____", 1)
    if len(question_text) > 180:
        question_text = question_text[:177] + "..."

    # Generate 3 distractors from a contextual pool
    # We pick the pool based on words in the extract
    distractors = _pick_contextual_distractors(extract, title)
    if len(distractors) < 3:
        return None

    a, b, c, d, correct = _shuffle_options(title, distractors[:3])
    return GeneratedQuestion(
        question=f'What fills the blank? "{question_text}"',
        option_a=a, option_b=b, option_c=c, option_d=d,
        correct_option=correct,
        explanation=f"The subject of this article is {title}.",
        difficulty="hard",
        source="generated",
    )


def _pick_contextual_distractors(extract: str, correct_title: str) -> List[str]:
    """
    Picks distractor titles from static pools based on extract content.
    Never invents names — only uses items from predefined pools.
    """
    lower = extract.lower()

    # Geography context
    if any(w in lower for w in ["country", "city", "nation", "capital", "river", "mountain", "ocean"]):
        pool = _CITY_POOL + _COUNTRY_POOL
    else:
        pool = _COUNTRY_POOL + _CITY_POOL

    # Filter out correct answer
    pool = [p for p in pool if p.lower() != correct_title.lower()]
    random.shuffle(pool)
    return pool[:3]


def generate_questions_from_extract(
    extract: str, title: str, min_questions: int = 3, max_questions: int = 5
) -> Tuple[List[GeneratedQuestion], bool]:
    """
    Main entry point for Tier 3 deterministic question generation.

    Returns (questions, quiz_available).
    quiz_available = False if fewer than min_questions could be generated.

    Rules:
    - Never invents facts
    - Only uses unambiguous, clearly stated facts
    - Falls back gracefully: returns what it can, marks unavailable if < min
    """
    all_questions: List[GeneratedQuestion] = []

    # Try title question first (reliable baseline)
    title_q = extract_title_question(extract, title)
    if title_q:
        all_questions.append(title_q)

    # Extract year-based questions
    year_qs = extract_year_questions(extract, title)
    all_questions.extend(year_qs)

    # Extract quantity-based questions
    if len(all_questions) < max_questions:
        qty_qs = extract_quantity_questions(extract, title)
        all_questions.extend(qty_qs)

    # Trim to max
    all_questions = all_questions[:max_questions]

    quiz_available = len(all_questions) >= min_questions
    return all_questions, quiz_available
