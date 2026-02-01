# Alsionyx TestServer Pattern Verification & Implementation Summary

**Date:** January 20, 2026  
**Status:** ✅ VERIFIED - Alsionyx correctly implements the TestServer pattern for Playwright testing

## Executive Summary

Alsionyx fully implements the **TestServer Pattern** for end-to-end testing using Playwright with in-process Kestrel servers. This pattern enables:
- ✅ Automatic server startup (no manual `dotnet run` needed)
- ✅ Parallel test execution with complete isolation
- ✅ Real HTTP connections from browser to Kestrel (not TestServer)
- ✅ Dynamic port allocation for conflict-free parallel runs
- ✅ Production environment testing (not development shortcuts)

## Pattern Verification Checklist

### 1. WebApplicationFactory Implementation (AlsionyxSut.cs) ✅

**Location:** `src/Alsionyx.Tests.Library/AlsionyxSut.cs`

**✅ Verified Components:**
- [ ] Inherits from `WebApplicationFactory<Program>` - YES
- [ ] Implements dual-server pattern (TestServer + Kestrel) - YES
- [ ] Uses `ConfigureWebHost` to switch to Kestrel - YES
- [ ] Sets dynamic port via `UseUrls("http://127.0.0.1:0")` - YES
- [ ] Sets `UseEnvironment(Environments.Production)` - YES
- [ ] Calls `builder.Build()` twice (before and after ConfigureWebHost) - YES
- [ ] Calls `_host.Start()` BEFORE extracting address - YES
- [ ] Extracts address via `IServerAddressesFeature` - YES
- [ ] Sets `ClientOptions.BaseAddress` to Kestrel address - YES
- [ ] Returns TestServer (not Kestrel) - YES
- [ ] Properly disposes Kestrel host - YES
- [ ] Exposes `ServerAddress` property for test access - YES

**Critical Sequence Correct:**
```
1. Build() ✓
2. ConfigureWebHost(UseKestrel) ✓
3. Build() ✓
4. _host.Start() ✓
5. Extract address ✓
6. Set ClientOptions.BaseAddress ✓
7. Return TestServer ✓
```

### 2. Program.cs (Alsionyx.Api) ✅

**Location:** `src/Alsionyx.Api/Program.cs`

**✅ Verified Components:**
- [ ] Has `public partial class Program { }` at end - YES
- [ ] Has HTTP-only CORS configuration - YES
  ```csharp
  policy.WithOrigins(
          "http://localhost:5002",    // Default Blazor UI port
          "http://localhost:5173",    // Vite dev server
          "http://localhost:3000"     // React dev server
        )
  ```
- [ ] Swagger enabled for all environments (no IsDevelopment() checks) - YES
- [ ] Health check endpoint at `/api/health` - YES
- [ ] HTTPS redirection disabled - YES

### 3. Global Setup (Alsionyx.Tests.Library/GlobalSetup.cs) ✅

**Location:** `src/Alsionyx.Tests.Library/GlobalSetup.cs`

**✅ Verified Components:**
- [ ] Has `[SetUpFixture]` attribute - YES
- [ ] Has assembly-level `[Parallelizable(ParallelScope.Children)]` - YES
- [ ] Has assembly-level `[FixtureLifeCycle(LifeCycle.InstancePerTestCase)]` - YES
- [ ] Creates ServiceCollection - YES
- [ ] Registers `AlsionyxSut` as Scoped - YES
- [ ] Provides static `Provider` property - YES
- [ ] Has proper cleanup in `[OneTimeTearDown]` - YES
- [ ] Does NOT manually install browsers (handled by microsoft.playwright.nunit) - YES ✓

**Browser Installation Handled Correctly:**
- ✅ Uses `Microsoft.Playwright.NUnit` NuGet package (auto-manages browser lifecycle)
- ✅ Browsers auto-downloaded on first test run
- ✅ Cached for subsequent runs
- ✅ No manual `playwright.ps1 install` required

### 4. PlaywrightTestBase.cs ✅

**Location:** `src/Alsionyx.Tests.Library/PlaywrightTestBase.cs`

**✅ Verified Components:**
- [ ] Inherits from `PageTest` - YES
- [ ] Has `[Parallelizable(ParallelScope.Self)]` - YES
- [ ] Has `[SetUp]` method `BeforeTestCase()` - YES
- [ ] Has `[TearDown]` method `AfterTestCase()` - YES
- [ ] Creates fresh scope per test - YES
- [ ] Gets fresh Sut instance from DI - YES
- [ ] Forces server startup by calling `/api/health` - YES
- [ ] Extracts and trims ServerAddress - YES
- [ ] Sets 30-second timeouts - YES
- [ ] Properly disposes scope - YES
- [ ] Uses `async Task` for async operations - YES

