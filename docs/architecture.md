# Architecture

SubZero's MVP is local-first. The UI is organized by feature, state and dependency injection use Riverpod, navigation uses GoRouter, and subscription persistence is abstracted behind a repository.

## Current foundation

- `lib/core`: theme and formatting utilities.
- `lib/data/models`: strongly typed subscription model and recurring-cost estimates.
- `lib/data/repositories`: local JSON persistence through SharedPreferences.
- `lib/features`: dashboard, subscription CRUD and settings.
- `test`: unit tests for billing-frequency calculations.

## Data and privacy decisions

The MVP does not connect to a backend or process payments. Currency totals are grouped by currency because no exchange-rate source is configured. The storage repository can later be replaced or complemented by a Supabase implementation without coupling screens to database APIs.

## Planned increments

1. Add calendar, trials, notification scheduling and richer validation.
2. Add analytics, export and accessibility improvements.
3. Introduce authenticated Supabase sync only after explicit account and Row Level Security design.
