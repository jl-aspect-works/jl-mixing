"""Shared v1.4-compatible validation rules."""

from __future__ import annotations

from .errors import ValidationError

SUPPORTED_SAMPLE_RATES = frozenset({44100, 48000, 88200, 96000, 176400, 192000})
SUPPORTED_BIT_DEPTHS = frozenset({16, 24, 32})


def require_sample_rate(value: object) -> int:
    if not isinstance(value, int) or isinstance(value, bool) or value not in SUPPORTED_SAMPLE_RATES:
        raise ValidationError(f"Unsupported expected sample rate: {value}")
    return value


def require_bit_depth(value: object) -> int:
    if not isinstance(value, int) or isinstance(value, bool) or value not in SUPPORTED_BIT_DEPTHS:
        raise ValidationError(f"Unsupported expected bit depth: {value}")
    return value