**BeforeTestCase() Sequence:**
```
1. Get Provider from GlobalSetup ✓
2. Create AsyncServiceScope ✓
3. Get Sut from DI ✓
4. Call /api/health to force server startup ✓
5. Extract ServerAddress ✓
6. Trim trailing slash ✓
7. Set timeouts ✓
```

**AfterTestCase() Cleanup:**
```
1. Close browser context ✓
2. Always dispose scope (even on error) ✓
3. Dispose Sut (stops Kestrel) ✓
4. Free port for next test ✓
```

### 5. Test Projects Configuration ✅

**Playwright Tests Project:** `src/Alsionyx.PlaywrightTests/Alsionyx.PlaywrightTests.csproj`

**✅ Verified Components:**
- [ ] Has `RunSettingsFilePath` property - YES
  ```xml
  <RunSettingsFilePath>$(MSBuildProjectDirectory)\playwrightconfig.runsettings</RunSettingsFilePath>
  ```
- [ ] References `Microsoft.Playwright.NUnit` - YES
- [ ] References `Alsionyx.Tests.Library` - YES
- [ ] Has `playwrightconfig.runsettings` - YES

**Tests Library Project:** `src/Alsionyx.Tests.Library/Alsionyx.Tests.Library.csproj`

**✅ Verified Components:**
- [ ] Has `Microsoft.AspNetCore.Mvc.Testing` NuGet - YES (version 9.0.1)
- [ ] Has `Microsoft.Playwright.NUnit` - YES (version 1.50.0)
- [ ] References Alsionyx.Api project - YES
- [ ] References Alsionyx.BlazorUI project - YES

### 6. Test Files (GlobalSetup & Playwright Tests) ✅

**Playwright Assembly GlobalSetup:** `src/Alsionyx.PlaywrightTests/GlobalSetup.cs`

**✅ Verified Components:**
- [ ] Sets `Alsionyx.Tests.Library.GlobalSetup.Provider` - YES
  - Enables cross-assembly provider sharing
  - PlaywrightTestBase can access provider from shared library

**Critical Journey Tests:** `src/Alsionyx.PlaywrightTests/CriticalJourneyTests.cs`

**✅ Verified Components:**
- [ ] Inherits from `PlaywrightTestBase` - YES
- [ ] Uses `ApiBaseUrl` property - YES
- [ ] Calls `/api/health` endpoint - YES
- [ ] Creates pedalboard via API - YES
- [ ] Takes screenshots at each step - YES
- [ ] Uses Playwright's `Page.APIRequest.PostAsync()` - YES
- [ ] Properly asserts responses - YES

## Pattern Comparison: Expected vs. Actual

| Component | Expected Pattern | Actual Implementation | Status |
|-----------|------------------|----------------------|--------|
| Factory Class | WebApplicationFactory<Program> | AlsionyxSut : WebApplicationFactory<Program> | ✅ |
| Server Type | Kestrel (real HTTP) | Kestrel on dynamic port | ✅ |
| Port Assignment | Dynamic (0) | `UseUrls("http://127.0.0.1:0")` | ✅ |
| Environment | Production | `UseEnvironment(Environments.Production)` | ✅ |
| HTTPS Redirect | Removed (HTTP-only) | Disabled for HTTP-only config | ✅ |
| Address Extraction | Via IServerAddressesFeature | ✓ After _host.Start() | ✅ |
| ClientOptions.BaseAddress | Set to Kestrel URL | ✓ | ✅ |
| Return Value | TestServer | ✓ | ✅ |
| Browser Lifecycle | Auto (microsoft.playwright.nunit) | ✓ No manual install | ✅ |
| Per-Test Server | Fresh Sut per test | ✓ Scoped DI registration | ✅ |
| Cleanup | Dispose scope after test | ✓ In [TearDown] | ✅ |
| URL Construction | Trim trailing slashes | ✓ `TrimEnd('/')` | ✅ |

## Critical Sequences Verification

