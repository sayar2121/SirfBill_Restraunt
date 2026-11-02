# SirfBill Restaurant: Transformation & Architecture Specification

**Project:** SirfBill Restaurant POS & Management Platform  
**Target Repository:** `SirfBill_Restraunt`  
**Reference Base:** SirfBill Printer (`manju_medical`)  
**Date:** 21 October 2026  

---

## 1. Executive Summary & Objectives

The goal of this initiative is to transition the current repository from the legacy **SirfBill Printer** codebase (which originated from `manju_medical`) into a modern, production-grade **SirfBill Restaurant** POS, Kitchen Display System (KDS), and Restaurant Management platform.

### Core Architectural Decisions (from Blueprint)
1. **Dedicated Product Identity**: Treat SirfBill Restaurant as an independent product rather than a mode bolted into the printer application.
2. **Reuse Stable Cross-Cutting Concerns**: Reuse proven foundational layers—Flutter Riverpod, GoRouter, Dio networking, environment management, and PDF/receipt abstractions.
3. **Domain Separation**: Completely replace printer-shop specific concepts (paper sizes, print jobs, rack/bin management) with restaurant domain entities (Menu Categories, Menu Items, Modifiers/Variants, Dine-in Tables, KOT, and Shift Management).
4. **Strong Typing & Invariants**: Replace unstructured `List<Map<String, dynamic>>` cart representations with strongly typed domain entities, transactional order lifecycles, and idempotent checkout operations.

---

## 2. Comprehensive Repository Audit

### 2.1 Identity & Package Structure
- **Package Name**: Currently defined as `manju_medical` in `pubspec.yaml`, with remaining package imports in `test/widget_test.dart` and various internal widgets.
- **Windows Runner & CI/CD**: Workflow currently targets `product_id: "sirfbill-printer-windows"` and packages `SirfBill_Setup.exe`.
- **Inno Setup (`installer/setup.iss`)**: Configured for basic `SirfBill` with old GUIDs and URLs.

### 2.2 Feature & State Layer Analysis
- **Billing State**: Cart state is handled via dynamic dictionaries (`List<Map<String, dynamic>>`) in `BillingNotifier`.
- **Target Architecture (Feature-First Clean Architecture)**:
  ```
  lib/
  ├── app/                # Root app widget, router, themes, bootstrap
  ├── core/               # Network (Dio), auth, tenancy, printing, logging, errors
  ├── features/
  │   ├── auth/           # Login, token refresh, role permission gates
  │   ├── menu/           # Categories, items, modifiers/variants, availability
  │   ├── pos/            # Touch-friendly POS, dine-in/takeaway/delivery cart
  │   ├── orders/         # Order state machine (draft -> placed -> preparing -> ready -> served)
  │   ├── tables/         # Dine-in floor map, table states (available, occupied, billed)
  │   ├── kitchen_display/# KOT ticket printing & digital KDS screen
  │   ├── payments/       # Cash, UPI, card, split payments, idempotent checkout
  │   ├── staff_shifts/   # Shift open/close, cash drawer reconciliation
  │   └── reports/        # Daily sales, KOT summary, stock consumption
  └── shared/             # Reusable UI components, formatters, domain models
  ```

---

## 3. Targeted Modifications for Configuration & Workflows

### 3.1 `pubspec.yaml`
- **Name**: `sirfbill_restaurant`
- **Description**: `"SirfBill Restaurant - POS, Kitchen Display & Operations Management Platform"`
- **Version**: `1.0.0+1`
- **Dependencies**: Keep Riverpod, GoRouter, Dio, Printing, Pdf, and formatting packages. Ensure assets paths are properly configured for restaurant assets.

### 3.2 `.github/workflows/build_windows.yml` & Windows Runner
- **App Name**: `Sirfbill Restaurant` (updated in Flutter [lib/main.dart](file:///Users/sayarpaul/Project/SirfBill_Restraunt/lib/main.dart), Windows Runner [main.cpp](file:///Users/sayarpaul/Project/SirfBill_Restraunt/windows/runner/main.cpp), and [Runner.rc](file:///Users/sayarpaul/Project/SirfBill_Restraunt/windows/runner/Runner.rc)).
- **Executable Name**: `Sirfbill_Restaurant.exe` (updated in [windows/CMakeLists.txt](file:///Users/sayarpaul/Project/SirfBill_Restraunt/windows/CMakeLists.txt) and [installer/setup.iss](file:///Users/sayarpaul/Project/SirfBill_Restraunt/installer/setup.iss)).
- **Installer Name**: `Sirfbill_Restaurant_Setup.exe` (built via Inno Setup and published in GitHub Actions).
- **Product ID in manifest.json**: `"product_id": "sirfbill-restaurant-windows"`.

### 3.3 `.vscode/settings.json`
- Configure modern Flutter/Dart workspace standards:
  - Auto-format on save with Dart format rules.
  - Fix lint issues automatically on save (`source.fixAll`).
  - Search/file exclusions for Flutter build artifacts (`build/`, `.dart_tool/`).
  - Proper YAML & JSON schema settings.

### 3.4 Internal Package Imports & Test Files
- Update package references in:
  - `test/widget_test.dart`
  - `lib/utils/pdf_generator.dart`
  - `lib/screens/counter/widgets/...`
- Replace starter counter test with SirfBill Restaurant App bootstrap test.

---

## 4. Implementation Phases

```
Phase 1: Foundation (Active)
- Update pubspec.yaml, settings.json, CI/CD workflow, and test files.
- Establish clean feature-first folder scaffold.

Phase 2: Restaurant Menu & Order Cart Domain
- Define MenuItem, ModifierGroup, OrderLine, and Table models.
- Implement Riverpod RestaurantCartNotifier with server-side validation rules.

Phase 3: KOT & Kitchen Display System (KDS)
- Implement KOT ticket generation (80mm/58mm thermal print).
- Implement KDS live board (new, preparing, ready, completed).

Phase 4: Checkout, Split Payments & Shift Management
- Idempotent payment processing, cash drawer tracking, and daily shift close.
```
