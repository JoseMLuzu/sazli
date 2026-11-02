# Two-pane recipe book and iPhone Duo

The open Duo displays a recipe workspace: the library remains visible on the left while the selected recipe opens on the right. Users can switch recipes without navigating back to the library. Cooking takes over the display with ingredients on one side and the current step on the other.

The implementation uses native SwiftUI APIs available on iOS 17. It does not identify devices by model name, change device-family support, or modify the SwiftData schema.

## Navigation

`LibraryView` uses `NavigationSplitView` with balanced presentation and a preferred sidebar width of 320 points (260–360 points). The system determines when both columns can be displayed and when navigation should collapse.

The sidebar contains the logo, search, filters, a single-column recipe list, Settings, and Add a recipe. Narrow rows use smaller thumbnails, and a terracotta outline plus an accessibility selection trait identifies the current recipe. Each pane scrolls independently.

The selected UUID lives at the split-view root:

- Selecting a recipe updates the detail pane. On a compact display it also opens the detail column.
- Closing Duo retains the current recipe in a full-screen detail view with the native back action.
- Opening Duo restores the library beside the same recipe.
- Returning to the compact library and selecting the same recipe opens it again.
- Search and filters affect the sidebar results while the current recipe remains available in the detail pane.
- Deleting the selected recipe clears the selection after a successful save and returns compact navigation to the library.
- The initial detail pane explains how to select a recipe and supports adding the first recipe when the library is empty.

Selection is session state; saved recipe data continues to persist through SwiftData across app launches. The new-recipe editor and Settings sheets are attached to the split-view root. Editing an existing recipe and ratings remain scoped to the selected detail.

## Reading and cooking

The width of each content area controls its own layout. A sufficiently wide recipe detail pane can place ingredients and method side by side; narrower detail panes stack them for readability. At accessibility Dynamic Type sizes, these sections stack as well.

Full-screen cooking uses two balanced panels at widths of at least 640 points: scrollable ingredients on the left and a scrollable current step/progress on the right. Compact or accessibility layouts show the current step, with ingredients available in a sheet. Cooking controls stay anchored below the content, and accessibility-size controls stack vertically. Folding and rotation retain the current step.

`SazliLayout` in `App/SazliTheme.swift` defines the 640-point content breakpoint, 1,080-point reading limit, and 480-point primary-action limit. Recipe editor content is capped at 720 points. None of these values represents a physical hinge coordinate.

## Verify in Device Hub

1. Select **iPhone Duo (iOS 27.1)** in Xcode and run Sazli with at least two saved recipes.
2. Use **Open**. Select a recipe in the left pane and confirm its detail appears beside the library with the selected row outlined. Switch recipes without using Back.
3. Close Duo while a recipe is selected. Confirm it stays open with a working back action. Return to the library, choose another recipe, and reopen Duo; the new selection should remain visible in both panes.
4. Search or change a category/favorites filter in the sidebar. Confirm the current recipe remains readable while the result list updates.
5. Open the new-recipe editor, enter an unsaved title/time, and fold/unfold. Confirm the draft survives. Repeat with the existing-recipe editor, then save and check the detail and row update.
6. Start cooking, advance to the second step, and use **Partially Open**, **Closed**, **Open**, and rotation. Confirm the step/progress survive and ingredients use the expanded panel or compact sheet as appropriate.
7. Cancel a deletion and confirm selection remains. Confirm deletion only for a disposable recipe and check that the detail pane clears without showing stale data.
8. Repeat with long titles and steps, larger text, VoiceOver, light/dark appearance, and a regular iPhone. Confirm every action remains reachable.

The simulator's partially open preview may show a perspective effect. Sazli uses the content areas and navigation traits supplied by the system; these checks do not establish behavior on physical Duo hardware.
