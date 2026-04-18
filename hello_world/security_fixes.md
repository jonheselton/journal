# Security and Privacy Remediation Plan

This document outlines identified vulnerabilities and privacy risks in the Daily Journal application.

## 1. PIN Brute-Force Vulnerability
- **Problem:** The fallback PIN authentication mechanism lacks rate limiting or exponential backoff.
- **Context:** `PinService` and `PinScreen` allow unlimited sequential attempts at the 4-digit PIN.
- **Risk:** High. A 10,000-combination space can be exhausted rapidly if physical access is obtained.
- **Recommendation:** Implement a 2-second delay after 3 failed attempts, increasing to 30 seconds after 5 attempts. Clear the session or lock the app after 10 consecutive failures.

## 2. Sensitive Keyword Exposure in Statistics
- **Problem:** The NLP-based keyword extraction (RAKE) surfaces sensitive journal content in an aggregate "Top Keywords" view.
- **Context:** `KeywordExtractor` and `StatisticsScreen` display the most frequent words from private entries.
- **Risk:** Medium. Sensitive medical, financial, or personal terms may be leaked on a high-level summary screen that the user might not expect to contain private details.
- **Recommendation:** Implement a blacklist for common sensitive terms and provide a user toggle to exclude specific entries or the entire "Top Keywords" cloud from the Statistics view.

## 3. Hardcoded Medical Metadata in Schema
- **Problem:** The database schema and data models include specific, hardcoded medication fields (e.g., "xanax").
- **Context:** `DatabaseService` and `DayEntry` model define fixed columns for specific substances.
- **Risk:** Low/Privacy. Hardcoding specific medical data into the structural schema leaks the "intent" of the application and the user's habits, even when the data is encrypted.
- **Recommendation:** Refactor the schema to use a generic `Metric` or `Medication` table where users can define their own tracking categories, ensuring the database structure remains agnostic to specific health conditions or treatments.
