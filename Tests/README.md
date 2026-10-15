Quick Finish order checks (from the Ordered project directory):

```sh
xcrun swiftc Ordered/Model/QuickFinishOrder.swift Tests/QuickFinishOrderTests.swift -o /tmp/ordered-order-tests
/tmp/ordered-order-tests
```

These checks use an isolated preferences suite and cover independent copies of All Events, per-order visibility and sorting, renaming, selected-order persistence, and added/removed library entries. They do not touch app data.

Manual UI check: tap All Events → Add New Order; verify the title becomes a focused New Order field. Rename it, use the pencil to reorder/hide categories and events, then switch to All Events and back. Confirm All Events is unchanged, the custom layout is restored after relaunch, and closing the editor with Done or a swipe retains changes without a Save button.

Category display persistence and lightweight migration checks:

```sh
mkdir -p /tmp/ordered-category-models
/Applications/Xcode.app/Contents/Developer/usr/bin/momc Ordered/Ordered.xcdatamodeld/OneTimePlan.xcdatamodel /tmp/ordered-category-models/Old.mom
/Applications/Xcode.app/Contents/Developer/usr/bin/momc Ordered/Ordered.xcdatamodeld/CategoryDisplayState.xcdatamodel /tmp/ordered-category-models/New.mom
xcrun swiftc -parse-as-library -module-cache-path /tmp/ordered-category-module-cache Tests/CategoryDisplayPersistenceTests.swift -o /tmp/ordered-category-persistence-tests
/tmp/ordered-category-persistence-tests /tmp/ordered-category-models/Old.mom /tmp/ordered-category-models/New.mom
```

These checks use a temporary SQLite database. They verify migration preserves existing categories and their identifiers, then reopen the store to verify minimized state and same-day finished-category expansion persist, including Uncategorized.

Manual UI check: minimize a category, relaunch, and verify it remains minimized. Expand it and relaunch again. Complete all non-hidden events, reopen the automatically minimized category, and relaunch on the same day; it should remain expanded and marked Finished. On the next day, its Finished label should clear while manually minimized categories remain minimized.

Category toggle refresh regression check: on Quick Finish, tap the same category arrow at least six times without scrolling. Verify each tap immediately changes both the arrow direction and tile visibility. Repeat for a newly created category (first saved preference), an existing saved category after relaunch, Uncategorized, and a finished category. Reopened finished categories must retain their tick and remain open until explicitly minimized again.

Event creation paywall continuation checks:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swiftc -module-cache-path /tmp/ordered-event-creation-module-cache Ordered/ViewModel/EventCreationGate.swift Tests/EventCreationGateTests.swift -o /tmp/ordered-event-creation-gate-tests
/tmp/ordered-event-creation-gate-tests
```

These checks cover the existing 50-event free limit, Premium bypass, purchase/restore authorization, cancellation, failure and retry, and consuming the pending Create request only once.

Sandbox purchase UI check: with 50 active library events and no Premium entitlement, open a category, tap Create Event, and enter a name and emoji. Tap Create, buy Premium, and verify exactly one event is created and selected in the still-open category editor after the paywall dismisses. Repeat with Restore Purchases for an account with Premium. Cancel or fail a purchase and confirm the draft is still present and no event was created. A restore without Premium must not create the event. If saving fails after purchase, the draft must remain available for retry without another purchase.

Subscription status regression checks:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swiftc -module-cache-path /tmp/ordered-event-creation-module-cache Ordered/ViewModel/PremiumAccessState.swift Tests/PremiumAccessStateTests.swift -o /tmp/ordered-premium-state-tests
/tmp/ordered-premium-state-tests
```

These checks verify unknown status is distinct from free access, cached active access can seed startup, older responses cannot overwrite a newer purchase or expiry, and newer renewal data restores access. Run the EventCreationGate checks above alongside them.

Sandbox subscription UI checks: launch with an existing Premium purchase and create the 51st event without Restore Purchases; background and return after changing entitlement status; start offline with cached Premium; start without cached info and make the check fail (keep the draft and show a retryable error, not a purchase requirement); verify a confirmed expiry removes Premium access. Test both purchase and restore callbacks plus delayed customer-info responses. Dashboard validation must confirm the exact case-sensitive entitlement identifier `Premium` is attached to each paid product; the app uses RevenueCat's anonymous identity and does not implement account login.

Onboarding category persistence checks (from the Ordered project directory):

```sh
mkdir -p /tmp/ordered-onboarding-tests/generated
/Applications/Xcode.app/Contents/Developer/usr/bin/momc --action generate --swift-version 5.0 Ordered/Ordered.xcdatamodeld /tmp/ordered-onboarding-tests/generated
/Applications/Xcode.app/Contents/Developer/usr/bin/momc Ordered/Ordered.xcdatamodeld/CategoryDisplayState.xcdatamodel /tmp/ordered-onboarding-tests/Model.mom
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swiftc -parse-as-library -module-cache-path /tmp/ordered-onboarding-tests/cache /tmp/ordered-onboarding-tests/generated/*.swift Ordered/ViewModel/WelcomeVM.swift Tests/OnboardingCategoryTests.swift -o /tmp/ordered-onboarding-tests/checks
/tmp/ordered-onboarding-tests/checks /tmp/ordered-onboarding-tests/Model.mom
```

