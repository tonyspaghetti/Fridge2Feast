# Fridge2Feast

Fridge2Feast is a Flutter app that helps users turn ingredients they already have into personalized recipe ideas.

## Features (In Progress)
- Onboarding flow (account, profile, dietary preferences, calorie goal)
- Persistent user data using SharedPreferences
- Home dashboard with stats and quick actions
- Virtual kitchen (empty state UI)
- Settings screen (edit profile, preferences, calorie goal, sign out)
- Recipe Generation using Spoonacular API - accustomed to user preferences
- Freshness test using RoboFlow API - currently supports Oranges, Apples, Bananas, and Tomatoes with high accuracy - other produce has lower accuracy as the model is mostly trained on those 4 items

## Status
All functionality completed and integrated into a seamless app.

## Goal
Reduce food waste and make cooking easier with smart, personalized recipes.

## Tech Stack
- Flutter (Dart)

## Running Instruction
- Clone the repo
- make sure you are in the root Fridge2Feast Folder
- Run following commands in order:
  - flutter pub get
  - flutter run \
    --dart-define=SPOONACULAR_API_KEY="GO AWAY HACKERS - NO API KEY FOR YOU - K.S." \
    --dart-define=ROBOFLOW_API_KEY="GO AWAY HACKERS - NO API KEY FOR YOU - K.S."
- Make sure you have some form of emulator or a physical device to test the app on.
