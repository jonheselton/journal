# Health Connect Permissions Declaration — Play Console Guide

When submitting your app to Google Play, you'll need to complete the **Health Connect permissions declaration form** in Play Console.

## Required Permissions

| Permission | Justification |
|------------|---------------|
| `READ_STEPS` | Display daily step count in the user's personal health journal entry |
| `READ_HEART_RATE` | Calculate and display average heart rate in the journal entry |
| `READ_SLEEP` | Display sleep duration and sleep stages in the journal entry |

## Declaration Form Answers

**How does your app use Health Connect data?**
> Daily Journal reads health metrics (steps, heart rate, sleep) from Health Connect to auto-populate the user's daily journal entry. All data is stored locally on-device in encrypted storage. No data is transmitted to any server or shared with third parties.

**Is this data shared with any third parties?**
> No. All data remains exclusively on the user's device.

**Is this data used for advertising?**
> No. The app contains no advertising.

**Where is your privacy policy?**
> Provide the hosted URL of `privacy_policy.html` (e.g., `https://yoursite.com/privacy`)

## Play Console Submission Steps

1. **Create your app listing** in [Google Play Console](https://play.google.com/console)
2. Navigate to **Policy and programs** → **App content**
3. Complete the **Health Connect** section:
   - Select the data types you read (Steps, Heart Rate, Sleep)
   - For each, explain the purpose (see justifications above)
   - Confirm you do not share data with third parties
4. Complete the **Privacy policy** section with your hosted URL
5. Complete the **Data safety** section:
   - Data collected: Health info (steps, heart rate, sleep), manual health entries
   - Data shared: None
   - Data encrypted: Yes
   - Data deletable: Yes (user can delete entries or uninstall)
6. Submit for review — **Health Connect apps go through manual review** (expect 1-4 weeks)

## Important Notes

> [!WARNING]
> Google may reject your first submission and request additional information. Common asks:
> - Video demonstration of how health data is used in the app
> - Clarification on why each data type is needed
> - Confirmation that data doesn't leave the device

> [!IMPORTANT]
> You must host the privacy policy at a publicly accessible URL before submitting. GitHub Pages or a simple static site works fine.
