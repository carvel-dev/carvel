---
aliases: [/ytt/docs/latest/known-limitations]
title: Known Limitations
---

- YAML anchors and templating directive for the same YAML node are not supported.

    ```yaml
    first: &content #@ 123
    second: *content
    ```
    `second` key-value pair will _not_ contain 123 since YAML anchors are resolved before ytt evaluates templating directives.