These checks use an in-memory store to verify advancing through every category writes nothing until onboarding finishes, repeated finishes do not duplicate records, empty selections create nothing, selected defaults and custom events retain their display order and category relationship, deselected events are excluded, adding creates no completion history, and revisiting the completed step creates no duplicates.

Manual UI check: on a fresh launch, verify onboarding opens directly on Morning with no progress bar, Welcome page, or Projects page. Verify all five categories appear in order, with a three-column grid and Custom Event always last. Tap a suggestion twice to check Added!/Add and Create Category/Skip toggle together. Add a custom name and emoji; verify it appears selected before Custom Event. Cancel another custom event and confirm nothing is added. Create one category and skip another, then finish onboarding and confirm only the created category and selected events appear in Library and Quick Finish, unfinished. Check scrolling on a small device and with larger text; verify each new category starts scrolled to the top. Use Back between categories and from the privacy page; selections and custom events should remain intact, and Back should be disabled on Morning. Skip every category and verify the final Skip stays on Food with an explanation that at least one event in a category is required. Use Back to select a default or custom event, then verify continuation succeeds.


Tutorial interaction and explanation checks:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swiftc -module-cache-path /tmp/ordered-tutorial-module-cache Ordered/ViewModel/AppTutorial.swift Tests/AppTutorialTests.swift -o /tmp/ordered-tutorial-tests
/tmp/ordered-tutorial-tests
```

Verify the user finishes the highlighted event, opens the rectangle tab, and deletes only the practice completion. After opening Library, tapping anywhere should explain the category plus, highlight the existing category, automatically open its editor to show Create Event, and dismiss the editor without saving. Open Stats, then tap anywhere for the pin and unpin explanations and to finish at the ending. Confirm the tutorial creates no additional categories or events and changes no pin preferences. Tapping outside the highlight must not bypass the actual finish or delete steps. Verify each text box sits beside its highlight with a small gap, stays within the screen, and remains readable with larger text. Verify there is no Skip Tutorial button or tap-to-continue hint. The category editor must not be dismissible by swiping during the tutorial. The original Library event must remain after deleting its practice completion.

Order-switch expansion check: minimize categories in Home, including a finished category, then select another saved order or All Events. Only minimized unfinished categories in the selected order should expand immediately, including Uncategorized; finished categories should remain as completed pills. Repeat with a search active, then clear it to verify categories outside the search results were expanded too. Minimize a category again and relaunch without switching orders to confirm its saved state still restores. Adding a new order should also expand only its minimized unfinished categories; renaming the current order should not reset them. The explicit Expand all menu action should still expand every visible category, including finished categories.

Daily hide/unhide database checks:

```sh
mkdir -p /tmp/ordered-daily-visibility-models
/Applications/Xcode.app/Contents/Developer/usr/bin/momc Ordered/Ordered.xcdatamodeld/DailyEventVisibility.xcdatamodel /tmp/ordered-daily-visibility-models/Old.mom
/Applications/Xcode.app/Contents/Developer/usr/bin/momc Ordered/Ordered.xcdatamodeld/DailyVisibilityOverride.xcdatamodel /tmp/ordered-daily-visibility-models/New.mom
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swiftc -parse-as-library -module-cache-path /tmp/ordered-event-creation-module-cache Tests/DailyEventVisibilityTests.swift -o /tmp/ordered-daily-visibility-tests
/tmp/ordered-daily-visibility-tests /tmp/ordered-daily-visibility-models/Old.mom /tmp/ordered-daily-visibility-models/New.mom
```

UI check: open a category containing both a daily-hidden event and an order-hidden event. Both should show eye.slash buttons in the pop-up. Tap either button and verify the event reappears on Home, its eye.slash clears in the pop-up, and no completion is recorded. Relaunch and verify restored visibility lasts for today. The next app day, the order-hidden event should again follow the order's visibility settings. Hiding a restored event again through hide mode must take effect immediately. Restoring an unfinished event must remove the category's completed status.

Automatic saving UI checks: edit an existing category name and icon, add/remove an event, and reorder events. Close with Done and repeat using sheet dismissal; relaunch to verify persistence. Rename an existing event and change its emoji, close it, and relaunch. In Quick Finish, rename a custom order, change category/event visibility, and reorder both; verify changes survive closing, switching orders, and relaunching. Repeat reordering in All Events and verify Library shares the new order. Empty category/event names must not replace the last valid saved name or allow closing until corrected. Failed saves must keep the editor open with edits available for retry. Opening editors or advancing the tutorial without editing must create no records. New categories retain Create; new reusable events retain Create and one-time events retain Add. Canceling those creation drafts must create nothing. Swipe-delete confirmation must still preserve the event on Cancel and deactivate it on Delete.

Rectangle calendar swipe check: drag the week left/right and verify dates follow the finger, then slide into the adjacent week. A short drag must snap back without changing the selected date. A completed swipe must keep the same weekday selected, update the month header and completion list, and share the newly selected day. Repeat across month/year boundaries and after many consecutive swipes. Today and the date picker must return to the correct week; date buttons must still work. With Reduce Motion enabled, week selection must work without the settling animation. VoiceOver Previous week/Next week actions must still change weeks.
