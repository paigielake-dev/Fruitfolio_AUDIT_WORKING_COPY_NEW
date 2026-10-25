# Fruitfolio localization status after Pass 6 cleanup

- 45 locales are represented: English + 44 target languages.
- Vietnamese (`vi`) and Filipino (`fil`) were added as first-class Settings choices and String Catalog locales.
- Arabic and the previously cataloged Indian/African languages are now also represented in the Settings language enum, so the selector and catalog no longer disagree.
- RTL includes Persian, Arabic, and Urdu.
- `Fruitfolio/Localizable.xcstrings` contains 471 English source entries.
- Target translation values are still empty in the uploaded catalog. They were NOT filled with English copies or fabricated translations.
- `Tools/translate_catalog_with_llama.py` is included to populate the catalog locally using a real `llama-cli` plus the actual `FruitfolioAI.gguf`, preserving existing translations and protecting placeholders/numbers/units/URLs/abbreviations.

This means localization architecture is present, but translated copy is not release-complete yet.
