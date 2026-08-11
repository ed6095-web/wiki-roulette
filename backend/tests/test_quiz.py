"""Tests for the three-tier quiz question generator."""
import pytest
from app.services.quiz_service import (
    generate_questions_from_extract,
    extract_year_questions,
    extract_quantity_questions,
    _year_distractors,
    _quantity_distractors,
)

RICH_EXTRACT = (
    "The Great Molasses Flood occurred on January 15, 1919, in the North End neighborhood of Boston. "
    "A large molasses storage tank burst, and a wave of molasses rushed through the streets. "
    "The disaster killed 21 people and injured 150 others. "
    "The storage tank held approximately 2,300,000 US gallons of molasses. "
    "The event occurred during World War I, when molasses was used to produce munitions."
)

THIN_EXTRACT = "A short article with no dates or numbers."


class TestYearDistractors:
    def test_returns_three_distractors(self):
        d = _year_distractors(1919)
        assert len(d) == 3

    def test_distractors_are_not_equal_to_correct(self):
        d = _year_distractors(1919)
        assert "1919" not in d

    def test_distractors_are_valid_years(self):
        d = _year_distractors(1919)
        for y in d:
            assert 1 <= int(y) <= 2100


class TestQuantityDistractors:
    def test_returns_three_distractors(self):
        d = _quantity_distractors(21, "people")
        assert len(d) == 3

    def test_no_correct_value_in_distractors(self):
        d = _quantity_distractors(21, "people")
        assert "21 people" not in d


class TestExtractYearQuestions:
    def test_finds_year_in_extract(self):
        qs = extract_year_questions(RICH_EXTRACT, "Great Molasses Flood")
        assert len(qs) >= 1

    def test_each_question_has_four_options(self):
        qs = extract_year_questions(RICH_EXTRACT, "Great Molasses Flood")
        for q in qs:
            assert q.option_a and q.option_b and q.option_c and q.option_d

    def test_correct_option_is_valid_letter(self):
        qs = extract_year_questions(RICH_EXTRACT, "Great Molasses Flood")
        for q in qs:
            assert q.correct_option in ("a", "b", "c", "d")

    def test_no_year_in_thin_extract(self):
        qs = extract_year_questions(THIN_EXTRACT, "Thin Article")
        assert len(qs) == 0


class TestGenerateQuestionsFromExtract:
    def test_rich_extract_generates_enough_questions(self):
        questions, quiz_available = generate_questions_from_extract(RICH_EXTRACT, "Great Molasses Flood")
        assert quiz_available is True
        assert len(questions) >= 3

    def test_thin_extract_marks_unavailable(self):
        _, quiz_available = generate_questions_from_extract(THIN_EXTRACT, "Thin Article", min_questions=3)
        assert quiz_available is False

    def test_no_question_exceeds_max(self):
        questions, _ = generate_questions_from_extract(RICH_EXTRACT, "Great Molasses Flood", max_questions=5)
        assert len(questions) <= 5

    def test_correct_option_always_in_options(self):
        questions, _ = generate_questions_from_extract(RICH_EXTRACT, "Great Molasses Flood")
        for q in questions:
            opts = {"a": q.option_a, "b": q.option_b, "c": q.option_c, "d": q.option_d}
            assert q.correct_option in opts
