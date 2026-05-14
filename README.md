# Fridge2Feast

Fridge2Feast is a Flutter mobile app that helps users turn ingredients they already have into personalized recipe ideas while reducing food waste.

## Features
- User onboarding flow (account creation, profile setup, dietary preferences, calorie goals)
- Persistent user data using SharedPreferences
- Personalized homepage dashboard
- Virtual kitchen inventory system using SQLite
- Add, remove, and organize ingredients by category
- Recipe generation using the Spoonacular API
- Personalized recipes based on dietary restrictions, allergies, and calorie goals
- Recipe saving and cooking history
- AI-powered freshness detection using the Roboflow API
- Editable settings and profile management

## Freshness Detection Support
The freshness detection model is currently optimized for:
- Apples
- Bananas
- Oranges
- Tomatoes

Other produce may have lower accuracy because the model is primarily trained on those items.

## Status
Completed and fully integrated Flutter application.

## Goal
Reduce food waste and make cooking easier with smart, personalized recipe recommendations.

## Tech Stack
- Flutter (Dart)
- SharedPreferences
- SQLite (sqflite)
- Spoonacular API
- Roboflow API

## Running Instructions

1. Clone the repository

2. Make sure you are inside the root `Fridge2Feast` folder

3. Run the following commands:

```bash
flutter pub get
dart run flutter_launcher_icons
flutter run \
  --dart-define=SPOONACULAR_API_KEY="YOUR_SPOONACULAR_API_KEY" \
  --dart-define=ROBOFLOW_API_KEY="YOUR_ROBOFLOW_API_KEY"