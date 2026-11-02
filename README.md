<div align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/LOGO_DM.png">
    <source media="(prefers-color-scheme: light)" srcset="assets/LOGO.png">
    <img alt="SirfBill Logo" src="assets/LOGO.png" width="300">
  </picture>
  <br/>
  <h1>SirfBill Restaurant - Point of Sale, KOT & Operations Management Platform</h1>
  <p><strong>Hospitality without friction</strong> • Multi-Floor Table Management, Real-Time KOT Dispatch, Kitchen Display System (KDS), Dynamic Multi-Tender Billing, Menu Modifiers, and Executive Analytics</p>
</div>

---

## 📋 Table of Contents

- [Project Overview](#-project-overview)
  - [The Problem It Solves](#the-problem-it-solves)
  - [Core Capabilities](#core-capabilities)
- [Tech Stack](#-tech-stack)
- [Prerequisites](#-prerequisites)
- [Getting Started](#-getting-started)
  - [1. Clone Repository](#1-clone-repository)
  - [2. Environment Configuration](#2-environment-configuration)
  - [3. Install Dependencies](#3-install-dependencies)
  - [4. Run on Web](#4-run-on-web)
  - [5. Run on Desktop (macOS / Windows / Linux)](#5-run-on-desktop)
- [Project Architecture & Modules](#-project-architecture--modules)
  - [Interactive POS & Fast Counter Billing](#-interactive-pos--fast-counter-billing)
  - [Floor Plan & Table Management](#-floor-plan--table-management)
  - [Live Kitchen Order Tickets (KOT) & Kitchen Display System (KDS)](#-live-kitchen-order-tickets-kot--kitchen-display-system-kds)
  - [Menu Management & Category Taxonomy](#-menu-management--category-taxonomy)
  - [Thermal Receipts & Multi-Format Invoicing](#-thermal-receipts--multi-format-invoicing)
  - [Executive Analytics, Item-Wise Sales & Audit Trail](#-executive-analytics-item-wise-sales--audit-trail)
  - [Inventory, Distributors & Financial Ledger](#-inventory-distributors--financial-ledger)
- [Backend API Contract](#-backend-api-contract)
- [State Management (Riverpod)](#-state-management-riverpod)
- [Troubleshooting & Gotchas](#-troubleshooting--gotchas)
- [License](#-license)

---

## 📖 Project Overview

**SirfBill Restaurant** is a high-speed, modern Point of Sale (POS) and restaurant management application built with **Flutter** and **FastAPI**. It empowers restaurants, cafes, quick-service counters (QSR), cloud kitchens, and fine dining establishments to manage their entire lifecycle: table seating, KOT ticket generation, kitchen order processing, split-tender checkout, thermal receipt printing, and executive business analytics.

### The Problem It Solves
Traditional restaurant software is often clunky, locked to slow proprietary hardware, or divides front-of-house from back-of-house:
- **Floor Seating & Held Orders**: Dine-in tables transition between empty, occupied, and reserved, requiring seamless appending of extra courses or items to an active bill without losing previous kitchen records.
- **Instant KOT Printing & KDS Sync**: Kitchen stations need instant, reliable thermal tickets and live digital KDS boards that automatically update as tickets are prepared, served, or cancelled.
- **Split & Multi-Tender Payment**: Diners pay across Cash, Dynamic UPI QR codes, and Cards/EDC terminals. The POS supports flexible multi-tender settlement.
- **Data-Driven Menu & Dish Analytics**: Owners need real-time item-level revenue tracking, category mix analysis, and tamper-evident audit trails.

### Core Capabilities
- 🍽️ **Interactive Floor & Table Grid**: Visual multi-floor table layouts with real-time seating timers, capacity indicators, and direct order docking.
- 🖨️ **Automated KOT Dispatch**: Generates formatted Kitchen Order Tickets (KOT) for ESC/POS 80mm/58mm thermal printers and live KDS boards.
- 💳 **Flexible Settlement**: Supports Dine-In, Takeaway, and Delivery orders with multi-tender checkout (Cash, Dynamic UPI QR, Card).
- 📜 **Dynamic Receipts**: Thermal 80mm bill generation, customer receipt modals, and instant reprint capabilities.
- 📈 **Executive Analytics**: Period-based revenue breakdowns (Today, This Week, This Month, All Time, Custom), Top Performing Dishes, and comprehensive Excel/PDF export pipelines.
- 🔐 **Multi-Tenant SaaS Architecture**: Built-in tenant isolation with branch-level switching, customized GST, service charges, and branding.

---

## 🛠️ Tech Stack

### Frontend Architecture
| Technology | Role | Description |
|---|---|---|
| **Flutter (Web & Desktop)** | Core Framework | Cross-platform canvas-rendered UI running smoothly in browsers and native Windows/macOS desktop. |
| **Riverpod** | State Management | Reactive, compile-time safe state management for active orders, tables, live KOT tickets, and reporting metrics. |
| **GoRouter** | Declarative Routing | Stateful routing with browser URL synchronization and keyboard shortcut bindings (`F1` to `F8`). |
| **Dio & Pretty Logger** | Networking | HTTP client with automatic Bearer token interceptor, tenant header propagation, and error handling. |
| **pdf & printing** | Invoicing & KOT Engine | Vector PDF generation for 80mm/58mm thermal receipts, A4/A5 customer invoices, and executive analytics reports. |
| **excel & file_saver** | Report Exporting | Multi-sheet `.xlsx` report generator for Sales Summaries, Order Registers, Item-Wise Sales, and Audit Logs. |

### Backend Architecture
| Technology | Role | Description |
|---|---|---|
| **Python & FastAPI** | Core REST API | Asynchronous, auto-documenting OpenAPI endpoints with strict Pydantic data schemas. |
| **SQLAlchemy 2.0** | Database ORM | High-performance ORM with strict tenant-isolation filters across shops, tables, orders, and lines. |
| **PostgreSQL** | Relational Database | ACID-compliant transactional persistence for orders, inventory, customers, and settlement logs. |
| **JWT** | Authentication | Stateless authentication carrying user identities, roles, and assigned `shop_id` / `tenant_id`. |

---

## 📋 Prerequisites

- **Flutter SDK**: `>=3.22.0` (Dart `>=3.5.0`)
- **Google Chrome**: Recommended for web execution and debugging
- **Visual Studio 2022** (Desktop C++ workload): Required only if building Windows native `.exe`
- **Xcode & CocoaPods**: Required only if compiling macOS/iOS targets

---

## 🚀 Getting Started

### 1. Clone Repository
```bash
git clone https://github.com/your-username/sirfbill_restaurant.git
cd sirfbill_restaurant
```

### 2. Environment Configuration
Create a `.env` file in the root directory:
```env
API_BASE_URL=http://localhost:8000
```
*(Or point to your remote backend server, e.g. `http://192.168.0.240:8000`)*

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run on Web
```bash
flutter run -d chrome
```

### 5. Run on Desktop
```bash
# macOS
flutter run -d macos

# Windows
flutter run -d windows
```

---

## 📂 Project Structure

```
lib/
├── config/                  # API client, environment constants & theme configs
│   ├── api_client.dart      # Central Dio client with JWT & tenant interceptors
│   └── ...
├── models/                  # Strong DTO data models
│   ├── restaurant_pos_models.dart   # DiningTable, RestaurantOrder, PosCartItem, etc.
│   ├── restaurant_report_models.dart# SalesReportSummary, TopSellingDish, AuditLogEntry
│   └── counter_models.dart          # Customer, SavedBill, ShopSettings
├── notifiers/               # Riverpod state notifiers (History, Accounts, Customers)
├── providers/               # Global Riverpod providers
│   ├── restaurant_pos_provider.dart    # Cart state, active order, table selection
│   ├── restaurant_table_provider.dart  # Floor tables, occupied state, order timers
│   ├── kitchen_display_provider.dart   # KDS ticket queue and status management
│   ├── restaurant_order_provider.dart  # Order list, filters, and status transitions
│   └── restaurant_report_provider.dart # Financial metrics, dish ranking, audit logs
├── router/                  # GoRouter configuration & route definitions
├── screens/counter/         # Main business screens
│   ├── billing_screen.dart             # POS Counter, menu catalog, cart, table picker
│   ├── table_management_screen.dart    # Floor plan, table visualizer & status editor
│   ├── kitchen_display_screen.dart     # Kitchen Display System (KDS) board
│   ├── order_management_screen.dart    # Orders register, active/completed tabs
│   ├── reports_screen.dart             # Analytics, item sales & audit trail
│   ├── menu_management_screen.dart     # Dishes, categories, pricing & status
│   └── widgets/                        # Modular UI components & export helpers
│       ├── pos/                        # Settlement, bill receipts, modal dialogs
│       ├── reports/                    # Executive PDF & Excel export helpers
│       └── ...
├── services/                # Backend API integration services
│   ├── restaurant_pos_service.dart     # Orders, tables, KOT dispatch & settlement
│   ├── billing_service.dart            # POS history & checkout fallback
│   ├── inventory_service.dart          # Stock items & shop identification
│   └── shop_service.dart               # Shop profile & configuration
└── utils/                   # Helper utilities
    ├── kot_printer_helper.dart         # KOT thermal ticket layout generator
    └── pdf_thermal_generator.dart      # Customer bill thermal invoice generator
```

---

## 🎯 Feature Modules

### 🛒 Interactive POS & Fast Counter Billing
- **Keyboard Shortcuts**: Quickly navigate screens using `F1` (Billing), `F2` (Tables), `F3` (Orders), `F4` (Kitchen), `F5` (Menu), `F6` (Customers), `F7` (Reports), `F8` (Settings).
- **Flexible Order Types**: Easily switch between **Dine-In**, **Takeaway**, and **Delivery**.
- **Customer Linking**: Link phone and name with auto-complete from existing customer directory.
- **Hold & Append**: Put orders on hold while tables dine; reload the active cart anytime to add more courses or items without losing previous history.

### 🪑 Floor Plan & Table Management
- **Floor Hierarchy**: Organize tables across Ground Floor, 1st Floor, Rooftop, Patio, etc.
- **Live Seating Timers**: Color-coded badges indicating duration since the table was seated.
- **Direct Table Billing**: Tapping an occupied table reloads its active cart and order state directly onto the counter POS.

### 🍳 Live Kitchen Order Tickets (KOT) & KDS
- **One-Click KOT Printing**: Dispatches thermal tickets directly to designated kitchen printers.
- **Kitchen Display System (KDS)**: Interactive board for kitchen staff showing live ticket age, ordered items, item notes, and one-tap status advancement (`New` ➔ `Preparing` ➔ `Ready` ➔ `Served`).

### 📑 Thermal Receipts & Multi-Format Invoicing
- **Thermal Printing**: High-resolution 80mm and 58mm receipts with itemized taxes, shop branding, GSTIN, CIN, and customer details.
- **Dynamic UPI QR Code**: Generates dynamic settlement QR codes on the customer screen or receipt for instant smartphone payments.

### 📊 Executive Analytics & Item-Wise Sales
- **Pre-set & Custom Date Filters**: Today, This Week, This Month, This Year, All Time, or Custom Range.
- **Key Performance Indicators**: Gross Revenue, Net Revenue, GST Collected, Total Bills, and Average Check (AOV).
- **Tender & Channel Distribution**: Breakdown of revenue across Cash, UPI, and Card, as well as Dine-In vs. Takeaway.
- **Top Performing Dishes**: Real-time ranking of top selling menu items sorted by revenue.
- **Multi-Sheet Excel & Executive PDF Exports**: Generate formatted reports ready for business review and tax filing.

---

## 🔌 Backend API Contract

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/restaurant/tables` | Fetch tables with floor and live occupancy status |
| `PATCH`| `/api/restaurant/tables/{id}/status` | Update table status (`AVAILABLE`, `OCCUPIED`, `RESERVED`) |
| `GET` | `/api/restaurant/orders` | Fetch orders list with status and date filters |
| `POST` | `/api/restaurant/orders` | Create a new restaurant order with lines |
| `PATCH`| `/api/restaurant/orders/{id}/items` | Append additional items to an active order |
| `POST` | `/api/restaurant/orders/{id}/settle` | Settle payment with multi-tender support |
| `POST` | `/api/restaurant/orders/{id}/send-to-kitchen` | Dispatch order ticket to kitchen / KOT printer |
| `GET` | `/api/restaurant/orders/{id}/thermal-bill` | Fetch 80mm thermal bill template |
| `GET` | `/api/admin/pos/history` | Retrieve historical POS transactions and item lines |

---

## ⚠️ Troubleshooting & Gotchas

1. **Environment File (`.env`)**:
   Always ensure a valid `.env` file exists with `API_BASE_URL`. For production builds, you can pass `--dart-define=API_BASE_URL=...` during build.
2. **Thermal Ticket Layout**:
   Thermal printing formatting is pre-configured for standard 80mm (approx 72mm printable width) paper. Adjust padding in `kot_printer_helper.dart` if using 58mm compact rolls.
3. **UTC / Local Time Synchronization**:
   Timestamps received from FastAPI backend in UTC are automatically parsed and displayed in the client's local timezone.

---

## 📄 License

This software is proprietary and developed for **SirfBill Restaurant POS**. Unauthorized copying, distribution, or commercial exploitation is strictly prohibited.
