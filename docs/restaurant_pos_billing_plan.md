# Restaurant POS Billing Section: Architecture & Widget Plan

**Target Feature:** High-Speed Restaurant POS Billing Screen  
**Design Reference:** Modern Dual-Pane Restaurant POS UI  
**Design Principles:** Modular, feature-first, strongly typed, reusable widgets (max ~100-150 lines per widget).

---

## 1. UI Breakdown (Dual Pane Architecture)

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ TOP BAR: Branch Selector | Global Food Search (Ctrl+K) | Order Types (Dine-in/Takeaway/│
│          Delivery) | Network & KOT Alerts | Cashier Profile                            │
├─────────────────────────────────────────────┬──────────────────────────────────────────┤
│ LEFT PANE (Menu & Catalog Discovery)        │ RIGHT PANE (Active Order & Settlement)   │
│                                             │                                          │
│ 1. Category Pill Selector (Horizontal)      │ 1. Order Mode Tabs (Table/Takeaway/Del)  │
│    - All, Beverages, Starters, Main, etc.   │ 2. Table / Floor Selector Grid           │
│ 2. Menu Item Cards Grid                     │ 3. Quick Customer Attachment (+ New)     │
│    - Food photo thumbnail                   │ 4. Cart Items Table                      │
│    - Dish Name & Price                      │    - Item name, modifiers snapshot       │
│    - Badges (Popular, Bestseller)           │    - Price, Qty stepper (- 1 +), Delete  │
│    - Tap to add / select modifier           │ 5. Order Notes input field               │
│                                             │ 6. Financial Summary (Subtotal, Tax, Tot)│
│                                             │ 7. Action Bar: Save/Hold | KOT | Pay     │
└─────────────────────────────────────────────┴──────────────────────────────────────────┘
```

---

## 2. Strongly Typed Domain Models

Located in `lib/models/restaurant_pos_models.dart`:

1. **`MenuItem`**: `id`, `name`, `category`, `price`, `imageUrl`, `badge` (Popular, Bestseller, etc.), `taxRate`, `isAvailable`.
2. **`CartItem`**: `menuItem`, `quantity`, `selectedModifiers`, `itemNotes`, `totalPrice`.
3. **`DiningTable`**: `id`, `label`, `floor`, `capacity`, `status` (`available`, `occupied`, `billed`), `occupiedDuration`.
4. **`OrderType`**: `dineIn`, `takeaway`, `delivery`.
5. **`CustomerSummary`**: `id`, `name`, `phone`, `loyaltyPoints`.

---

## 3. Modular Reusable Widgets Structure

Split the current monolith (`851 lines`) into focused, single-responsibility components:

| Component File | Role / Responsibility | Lines Target |
| :--- | :--- | :--- |
| `widgets/pos/pos_top_bar.dart` | Branch dropdown, search bar, order-type pills, cashier profile | ~80 lines |
| `widgets/pos/pos_category_selector.dart` | Horizontal scrollable category pills with icon + badge | ~60 lines |
| `widgets/pos/pos_menu_grid.dart` | Responsive grid showing dishes with thumbnail & badges | ~90 lines |
| `widgets/pos/pos_menu_card.dart` | Individual dish card with photo, price, and add action | ~70 lines |
| `widgets/pos/pos_table_selector.dart` | Floor dropdown + table status chips (Empty, Occupied) | ~85 lines |
| `widgets/pos/pos_customer_bar.dart` | Phone/Name search input with "+ New" customer button | ~55 lines |
| `widgets/pos/pos_cart_item_tile.dart` | Cart item row with quantity stepper and price calc | ~80 lines |
| `widgets/pos/pos_bill_summary.dart` | Subtotal, discounts, GST calculation breakdown | ~70 lines |
| `widgets/pos/pos_bottom_action_bar.dart` | "Save / Hold", "Print KOT", "Proceed to Payment" | ~65 lines |
| `screens/counter/billing_screen.dart` | Orchestrator connecting left pane and right pane | ~120 lines |

---

## 4. State Management (`restaurant_pos_provider.dart`)

- Single source of truth using Riverpod:
  - `activeCategory`
  - `searchQuery`
  - `orderType` (Dine-in / Takeaway / Delivery)
  - `selectedTable`
  - `cartItems`
  - `attachedCustomer`
  - `discount` & `taxes`
  - Clear, Hold, KOT dispatch, and Checkout actions.
