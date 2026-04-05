# Campo

Personal football training tracker for iPhone. Built for a Sunday league player preparing for match day.

## What it does

- Weekly session pool — complete any session any day, no fixed schedule
- Exercise library with timer and image guides
- "Skip" a session with a reason (not a failure, just context)
- Weight tracking
- AI coach that reads your current cycle, weekly progress, and daily check-in

## Stack

Flutter · Hive · Firebase (Auth, Firestore, Functions) · Anthropic Claude

## Architecture

Hive is the local cache for instant UI. Firestore is the source of truth. The AI coach runs through a Cloud Function — the Anthropic API key never touches the client.

## Setup

1. Clone the repo
2. Add `ios/Runner/GoogleService-Info.plist` from your Firebase project
3. `flutter pub get`
4. `cd functions && npm install`
5. `firebase functions:secrets:set ANTHROPIC_KEY`
6. `firebase deploy --only functions`
7. Run on device
