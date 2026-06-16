# iOS Shortcuts — Auto-Forward Bank SMS to the App

Because iOS doesn't let apps read messages directly, we use the **Shortcuts** app
to forward bank SMS text to Finance Reimagined automatically.

## How it works

When a bank SMS arrives, the Shortcut:
1. Captures the message body.
2. URL-encodes it.
3. Opens `fintrack://add-sms?text=<message>` — the app receives it, auto-parses,
   and shows you the extracted transaction ready to save.

---

## Option A — Automation (fully automatic, runs in background)

> Requires iOS 16.4+ and the **Allow Running Without Confirmation** toggle (see step 4).

1. Open the **Shortcuts** app → **Automation** tab → **+** (top-right).
2. Choose **Message** → set **Sender** to your bank's short-code or number
   (e.g. "CHASE", "32098", etc.).  
   Toggle **Any Message** off, check **Message Contains** → type `$`.
3. Tap **Next** → **New Blank Automation**.
4. Add action **Open URLs**.  
   In the URL field, paste:
   ```
   fintrack://add-sms?text=
   ```
   Then tap the URL field → **Insert Variable** → **Shortcut Input** → **Message** → **Message Body**.
   The full URL should look like:
   ```
   fintrack://add-sms?text=[Shortcut Input]
   ```
5. Tap **Done**.  
   Toggle **Run After Confirmation** → off (so it runs silently in the background).

The app will open, auto-parse the message, and pre-fill the transaction form.
Tap **Save Transaction** to confirm.

---

## Option B — Share Sheet (manual, one tap)

Use this when you want to forward a specific SMS you've already received.

1. Open **Shortcuts** app → **+** → **New Shortcut**.
2. Add action **Receive** → set Input to **Text**.
3. Add action **Open URLs** → URL: `fintrack://add-sms?text=[Shortcut Input]`.
4. Name it "Send to Finance" and save.

**To use:**
- Open **Messages** → long-press any bank SMS → **Share** → scroll to **Shortcuts** →
  tap **Send to Finance**.

---

## Supported banks (auto-detected)

Chase · Bank of America · Wells Fargo · Capital One · Citibank ·
American Express · Discover · TD Bank · US Bank · PNC · Synchrony ·
Navy Federal · USAA

For any other bank, the amount and date are still extracted automatically.
You can manually set the bank name before saving.

---

## Testing

You can test without a real bank SMS. In the Shortcuts app, run this URL manually:

```
fintrack://add-sms?text=A%20charge%20of%20%2442.50%20has%20been%20authorized%20on%20your%20Chase%20Visa%20card%20ending%201234%20at%20Amazon%20on%2006%2F05%2F2026.
```

That decodes to:
> A charge of $42.50 has been authorized on your Chase Visa card ending 1234 at Amazon on 06/05/2026.
