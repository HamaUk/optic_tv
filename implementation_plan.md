# Refactor Admin Screen into Separate Tab Files

The `admin_screen.dart` file has grown significantly large (~4600 lines) because it houses the state and UI for all admin dashboard sections. We will extract each section into its own separate file to improve maintainability.

## Proposed Changes

We will create a new directory `lib/ui/admin/tabs/` and extract each tab into a dedicated `StatefulWidget` or `ConsumerWidget`. This includes moving their respective `TextEditingController`s, local state variables, and helper methods. 

The main `AdminScreen` will remain the "shell" (handling the `TabBar`, Auth Shield, and `TabBarView`).

### `lib/ui/admin/tabs/`
#### [NEW] [admin_overview_tab.dart](file:///c:/Users/Hama9/Desktop/newww/optic_tv/lib/ui/admin/tabs/admin_overview_tab.dart)
Extract `_buildOverviewTab()` and related helper methods into `AdminOverviewTab`.

#### [DELETE] Analytics Tab
We will remove `_buildAnalyticsTab()` and its corresponding tab.

#### [NEW] [admin_channels_tab.dart](file:///c:/Users/Hama9/Desktop/newww/optic_tv/lib/ui/admin/tabs/admin_channels_tab.dart)
Extract `_buildChannelsTab()`, search query state, and group filter state into `AdminChannelsTab`.

#### [NEW] [admin_movies_tab.dart](file:///c:/Users/Hama9/Desktop/newww/optic_tv/lib/ui/admin/tabs/admin_movies_tab.dart)
Extract `_buildMoviesTab()` into `AdminMoviesTab`.

#### [NEW] [admin_publish_tab.dart](file:///c:/Users/Hama9/Desktop/newww/optic_tv/lib/ui/admin/tabs/admin_publish_tab.dart)
Extract `_buildPublishTab()`, `_PublishShelf` enum, and all form controllers (e.g., `_channelNameController`, `_channelUrlController`) into `AdminPublishTab`.

#### [NEW] [admin_import_tab.dart](file:///c:/Users/Hama9/Desktop/newww/optic_tv/lib/ui/admin/tabs/admin_import_tab.dart)
Extract `_buildImportTab()`, Xtream controllers, and import progress state into `AdminImportTab`.

#### [DELETE] Health Tab
We will remove `_buildHealthTab()` and its corresponding tab and health-checking logic.

#### [NEW] [admin_access_tab.dart](file:///c:/Users/Hama9/Desktop/newww/optic_tv/lib/ui/admin/tabs/admin_access_tab.dart)
Extract `_buildAccessTab()`, login code generation, and durations into `AdminAccessTab`.

#### [NEW] [admin_broadcast_tab.dart](file:///c:/Users/Hama9/Desktop/newww/optic_tv/lib/ui/admin/tabs/admin_broadcast_tab.dart)
Extract `_buildAnnouncementTab()`, notification broadcast logic, and history tracking into `AdminBroadcastTab`.

#### [NEW] [admin_update_tab.dart](file:///c:/Users/Hama9/Desktop/newww/optic_tv/lib/ui/admin/tabs/admin_update_tab.dart)
Extract `_buildUpdateTab()` and OTA update controllers into `AdminUpdateTab`.

### `lib/ui/admin/`
#### [MODIFY] [admin_screen.dart](file:///c:/Users/Hama9/Desktop/newww/optic_tv/lib/ui/admin/admin_screen.dart)
- Delete all the extracted code.
- Import all the new tab files.
- Replace the `TabBarView` children with the new extracted widgets (e.g., `AdminOverviewTab()`, `AdminAnalyticsTab()`, etc.).
- Keep the `AuthService` shield and `_adminEnglishLtr` wrapper.

## User Review Required

> [!WARNING]
> Since this is a massive refactor affecting thousands of lines of code, the extraction process will happen systematically. I will extract a few tabs at a time to ensure no state is lost or incorrectly wired. 

Does this structure look good to you? Once you approve, I will begin the process of breaking down `admin_screen.dart` into these individual components.
