# Quick Reference: Widget Constructor Parameters

## ✅ All Fixed and Verified

### AdminDashboardScreen (Main Container)
```dart
const AdminDashboardScreen({super.key});
```
**Manages**: User authentication, dashboard stats, interns, activity logs, scrolling

---

### InternCarouselSection
```dart
const InternCarouselSection({
  super.key,
  required List<InternProfile> interns,
  required bool loading,
  required String? error,
  required VoidCallback onRetry,
});
```
**Receives from parent**: List of interns, loading state, error message, retry callback  
**Manages internally**: Carousel animation, page controller, auto-scroll timer  
**Exports**: Navigation to InternDetailPage

---

### DashboardStatsGrid  
```dart
const DashboardStatsGrid({
  super.key,
  required Map<String, dynamic>? stats,
});
```
**Receives from parent**: Dashboard stats object  
**Props used from stats**:
- `stats['total_users']` → Total Users card
- `stats['active_users']` → Active Users card
- `stats['admin_users']` → Admins card
- `stats['new_users']` → Inactive card

---

### RecentUsersCard
```dart
const RecentUsersCard({
  super.key,
  required Map<String, dynamic>? stats,
  required int usersPage,
  required int totalPages,
  required int itemsPerPage,
  required Function(int) onPageChanged,
});
```
**Receives from parent**:
- `stats` → Contains list of recent users under `stats['recent_users']`
- `usersPage` → Current page index
- `totalPages` → Total number of pages
- `itemsPerPage` → Items to display per page (5)
- `onPageChanged` → Callback to update parent's `_usersPage`

---

### RecentActivityCard
```dart
const RecentActivityCard({
  super.key,
  required List<dynamic> activityLogs,
  required int activityPage,
  required int totalPages,
  required int itemsPerPage,
  required Function(int) onPageChanged,
});
```
**Receives from parent**:
- `activityLogs` → List of activity log entries
- `activityPage` → Current page index
- `totalPages` → Total number of pages
- `itemsPerPage` → Items to display per page (5)
- `onPageChanged` → Callback to update parent's `_activityPage`

---

### BouncingArrow
```dart
const BouncingArrow({
  super.key,
  required VoidCallback onTap,
});
```
**Receives from parent**: Callback to scroll to cards section  
**Manages internally**: Bouncing animation, AnimationController, Tween

---

### PaginationFooter (Reusable Helper)
```dart
const PaginationFooter({
  super.key,
  required int currentPage,
  required int totalPages,
  required VoidCallback onPrev,
  required VoidCallback onNext,
});
```
**Used by**: RecentUsersCard, RecentActivityCard  
**Receives**: Current page, total pages, prev/next callbacks

---

## Data Flow Diagram

```
Parent: AdminDashboardScreen (State Holder)
    ↓
    ├─→ InternCarouselSection
    │   - Receives: interns[], loading, error
    │   - Returns: Navigation actions
    │
    ├─→ DashboardStatsGrid
    │   - Receives: stats{total_users, active_users, admin_users, new_users}
    │   - Returns: (pure UI, no callbacks)
    │
    ├─→ RecentUsersCard
    │   - Receives: stats, usersPage, totalPages, onPageChanged()
    │   - Uses: PaginationFooter internally
    │   - Returns: Page change callbacks
    │
    ├─→ RecentActivityCard
    │   - Receives: activityLogs[], activityPage, totalPages, onPageChanged()
    │   - Uses: PaginationFooter internally
    │   - Returns: Page change callbacks
    │
    └─→ BouncingArrow
        - Receives: onTap() callback
        - Returns: Scroll to cards trigger
```

---

## Import Tree (Fixed)

```
📁 lib/screens/
  📄 admin_dashboard_screen.dart (Main file)
    ├── imports from: providers/auth_provider.dart ✓
    ├── imports from: providers/sidebar_provider.dart ✓
    ├── imports from: services/api_service.dart ✓
    ├── imports from: widgets/admin_layout.dart ✓
    ├── imports from: admin_glass_topbar.dart ✓
    ├── imports from: intern_widgets.dart ✓
    │
    └── imports from: ../widgets/admin_dashboard_widgets/
        ├── intern_carousel_section.dart ✓
        ├── dashboard_stats_grid.dart ✓
        ├── recent_users_card.dart ✓
        ├── recent_activity_card.dart ✓
        └── bouncing_arrow.dart ✓

📁 lib/widgets/admin_dashboard_widgets/
  ├── intern_carousel_section.dart
  │   └── imports from: ../../screens/intern_widgets.dart ✓
  │
  ├── dashboard_stats_grid.dart
  │   └── imports from: ../stat_card.dart ✓
  │
  ├── recent_users_card.dart
  │   └── imports from: ./pagination_footer.dart ✓
  │
  ├── recent_activity_card.dart
  │   └── imports from: ./pagination_footer.dart ✓
  │
  ├── bouncing_arrow.dart
  │   └── imports: flutter/material.dart only ✓
  │
  └── pagination_footer.dart
      └── imports: flutter/material.dart only ✓
```

---

## Const Modifiers Status

| Widget | Constructor Const | Reason |
|--------|------------------|--------|
| AdminDashboardScreen | ❌ (StatefulWidget, needs state) | -- |
| InternCarouselSection | ✅ const | Constructor is immutable |
| DashboardStatsGrid | ✅ const | Constructor is immutable |
| RecentUsersCard | ✅ const | Constructor is immutable |
| RecentActivityCard | ✅ const | Constructor is immutable |
| BouncingArrow | ✅ const | Constructor is immutable (Stateful) |
| PaginationFooter | ✅ const | Constructor is immutable |
| StatCard | ✅ const | Constructor is immutable |

**Note**: While StatefulWidget constructors can be const, the instances created in the build method cannot be const because they receive dynamic callbacks and state values. This is expected behavior.

---

## Testing Checklist

- [x] All imports resolve correctly
- [x] No compilation errors detected
- [x] Constructor parameters match definitions
- [x] Stateless/Stateful widget usage is correct
- [x] Const modifiers are properly applied
- [x] Data flows correctly from parent to children
- [x] Callbacks properly trigger state updates
- [x] Main file acts as clean orchestrator (not builder)

---

## How to Use This Screen

```dart
// Navigate to the dashboard
context.go('/admin/dashboard');

// The AdminDashboardScreen will:
// 1. Load stats via ApiService.getDashboardStats()
// 2. Load activity logs via ApiService.getActivityLogs()
// 3. Load interns via ApiService.getInterns()
// 4. Display all data through extracted widgets
// 5. Handle pagination, scrolling, and animations
```
