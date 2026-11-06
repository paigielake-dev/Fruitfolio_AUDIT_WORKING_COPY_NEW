#!/usr/bin/env python3
"""Deprecated entry point: use the actual offline MADLAD catalog draft workflow.
The former Qwen auto-translation/auto-approval path has been removed. Existing
--model/--llama-cli/--overwrite options intentionally fail instead of silently
substituting the assistant model or approving unreviewed medical translations.
"""
from translate_catalog_with_madlad import main

if __name__ == '__main__':
    raise SystemExit(main())
