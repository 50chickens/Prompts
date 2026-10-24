# Avalonia patterns

Rules here apply to Avalonia desktop applications and their tests. Language and general .NET rules live in [csharp.md](./csharp.md) and are not repeated here. Test-shape rules live in [csharp.md](./csharp.md).

## Threading

A view model must never run file, network or scan work on the UI thread. Every such call goes through `Task.Run` at the view model boundary, so the guarantee holds whatever the injected service does: `await Task.Run(() => service.DoAsync(...), cancellationToken)`. Await the wrapper, do not fire and forget it.

An infrastructure service whose name ends in Async must do its own work off the calling thread, and `Task.FromResult` after synchronous IO is a lie that freezes whatever thread called it. The view model wrapper and the honest service both earn their place: the wrapper protects the UI from any implementation, the service keeps its contract.

Progress reported from a worker thread goes through an `IProgress<T>` created on the UI thread, which posts to the dispatcher. Capture the `SynchronizationContext` when the reporter is constructed, never when a callback fires.

Work that must finish the job (recording per-item state, building the result) runs in one reconciliation pass after the awaited copy returns, and that pass runs off the UI thread as well. Apply its outcome to the observable collections in one batched notification rather than one per item, because a hundred thousand items is a hundred thousand property changes.

Loaded settings are applied behind a guard flag. Without it, assigning each loaded value raises the change handlers that persist settings, and startup writes the file back once per property.

Persisting settings from a property setter needs a writer that owns a background drain and coalesces to the latest value. The setter must never touch the file system.

## Bindings

A `Button` does not take `IsEnabled` from its command's `CanExecute`, so bind `IsEnabled` to a view model property as well as binding the command.

Every computed `Can*` property needs an explicit change notification for each input it depends on (`[NotifyPropertyChangedFor(nameof(CanCopy))]`). A control bound to `IsEnabled` through a computed property keeps its initial state otherwise, which looks like a broken button rather than a missing notification.

Do not two-way bind both `Text` and `SelectedItem` of an editable `ComboBox` to the same property. When the items source is refreshed the selection resets and writes `null` back into the property, clearing the user's value. Bind `Text` and handle `SelectionChanged` for the dropdown, and refresh a history list by inserting rather than clearing.

Show enum values through a converter that supplies readable labels, and keep compiled bindings elsewhere. An item template over raw enum values needs `x:CompileBindings="False"` on the control, because the item has no data type to compile against.

Locking inputs for the duration of a job means binding the lock property on the container of the controls, not on each control. A child control's `IsEnabled` reports the value set on it, not the inherited effective state.

A service that needs the window (a folder picker that uses `StorageProvider`) can take `Func<Window>` so the container can construct it before the window exists, which breaks the cycle without a service locator.

## Compositions

Register a view model that only a UI consumes in the UI's composition root, not in the shared Application layer container. Otherwise a console app's container must supply UI-only dependencies and its dependency-resolver test stops meaning anything.

A window built by a DI container has no parameterless constructor, so the XAML compiler warns AVLN3001 for the whole file. Suppress it in the project file; adding an empty constructor to silence it changes nothing at runtime and hides the real requirement.

## Headless UI tests

The headless test application must apply the same theme as production (`Styles.Add(new FluentTheme())`). Without a theme the controls are untemplated: the window renders naked text, and synthetic pointer clicks silently never reach the buttons, which looks exactly like a layout bug.

Send a pointer click to a point in the control's own coordinate space. `Bounds` is parent-relative, so translate `new Point(Bounds.Width / 2, Bounds.Height / 2)`; passing `Bounds.Center` clicks the wrong place for every control that is not at its parent's origin.

Raising `Button.ClickEvent` by hand runs a code-behind `Click` handler but does not execute the button's bound command, so click command-bound buttons through the pointer.

Awaiting inside an `[AvaloniaTest]` body deadlocks, because the body runs on the Avalonia thread and the continuation can only be pumped by the same thread. Drive the UI synchronously and flush queued work with `Dispatcher.UIThread.RunJobs()`.

Once the work behind a button runs off the UI thread, a click returns before the job does, so a fixed `RunJobs()` is a race. Wait for a condition: pump `RunJobs()` in a loop with a short sleep until the expected state appears or a bounded timeout expires, then assert on the final state.

Assert that work really left the UI thread by having the test double record `Environment.CurrentManagedThreadId` and comparing it with the thread id of the test body. A blocking double (a `ManualResetEventSlim` the test releases) proves the UI thread stays usable while the work runs: pausing or cancelling from the UI still works mid-job.

`CaptureRenderedFrame()` needs `UseSkia()` with `UseHeadlessDrawing = false`, and it is the fastest way to see that a test app is missing its theme.

When a suite hangs and prints nothing, run the smallest filter with `--logger "console;verbosity=normal"`. `--blame-hang --blame-hang-timeout 90s` names the test that hung instead of leaving you to guess.

Killing a `dotnet test` run leaves a `testhost` process holding the test dll, so the next build fails with MSB3026/MSB3027 "the file is locked by testhost". Find that process by id and stop it, rather than rebuilding and re-reading the same error.

## Test composition

A UI app service injection from tests: set a static `Func<IService>? ServiceProvider` property on `App` before the test fixture runs, in the constructor. The app calls it at startup. Do not use a null-safe operator on `ServiceProvider`; tests must set it explicitly so missing wiring is caught immediately.

A product namespace ending in `.Application` shadows the `Application` type from Avalonia or WPF inside that product: `class App : Application` resolves to the namespace and fails with CS0118. Fully qualify the base type (`Avalonia.Application`).

Rebuilding an observable tree on every change of an input multiplies the lazy loads behind it. Reuse the existing nodes when the input is unchanged, and assert the loader count in a test, which is the cheapest way to notice the duplication.
A button that a binding enables after the window is shown can report `IsEnabled` true while its cached `IsEffectivelyEnabled` is still false, and synthetic pointer input silently skips it. Hit testing follows the cached value, so the click does nothing and the test fails as if the command were unwired. Assert `IsEnabled` and `Command.CanExecute`, then either click once the cached value has caught up or invoke the command directly for that control.

Headless windows accumulate across tests in one process, and a closed window is not always enough to release the platform's active top-level. Keep a field for the window, close it in the teardown, and assert on the window the test created rather than on whatever `FindControl` happens to return.
A TreeView cannot filter its items by removing them without losing expansion state and lazy-loaded children. Bind `IsVisible` on the item container from a style against a node property, and compute that property bottom-up so a node stays visible when any descendant matches.

Progress that belongs to a list of in-flight items goes in an expander at the bottom of the window, with the whole-run bar beside it, not in the top section where it competes with the controls the user is still adjusting. Keep the expander header carrying the count so a collapsed expander still reports that work is happening.

Two ellipses with inverse `IsVisible` bindings are the cheapest way to show one status dot that means different things before and after a comparison pass. One is bound to the copy state, the other to the comparison state, and a node flag decides which one renders.
