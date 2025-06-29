# Korean TTS Reader

A desktop application for reading Korean text with Text-to-Speech (TTS) and integrated dictionary lookup.

## Features

- Text input and display.
- TTS playback of Korean text using AWS Polly or Google Cloud TTS.
- Word-by-word highlighting during TTS playback.
- Romanization of Korean text (Revised Romanization and McCune-Reischauer).
- Clickable words to look up definitions and examples.
- Dictionary functionality by scraping Daum Dictionary.

## Setup

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd korean-tts-reader
    ```

2.  **Create a virtual environment and activate it:**
    ```bash
    python -m venv .venv
    # On Windows
    .venv\Scripts\activate
    # On macOS/Linux
    source .venv/bin/activate
    ```

3.  **Install dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

4.  **Configure Environment Variables:**
    Copy the `.env.example` file to `.env` and fill in your API credentials:
    ```bash
    cp .env.example .env
    ```
    Edit `.env` with your credentials for:
    -   AWS Polly (if using AWS for TTS)
    -   Google Cloud TTS (if using Google for TTS)
    -   Naver API (Note: The dictionary now uses Daum scraping, so Naver credentials for dictionary are no longer strictly needed for that feature, but might be used by other parts or future features).

▶️  **Required AWS permissions**
   • `AmazonPollyReadOnlyAccess`   (speech synthesis)
   • `AmazonCloudWatchReadOnlyAccess`  (usage meter)
You can attach these managed policies to the same IAM user.

## Running the Application

```bash
python -m app.main
```

## Playback Controls

A toolbar provides the following playback controls:
-   **Play/Pause:** Start or pause TTS playback (Hotkey: `Space`).
-   **Rewind 5s:** Skip backward by 5 seconds.
-   **Fast-Forward 5s:** Skip forward by 5 seconds.
-   **Speed ComboBox:** Adjust playback speed (0.5x, 1.0x, 1.25x, 1.5x). Hotkeys: `[` to decrease speed, `]` to increase speed.

## Text Input

-   **File ▸ Open text… (Ctrl+O):** Open a UTF-8 encoded `.txt` file. The content will be loaded into the reading pane.
-   **Edit ▸ Paste as new text (Ctrl+Shift+V):** Paste plain text from the clipboard to load as new content in the reading pane.
-   **Direct Paste (Ctrl+V):** When the reading pane has focus, pasting text from the clipboard will also load it as new content.

## Word Interaction

-   **Click:** Click on any Korean word to look up its definition (if auto-lookup is enabled in Preferences).
-   **Hover:** When TTS playback is stopped or paused, hovering over a word will subtly highlight it. This feature is disabled during active playback to prioritize the main word highlight.

## Preferences

The application allows you to customize several options through the **Settings ▸ Preferences…** menu:
-   **Font size (px):** Adjust the font size for the Korean and romanized text in the reading pane (default: 16px, range: 8-48px).
-   **Show romanisation:** Toggle the visibility of the romanized text line beneath the Korean text (default: enabled).
-   **TTS provider:** Choose between "aws" (AWS Polly) and "gcp" (Google Cloud TTS) for text-to-speech synthesis (default: "aws"). Requires appropriate credentials in your `.env` file.
-   **Auto-lookup definitions on click:** Enable or disable automatic dictionary lookup when a word is clicked in the reading pane (default: enabled).

Your preferences are saved automatically and will be loaded the next time you start the application.

### Settings File Location

The settings are stored in a platform-specific configuration file:
-   **Windows:** `%APPDATA%\KoreanTTS\Reader.ini` (e.g., `C:\Users\<YourUser>\AppData\Roaming\KoreanTTS\Reader.ini`)
-   **macOS:** `~/Library/Preferences/com.KoreanTTS.Reader.plist`
-   **Linux:** `~/.config/KoreanTTS/Reader.conf`

## Tracking your Polly Usage

The application helps you monitor your AWS Polly character consumption to stay within the free tier or manage costs.

-   **Status Bar Display:** The main window's status bar will show your current monthly usage:
    `Characters: <used_chars> / <quota_chars> (<percent>%)`
    -   The color indicates usage level:
        -   **Green:** Less than 80% of the monthly free tier (5,000,000 characters) used.
        -   **Orange:** Between 80% and 95% used.
        -   **Red:** 95% or more used, or an error occurred fetching usage.
        -   **Gray (N/A):** If the quota is 0 or cannot be determined.
-   **Terminal Log:** The same usage information is printed to the terminal when updated.
-   **Polling:** Usage is checked automatically every 30 minutes and also once on application startup.
-   **Caching:** The most recently fetched character count is cached locally in `~/.hangu-tts/usage.json` (or platform equivalent for `~`) to provide an instant estimate on startup if the live CloudWatch query is slow or fails.
-   **Permissions:** This feature requires the IAM user to have `cloudwatch:GetMetricStatistics` permission, typically included in `AmazonCloudWatchReadOnlyAccess`. If permissions are insufficient, usage will show as "Error" or fall back to the cached value (or 0 if no cache).

The application queries the `CharactersProcessed` metric for the `AWS/Polly` namespace with a dimension of `Service: Polly`. This reflects the total characters processed by Polly under your account for the current calendar month.
## Running Tests

```bash
pytest
```
To include live API tests (e.g., for dictionary or TTS services that require credentials):
```bash
pytest --run-live-api 
# (Or ensure NAVER_CLIENT_ID/SECRET are set for old live dictionary tests if they are still relevant)
# Note: Live dictionary tests for Daum scraping do not require API keys.
```

## Dictionary Service - Daum Dictionary Scraping

The application uses web scraping of [Daum Dictionary](https://dic.daum.net/) to provide word definitions and examples.

**Important Note on Web Scraping (Polite Use):**
- This application attempts to be a "polite" scraper by including a `User-Agent` header and implementing a rate limit (`MIN_DELAY` in `app/core/dictionary.py`) to ensure it does not overload Daum's servers.
- If Daum scraping fails to find a suitable English definition, the app falls back to Google Translate’s public JSON endpoint to ensure an English gloss is always shown. This fallback also respects the rate limiting.
- Please be mindful of the terms of service for both Daum and Google. Excessive or abusive scraping can lead to IP bans or other restrictions.
- The scraping selectors in `app/core/dictionary.py` are based on the Daum Dictionary website structure at the time of implementation and may break if Daum updates its website layout.

## Dependencies

Key dependencies are listed in `requirements.txt`. This includes:
- `PySide6` for the GUI.
- `requests` for HTTP requests (used by dictionary scraper).
- `beautifulsoup4` for parsing HTML (used by dictionary scraper).
- `python-dotenv` for managing environment variables.
- `boto3` for AWS Polly TTS.
- `google-cloud-texttospeech` for Google TTS.
- `hangul-romanize` for Korean romanization.
- `pytest` and `pytest-qt` for testing.


---

## How to get the iOS build on your phone (no Mac)

1. Push code to GitHub ➜ Actions ➜ *Build iOS IPA* ➜ **Run workflow**
2. Download the `HanguTTS-unsigned.ipa` artifact when the job finishes
3. Open AltServer on Windows → **Install .ipa** → pick the file
4. Trust the developer certificate on the iPhone (Settings ▸ General ▸ VPN & Device Management)
5. Launch *Hangu TTS* – refresh every 7 days via AltStore
