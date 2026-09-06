---
name: macos-bundle-signing
description: Safely patch, ad-hoc sign, restore, or diagnose an existing macOS .app bundle. Use for modified app resources, codesign or Gatekeeper failures, dyld Team ID errors, Hardened Runtime library validation, Electron Helpers, and App Management permission failures; not for an ordinary unmodified app installation.
---

# macOS Bundle Signing

Treat a signed `.app` as one integrity unit. A successful `codesign --verify` is a static result, not proof that dyld can load its frameworks or that the app runs.

## Establish the boundary

1. Resolve the exact `.app`, executable, version, architecture, owner, running processes, and intended modified files.
2. Record hashes of every file the patch will replace. Verify supplied archives and inspect their paths and scripts before extraction or execution.
3. Inspect the current signature, Team ID, runtime flags, designated requirement, and entitlements before mutation.
4. Prefer the repository's maintained patch/signing script when it has exact version and hash gates. Treat its success message as provisional until runtime verification.
5. Quit the app and its Helpers. Refuse to patch an unexpected version or hash.

Use private temporary storage for signature dumps and extracted artifacts. Keep credentials, application data, and identifiers that are unrelated to signing out of captured output.

## Make rollback real

Preserve a complete original `.app` outside the bundle with metadata intact, or prove that the exact official installer is available. A backup of only the modified resource can restore its bytes but cannot restore the original Developer ID signature after the outer bundle is re-signed.

Never overwrite an existing backup unless its provenance and hashes are verified. State whether rollback restores original content only or the original trusted signature as well.

## Choose a signing strategy

Prefer, in order:

1. The project's documented signing pipeline and matching Apple-issued identity.
2. A project-specific script that explicitly signs every nested code object in dependency order.
3. Ad-hoc signing for a local test build, with the trust and library-validation consequences disclosed.

Apple Silicon executables still require a valid code signature. Removing signatures entirely is not a workable substitute for consistent signing.

Preserve each code object's own entitlements. Do not copy the main app's entitlement set onto every Helper. Add an entitlement only to the processes that require it.

Sign nested code from the leaves outward, then sign the outer app last. Use `--deep` for verification and inventory assistance, not as the sole signing plan: it can leave a bundle whose individual signatures verify while runtime library validation still fails.

For Electron bundles or a dyld `different Team IDs` failure, read [references/electron.md](references/electron.md).

## Respect macOS authorization

`sudo` and App Management are separate gates. If modifying `/Applications/*.app` returns `Operation not permitted` even with administrator privileges, have the user grant their preferred terminal application **System Settings → Privacy & Security → App Management**.

Treat authorization as the fix. Do not bypass TCC by stripping security metadata or broadly changing ownership and permissions.

### Hand privileged mutation to the user

For any mutation that needs `sudo`, administrator authentication, or App Management, prepare an auditable script or exact command for the user to run in their already-authorized terminal. Put preflight checks, narrowly scoped targets, failure stops, backup behavior, signing steps, and post-sign verification in the script. Show the script path and invocation, then stop at that boundary.

After the user returns its output, resume with unprivileged, read-only verification and runtime checks. Never open or drive Terminal, inject commands into a terminal window, invoke an AppleScript administrator prompt, or attempt to observe or handle the user's password.

## Verify the observable outcome

Complete all applicable checks:

1. Re-hash the patched files and rollback artifact.
2. Run `codesign --verify --deep --strict --verbose=2`.
3. Re-inspect signature type, Team ID, runtime flags, and entitlements on the outer app and representative nested code, including every distinct Helper role.
4. Launch the main executable directly once so dyld errors and exit status are observable.
5. Launch the `.app` normally, confirm the main process and expected Helpers remain alive, and perform the smallest relevant functional smoke check.
6. If launch fails, capture the exact runtime boundary before changing the signing plan.

The task is complete only when hashes and static signatures pass, the app survives a real launch, and the patched behavior is exercised or the remaining functional check is explicitly handed to the user.

## Restore

Quit all app processes before restoration. Prefer restoring the complete original `.app` or reinstalling the exact official build when the goal is to regain its Developer ID trust. Restore a resource-only backup only when an ad-hoc-signed restored app is acceptable.

After restoration, verify the restored hashes, signature identity, and real launch. Remove only temporary artifacts created for the task; retain the validated rollback artifact until the user no longer needs it.
