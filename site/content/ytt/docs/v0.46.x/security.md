---

title: Security
---

## Vulnerability Disclosure

If you believe you have found a security issue in `ytt`, please privately and responsibly disclose it by following the directions in our [security policy](/shared/docs/latest/security-policy).

## Attack Vectors

This section is a work-in-progress...

- malicious template input
  - input tries to exhaust cpu/mem/disk resources
    - A: how does it affect go-yaml? ... https://en.wikipedia.org/wiki/Billion_laughs_attack
  - input tries to use YAML tagging to initialize custom objects (std yaml concern)
    - A: TBD

- malicious template code
  - code tries to load file contents from sensitive locations
    - A: templating is constrained to seeing only files explicitly specified by the user via -f flag, and does not follow symlinks. Unless user is tricked to provide sensitive files as input, template code is not able to access it. In other words, template runtime does not have facilities to access arbitrary filesystem locations.
  - code tries to exfiltrate data over network
    - A: template runtime does not have facilities to access network.
  - code tries to exhaust cpu/mem/disk resources
    - A: there are currently no resource constraints set by ytt itself for cpu/mem/disk. currently cpu can be pegged at 100% via an infinite loop. function recursion is also possible; however, it will be contstrained by Go stack space (and will exit the program).
  - code tries to produce YAML that exhausts resources
    - A: TBD
  - meltdown/spectre style attacks
    - A: TBD

- CLI output directory
  - user is tricked to set --output-files flag to a sensitive filesystem location
    - A: template output is constrained to stdout or specified output directory via --output-files flag. if user is tricked to point --output-files flag to a sensitive filesystem location such as ~/.ssh/, attacker may be able to write templates (for example ~/.ssh/authorized_keys) that can be intepreted by the system as configuration/executable files.
