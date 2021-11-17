---
title: FAQ
---

## Can I configure the number of retries imgpkg does when a temporary error occur while connecting to the registry?

Yes, starting in version 0.24.0 the flag `--registry-retry-count` was added. This flag allows the user to define how
many times `imgpkg` repeat the request until it stops.

The requests are not immediately sent, it uses an exponential wait time.
