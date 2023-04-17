---
title: Coding Guidelines for Carvel
---

**Audience**: any contributor, especially new, whether internal/external, full-time/occasional

**Purpose**:
* Describe some current practices and aspirational directions
* OSS focus
* How to make changes
* How our development flow / process works
* How to understand and evolve our codebases

## General Mindset and Sensibilities
### Naming
* Consistent and descriptive, without abandoning golang’s terse style.
* Flag names should be nouns not verbs ( --warnings,  not --warn) 

### Modularity
* Each Carvel tool is modular and composable, with aggressively limited scope
* Within a codebase each file / package / “class” should be modular - each package is almost its own program that exposes an API, and [can be a unit of documentation.](https://github.com/carvel-dev/kapp-controller/blob/develop/pkg/fetch/doc.go)
    * At each layer, consider the API you’re exposing and the subset of responsibilities you’re abstracting.
    * Layered abstractions are often combined via dependency injection.
* Prefer to apply modularity at each level of the codebase so that each layer is sufficiently compact to fit in a developer’s head. (What fits in a developer’s head? [Seven plus or minus two](https://en.wikipedia.org/wiki/The_Magical_Number_Seven,_Plus_or_Minus_Two) items.) 
    * Extract code to functions when it’s not helpful to see those details at the current level, and when that will help pull the number of “code chunks” in the current function back down below 7 ± 2.
    * Don’t extract to functions when the detail doesn’t add complexity at the current level, especially if there’s &lt; 7 “code chunks” in the current level..

### Conformity
* Prefer to use tools or patterns that match prior art in the codebase.
    * Example: Order test variables [consistently](https://github.com/carvel-dev/ytt/blob/47d49cce99b3a2a9ba5197565bc6ff07367a216b/pkg/cmd/template/cmd_overlays_test.go#L24) [across](https://github.com/carvel-dev/ytt/blob/47d49cce99b3a2a9ba5197565bc6ff07367a216b/pkg/cmd/template/cmd_overlays_test.go#L76) [similar](https://github.com/carvel-dev/ytt/blob/47d49cce99b3a2a9ba5197565bc6ff07367a216b/pkg/cmd/template/cmd_overlays_test.go#L187) [tests](https://github.com/carvel-dev/ytt/blob/47d49cce99b3a2a9ba5197565bc6ff07367a216b/pkg/cmd/template/cmd_overlays_test.go#L261).
* However, value clarity and readability of the logic you’re working on over awkwardly forcing that code to conform to a pattern elsewhere in the codebase. (“Be different when you have a reason to be”) 

### DRY within domains
* We often strive for a “single point of truth” or single codepath to avoid paying the cost of the same complexity twice, and maximize maintainability.
* In different packages or domains, It’s fine for code to “rhyme”:  Some implementations are superficially similar but have fine-grained divergence, because they solve similar problems for distinct domains.
    * Example: kapp-controller’s App, PackageInstall, PackageRepository have similar reconcilers structs, those structs have methods with same names, but distinct implementations:
        * [App reconciler attach watches](https://github.com/carvel-dev/kapp-controller/blob/4b0307d377e429c00d8f5cf6499bf59989f71f44/pkg/app/reconciler.go#L43)
        * [PackageInstall reconciler attach watches](https://github.com/carvel-dev/kapp-controller/blob/4b0307d377e429c00d8f5cf6499bf59989f71f44/pkg/packageinstall/reconciler.go#L44)
        * [PackageRepository reconciler attach watches](https://github.com/carvel-dev/kapp-controller/blob/4b0307d377e429c00d8f5cf6499bf59989f71f44/pkg/pkgrepository/reconciler.go#L49)
* We’re especially tolerant of duplication in new/young code where we expect to learn and iterate.

### Structure
Developers should feel free to add more structure as complexity grows by making new files and subdirectories in both test and application code.

### Planning
* Prefer to balance speed, quality, and delivery in a way that considers the value and complexity of the feature, its edge cases, cost of failure: aim for the 80% of [the 80/20 split](https://en.wikipedia.org/wiki/Pareto_principle) to deliver iterative, incremental value quickly and often.
* Estimates are often noisy and probably low by a small factor.

### Golang specific concerns
* [Named Returns](https://tour.golang.org/basics/7): Prefer to avoid; use rarely and judiciously
    * Often these add burden to the reader
    * When returning multiple items of same type, especially in a short function, named returns can remove burden from the reader
* Expose crisp abstractions and intentional APIs by keeping scoping minimal. Prefer to use restricted scope such as private or receiver in situations like:
    * [Structs](https://github.com/carvel-dev/vendir/blob/f65c73335261488c3328c98c99ef123ceeee5def/pkg/vendir/config/resources.go#L17) used [only in their package](https://github.com/carvel-dev/vendir/blob/f65c73335261488c3328c98c99ef123ceeee5def/pkg/vendir/config/config.go#L38)
    * [Fields used only by receivers on the structs](https://github.com/carvel-dev/vendir/blob/f65c73335261488c3328c98c99ef123ceeee5def/pkg/vendir/fetch/imgpkgbundle/sync.go#L16)
    * [Methods used only locally](https://github.com/carvel-dev/kapp/blob/develop/pkg/kapp/app/preparation.go#L67)
    * [Methods on receivers](https://github.com/carvel-dev/imgpkg/blob/6cb2b71f01d15e640de28b04af84c2c9fb944238/pkg/imgpkg/bundle/bundle.go#L250-L252) (func doesn’t use receiver, but is scoped to the struct to indicate semantically some where/how/who of usage)
* Godocs:
    * Should impart more context or information than the name alone.
    * Note: older code may not already have godocs,  great to add docs as you learn what something does
* Prefer multi-line over single-line err check:
    * Prefer:
      ```
      err := foo()
      if err != nil { //…
      ```
    * Occasionally appropriate: (example: [highly indented guard clause](https://github.com/carvel-dev/ytt/blob/efbe80b11dd7039ced30a48a35a5e4572070d80e/pkg/template/compiled_template.go#139))
      ```
      if err := foo(); err != nil { //…
      ```
* Dependencies
    * are all vendored locally and version controlled
    * `go mod vendor; go mod tidy` are your friends; hack/build.sh runs them.
    * Prefer not to bump dependencies until necessary
        * We rarely want to hop onto the latest version with all its latest bugs :),  but we do want to patch CVEs
        * Value stability
    * Kubernetes versions
        * Kubernetes isn’t one thing from a go modules / deps perspective, but the many libraries of k8s do need to be kept on compatible versions
        * If you need to upgrade k8s deps,
            * You can use specific directives, one per each library, of the form:  `go get -u k8s.io/thing@v1.2.3` 
            * You can edit the go.mod file directly and then re-vendor.
    * Debugging
        * Because we vendor all our libraries, println style debugs can also be added to 3rd party source code.  However you must comment out the `go mod vendor` and `tidy` commands in hack/build.sh.

### K8s Controller-Specific Concerns: API Changes
* Adding fields to CRDs is not a breaking change; removing fields is; see guidance on breaking changes below.
* Kubernetes auto-generates code for APIs and Custom Resource objects
    * Generators can be run via hack/gen.sh
    * Kapp-controller’s aggregated API server has a separate generator: hack/gen-apiserver.sh
    * The CRD yaml is generated via[ a separate script](https://github.com/carvel-dev/kapp-controller/blob/85e814cda7109169809ede1c8a4f211739ad15d2/hack/gen-crds.sh) that is run by hack/build.sh

## Development Process
### Controller specific workflows
* Deploy in order to test changes to a local or dev cluster via hack/deploy-test.sh
    * We use minikube; while other solutions may work, minikube definitely works. Remember to  `> eval $(minikube docker-env)`
    * You can also use hack/deploy.sh to deploy
    * See dev.md for more details.

### Automated Testing
We write mainly e2es and units;  some tools have [performance tests](https://github.com/carvel-dev/imgpkg/tree/develop/test/perf)

* e2es
    * Can be found in test/e2e
    * Can be run via hack/test-e2e.sh (or test-all.sh)
    * Should make clear whether it tests the happy path or a failure case in the test name or [logged-section](https://github.com/carvel-dev/secretgen-controller/blob/develop/test/e2e/placeholder_secrets_multi_case_test.go#L241) 
    * Controllers (esp. kapp-controller)
        * Require other Carvel tools at specific versions, which can be installed via  hack/install-deps.sh
        * K8s behaviors are often hard to test well outside of e2e tests, as they often rely on side effects and multiple interacting pieces.
        * Prefer [a partial-coverage e2e test ](https://github.com/carvel-dev/secretgen-controller/blob/develop/test/e2e/placeholder_secrets_multi_case_test.go)complemented by [a more thorough unit/functional test that invokes reconcilers explicitly](https://github.com/carvel-dev/secretgen-controller/blob/develop/pkg/sharing/placeholder_secret_test.go) ([2nd example of limited scope unit test](https://github.com/carvel-dev/kapp-controller/blob/develop/pkg/packageinstall/packageinstall_deletion_test.go)). This allows us to leverage the power of e2e tests while reducing the runtime of our test suite by checking most edge cases and details in unit tests.
* Unit
    * Can be found mixed in with the code, per golang custom
    * Can be run via hack/test.sh (or test-all.sh)
    * Code that is ‘functional’ (input/output,  as opposed to relying on side effects) [should be unit tested](https://github.com/carvel-dev/kapp-controller/blob/85e814cda7109169809ede1c8a4f211739ad15d2/pkg/app/reconcile_timer_test.go)
        * E.g. we don’t mock the kubernetes API for the sake of a unit test, we just rely on e2e to cover that part of the code.
    * A meaningful ‘unit’ for a test may include multiple structs or files - particularly for middle layers in Dependency Injection patterns there is no need to test them in isolation. (for instance, [these controller reconciliation tests)](https://github.com/carvel-dev/secretgen-controller/blob/develop/pkg/sharing/placeholder_secret_test.go) 
    * If I remove one line/thing in the code only one test should fail. In other words, test only one unit per test.
    * While not all old tests use it, we prefer [testify](https://www.google.com/url?q=http://github.com/stretchr/testify&sa=D&source=editors&ust=1632950551239000&usg=AOvVaw2AmvToSVjm0FAWulRYV_21) for assertions in new tests
    * Targeted Unit tests for specific external integrations with detailed error and edge-case handling may [mock those external dependencies](https://github.com/carvel-dev/imgpkg/blob/274d5a2cfc9518d2a453290035c43b752d2f490d/pkg/imgpkg/bundle/contents_test.go#L73)
* Coverage
    * We aren’t concerned with any fixed coverage percentage
    * New large features generally should add an e2e test (targeting at least the happy path, but consider which failure cases are important)? 
        * A single test doesn’t have to fully cover a feature if the test suite covers the feature: consider whether another test already covers this codepath before adding a new test.
    * New code that “fits” a unit test (per the above) should add a unit test
    * Updates to code with existing unit tests should update tests.
    * While ideally every bugfix includes a new test to prevent regression, this may not always be practical.
    * Example of our 80/20 approach: our test suite tends to cover only the majority case of integrations and tools (e.g. harbor not dockerhub; linux not windows). OSS contributors are welcome to improve our testing integration with third parties. 
* Test Assets:
    * If a test requires additional artifacts or assets they should live in a separate /assets subfolder.
    * Test assets should include comments describing how to generate or modify those assets. [example](https://github.com/carvel-dev/kapp-controller/blob/1844e157b6de4048cec3ba0e53fc699d37e9c71e/test/e2e/assets/https-server/certs-for-custom-ca.yml#L9)

### Issues, Branching, Pull Requests, Approval
* Issues (see also, [issue triaging docs](hhttps://github.com/carvel-dev/carvel/blob/develop/processes/issue-triage.md) for more info!)
    * [Proposal Process](https://github.com/vmware-tanzu/carvel/tree/develop/proposals#carvel-proposals)
    * Prefer to leave issues open until documentation is complete
    * Docs typically live in a [separate
      repo](https://github.com/vmware-tanzu/carvel/tree/develop/site) which
      renders to [https://carvel.dev](https://carvel.dev)
    * When closing the issue manually, comment which release includes the issue so that others can easily find it.
* Branching
    * Our default / primary branch is named develop
    * We do not have convention around branch names
    * Prefer to delete branches from github after they’ve been merged.
* Pull Requests
    * Commits
        * Currently open-ended: can be intentionally staged, messy with the intention of squashing them, etc.
        * We may revisit automated release tooling and commit squashing.
    * Generally author should ping in slack after a PR is filed and ready for review
    * See our [issues/triage
      doc](https://github.com/carvel-dev/carvel/blob/develop/processes/issue-triage.md) for more info!
* Refactors
    * If a new feature needs a large refactor, we prefer that refactor in a separate PR. At a minimum developers should put refactor in a separate commit. This helps scope reviews and minimize changesets.
* Approvals
    * Maintainers will offer feedback on PRs but we have very little formalization around approval
    * Reviewers leave a “LGTM” or approved comment indicating a timestamped approval
    * Maintainers merge PRs when no outstanding comments are left other than LGTM / approval.

### Versioning and Backwards Compatibility
Carvel uses semver, x.y.z version structure, with all tools at major version x=0 currently.

* Bug fixes to existing releases increment the patch version (z), especially for “small” fixes
* Otherwise, even just for important bug fixes, new releases increment the minor version (y) whether or not there is a breaking change.
* API changes within each tool are at different stages of maturity (e.g. kapp-controller’s “app” CR is much more mature than “packageInstall”)
* Prefer to avoid breaking changes
    * We consider our “pre-1.0” phase to give us more flexibility, while still prioritizing user delight and non-breaking changes.
        * 1.0 should indicate 3-5+ years of hardened production use
        * 1.0 should offer a stronger guarantee against breaking changes
    * If we do have a breaking change we want to fully automate upgrading that break.
    * Sometimes we do have to make a breaking change e.g. when a bugfix closes a behavior loophole.

### Github Actions:  what gets run on PRs?
* golangci-lint (can be run locally; note not all projects have identical linter configs)
* [hack/verify-no-dirty-files.sh](https://github.com/carvel-dev/kapp-controller/blob/develop/hack/verify-no-dirty-files.sh) - verifies that CI can build without any changes to git working directory
* Test suite (hack/test-all.sh)
* Aspirational: a single script that runs linter, no-dirty-files, and unit tests locally

### Release Process
* Open Source Software Releases: We’re mostly trying to use goreleaser, which relies on git tags, but this varies by repo; see the relevant dev.md for details
* VMware releases: have their own process; VMware employees should see internal docs.