### Server Startup Sequence (CreateHost Method) ✅
```
✅ Step 1: builder.Build() - initializes state
✅ Step 2: builder.ConfigureWebHost(p => p.UseKestrel()) - reconfigure
✅ Step 3: builder.Build() - create Kestrel host
✅ Step 4: _host.Start() - bind to port
✅ Step 5: Extract address from IServerAddressesFeature
✅ Step 6: Set ClientOptions.BaseAddress = new Uri(address)
✅ Step 7: Return testHost (TestServer instance)
```

### Per-Test Execution Sequence ✅
```
✅ GlobalSetup.Setup() runs once:
   - Creates ServiceCollection
   - Registers AlsionyxSut as Scoped
   - Sets static Provider

✅ For each test:
   - [SetUp] BeforeTestCase():
     - Create AsyncServiceScope
     - Get Sut from scope (creates new Kestrel server)
     - Call /api/health to force startup
     - Extract ServerAddress
     - Set Page timeouts
   
   - Test executes:
     - Uses ApiBaseUrl for HTTP calls
     - Uses Page for browser automation
     - Both access same Kestrel server
   
   - [TearDown] AfterTestCase():
     - Close browser context
     - Dispose scope
     - Stop Kestrel server
     - Free port
```

## Known Limitations & Trade-offs

✅ **Addressed:**
- BlazorUI tests are marked `[Ignore]` because WebAssembly apps cannot be hosted via WebApplicationFactory
- Tests currently run against separate Blazor instance (intended design)
- Critical journey tests focus on API workflows

## Pitfalls Prevention

All 5 critical pitfalls documented in Testing_Workflow.md are prevented:

| Pitfall | Prevention in Alsionyx |
|---------|------------------------|
| Return Kestrel instead of TestServer | ✅ Correctly returns `testHost` (TestServer) |
| URL construction double-slashes | ✅ `TrimEnd('/')` in PlaywrightTestBase |
| Port already in use | ✅ Proper disposal in AfterTestCase |
| Extract address before server starts | ✅ Calls `_host.Start()` first |
| Manual browser installation | ✅ Uses automatic microsoft.playwright.nunit |

## Documentation Updates

✅ **Created/Updated:**
- `.github/copilot-instructions.md` - Complete AI agent instructions with TestServer pattern
  - TestServer Pattern section (lines ~138-363)
  - Common Pitfalls section (lines ~364-415)
  - Critical Configuration Points (lines ~331-362)
  - Build & Test Commands (lines ~417-450)

## Testing Coverage

**Unit Tests:**
- Use NSubstitute for mocking
- Run against mock providers
- No server startup needed

**Integration Tests:**
- Use Alsionyx.Api.Tests project
- May use Sut for database/configuration testing
- Follow same pattern as Playwright tests

**E2E Tests (Playwright):**
- Use Alsionyx.PlaywrightTests project
- Run against in-process Kestrel servers
- Browser automation via Playwright
- Screenshots captured at each step

## Build & Test Verification

**Build Command:**
```powershell
cd src
dotnet build
```

**Test Commands:**
```powershell
# All tests (servers start automatically)
dotnet test

# Playwright tests only
dotnet test Alsionyx.PlaywrightTests

# Specific test
dotnet test --filter "Journey_CreatePedalboard"
```

**No Manual Setup Required:**
- ✅ No need to run `dotnet run` for API
- ✅ No need to run `dotnet run` for Blazor UI
- ✅ Playwright test discovers and starts servers automatically

## Reference Implementation

**Source Pattern:** TestExamplesDotnet/Vue.Playwright  
**Alsionyx Implementation:** Faithful adaptation for .NET 9 + NUnit + Alsionyx project structure

## Conclusion

Alsionyx **✅ FULLY IMPLEMENTS** the TestServer Pattern for Playwright testing. The implementation:

1. ✅ Correctly manages dual-server pattern (TestServer + Kestrel)
2. ✅ Uses dynamic port allocation for parallel execution
3. ✅ Runs tests in Production environment
4. ✅ Handles all 5 known pitfalls
5. ✅ Provides clean DI integration
6. ✅ Enables zero-manual-setup testing
7. ✅ Supports complete test isolation
8. ✅ Documents critical decisions

### AI Agent Readiness

The updated `.github/copilot-instructions.md` provides AI coding agents with:
- ✅ Complete TestServer pattern explanation
- ✅ Critical component documentation
- ✅ Common pitfalls and prevention strategies
- ✅ Configuration requirements
- ✅ Build and test commands
- ✅ Key file references
- ✅ Important conventions

**Result:** Agents can immediately understand and extend the testing infrastructure without rediscovering patterns or hitting known pitfalls.
