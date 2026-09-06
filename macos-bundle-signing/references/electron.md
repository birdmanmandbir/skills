# Electron bundles

Read this reference when the target contains Electron Framework, Helper apps, XPC services, or dyld reports that the process and mapped file have different Team IDs.

## Model the code graph

An Electron `.app` is a graph of independently signed and independently launched code, commonly including:

- the main app executable;
- `Electron Framework.framework` and its helper executables;
- `Helper`, `Helper (Renderer)`, `Helper (GPU)`, and `Helper (Plugin)` app bundles;
- crash handlers, XPC services, native `.node` modules, dylibs, and other frameworks.

Inventory the actual bundle. Do not assume every Electron version has the same graph. Inspect each code object's signature and entitlements before signing it.

Prefer the project's Electron packaging signer, such as its configured `@electron/osx-sign` flow, when available. For an already-built local patch, reproduce that signing structure explicitly rather than applying one outer signature.

## Library validation

With Hardened Runtime, a process normally loads code from a compatible signing identity. These states are different:

- Every nested signature is cryptographically valid.
- The process is permitted to map a particular nested framework at runtime.

`codesign --verify --deep` proves the first state, not the second. A mixed Developer ID/ad-hoc bundle can fail immediately. An all-ad-hoc bundle can also fail when independently signed processes retain library validation and have no common Apple Team ID.

Prefer signing every component with the same proper identity. For a local ad-hoc test build where that identity is unavailable, `com.apple.security.cs.disable-library-validation=true` may be necessary on **each process that loads the differently identified framework**: the main app and relevant Helpers. Adding it only to the outer app does not affect Helper processes.

This entitlement weakens a runtime security boundary. Add it narrowly, disclose it, and keep the build local. Preserve every process's other entitlements independently; for example, Renderer/GPU Helpers may need JIT entitlements while a Plugin Helper may already disable library validation.

## Signing order

Use the actual dependency graph, generally:

1. leaf native modules, dylibs, crash handlers, and inner framework executables;
2. frameworks and XPC services;
3. each Helper app with its own entitlement file;
4. the outer app with its own entitlement file.

Changing a nested signature invalidates the seal of its containers, so sign containers again on the way outward. Stop all Electron processes before each signing attempt.

## Runtime diagnosis

Run the main executable directly and retain its exit status. A GUI alert such as “check with the developer” hides the useful dyld reason.

For `mapping process and mapped file (non-platform) have different Team IDs`:

1. Identify the referenced process and mapped file from the dyld message.
2. Inspect both Team IDs, runtime flags, and entitlements.
3. Change only the boundary named by the failure.
4. Re-sign its containing bundles outward.
5. Re-run the same direct-launch command.

When the main process starts but Renderer, GPU, or Network Service crashes, apply the same inspection to the named Helper. The app is not healthy until expected Helpers survive and a window renders.

Static verification followed by direct launch and a rendered-window smoke check is the minimum reliable feedback loop.
