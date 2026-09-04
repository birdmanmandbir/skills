---
name: shizuku-adb
description: Start or check Shizuku on Neil's current USB-connected Pixel 7a after a reboot.
---

# Shizuku via ADB

Use raw ADB with this fixed device and installed Shizuku build:

- Serial: `32131JEHN00865`
- Starter: `/data/app/~~JtxT73gKKCE9EBiwgalN3A==/moe.shizuku.privileged.api-3i4PE5JspOjzc4pzydKldQ==/lib/arm64/libshizuku.so`

## Start

1. Confirm `32131JEHN00865` is in `device` state with `adb devices -l`. If it is absent or unauthorized, report that condition and stop.
2. Check for `shizuku_server` with:

   ```bash
   adb -s 32131JEHN00865 shell 'ps -A | grep shizuku_server'
   ```

3. If it is not running, start it with:

   ```bash
   adb -s 32131JEHN00865 shell /data/app/~~JtxT73gKKCE9EBiwgalN3A==/moe.shizuku.privileged.api-3i4PE5JspOjzc4pzydKldQ==/lib/arm64/libshizuku.so
   ```

4. Run the process check again. Completion requires a live `shizuku_server` process; report the starter's stderr if verification fails.

The fixed starter path assumes Shizuku remains at the current installed version. A Shizuku update or reinstall invalidates this skill and requires reading the new command from Shizuku's **View command** screen.
