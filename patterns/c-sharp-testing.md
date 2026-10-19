
## C# Unit & Integration Testing guidelines.
Use NUnit and NSubstitute for testing frameworks. 
use [TestCases] where possible.
Don't use the word mock/fake/test/dummy in the code anywhere - even in unit tests. for places where we need to use a mock there should be an abstraction where we create a minimimal implementatio of the abstraction in the unit test and use this instead. see TestUtils.BuildTestConfiguration() for an example. we don't create a full configuration class - we have a minimal implementation of the interface in the unit test and use this instead.

Create a DependencyResolverTest unit test to verify the DI container can resolve all services. make this generic so that it if we add additional dependencies that will automatically be in scope to ensure they can be resolved.
Use UseNunitTestContext to create a _log and then use if required - eg _log.Info("testing for ....")
Follow the project's own conventions first, then common C# conventions.
Keep naming, formatting, and project structure consistent.
Tests must use primary code paths only.
No timing-dependent assertions. No Stopwatch usage. No Task.Delay assertions in tests.
Use async tests unless code path is not async.
Mock all external dependencies: file I/O, network.
Tests should be deterministic and fast.
Record test metadata in datestamped JSON files with test name, duration, status, environment. DO NOT use CSV.
Don't create unit tests that test for DoesNotThrow(). This are meaningless tests. When testing a method we should be testing the return value which represents the main function of the method. 
DON'T add interfaces/abstractions unless used for external dependencies or testing.
Don't wrap existing abstractions.
Keep names consistent. 
Don't add unused methods/params.
When fixing one method, check siblings for the same issue.
Reuse existing methods.

## Avalonia headless journey tests.

The test body runs on the Avalonia thread. Awaiting anything that resumes on that thread deadlocks and the run hangs with no test output, so drive the UI synchronously and flush queued work with Dispatcher.UIThread.RunJobs() instead of awaiting a command's ExecutionTask.
The test application must apply the same theme as production (Styles.Add(new FluentTheme()) in the test Application, plus any app styles). Without a theme the controls render untemplated: the window draws no chrome and part of the input does not reach the controls, so a button that works in the app silently ignores a synthetic click.
Send a pointer click to a point in the control's own coordinate space. Bounds is parent-relative, so translate new Point(Bounds.Width / 2, Bounds.Height / 2); passing Bounds.Center clicks the wrong place for every control that is not at its parent's origin.
Raising Button.ClickEvent by hand does run a code-behind Click handler, but it does not execute the button's bound Command; a command runs only from the button's own click handling, so click those buttons through the pointer.
A Button does not take IsEnabled from its command's CanExecute, so bind IsEnabled to a view model property as well as binding the command.
CaptureRenderedFrame requires UseSkia() and UseHeadlessDrawing = false on the headless platform options.


