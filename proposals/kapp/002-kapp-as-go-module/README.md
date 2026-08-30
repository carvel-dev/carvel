---
title: "kapp as a Go module"
authors: ["Yash Sethiya <yashsethiya97@gmail.com>"]
status: "Review"
approvers: ["Carvel Maintainers"]
---

# Kapp as a Go module

#### Problem: 
kapp cannot be used as go module today and hence there is no way to watch the changes, improving error handling and resillence

#### Solution:
Officially start supporting kapp as a go module There should be exported pkg or APIs that can be leveraged 

#### Approach 1: Exposing Exportable Functions and Structs While Keeping Cobra (Recommended)
Meticulously architect or adapt existing structures to encapsulate the full spectrum of configuration options available to users. These structs comprehensively mirror the configuration capabilities currently accessible via CLI flags.

##### Pros:
- Maintains CLI Functionality: Keeps the rich CLI features provided by Cobra, like command hierarchy, automatic help generation, and flag parsing.
- Ease of Use for CLI Users: Existing CLI users can continue using the application as they always have, with no changes to their workflow.
- Flexibility for Developers: Developers can programmatically use the core functionality of the application by calling the exposed functions and structs.

##### Cons:
- The internal codebase will increase and will be setting defaults seperately, having to support both CLI and programmatic use cases.
- Retaining the dependency on Cobra, which might not be necessary for programmatic usage.

##### Challenges:
- Have to write significant amount of code for the functional options for each of the flag but we can restrict to just write the functions for the flags that are critical and then extend the functionallity with time.


#### Approach 2: Get Rid of Cobra and Write the CLI Logic Manually
Avoid spf13/cobra as dependency and call the structs and methods natively.

##### Pros:
- Full Control: Complete control over the CLI processing logic, potentially leading to a simpler system for small applications.
- No External Dependencies: Removes the dependency on Cobra, lightening the application.

##### Cons:
- While this approach gives us full control over how commands and flags are handled, it also requires more manual effort to implement features that come out-of-the-box with frameworks like Cobra, such as automatic help generation, command grouping, and advanced flag handling (e.g., typed flags, default values) we have manage all this manually using this approach
- Potential for Bugs: Increased scope for bugs in the CLI parsing logic.


#### Approach 3: Refactoring to Use io.Reader and io.Writer
Accept configuration as a io.Reader and writing outputs to io.Writer

##### Steps:
- Refactoring the existing command handelers to read input from an io.Reader and write output to an io.Writer
- For CLI usage we create a wrapper that interacts with terminal, read input from os.Stdin, output to os.Stdout and parses command-line arguments to pass to your command functions.

##### Pros:
- High Flexibility and Testability: Makes it easier to test the application and use it both as a CLI tool and programmatically as a library.
- Decoupling I/O: By decoupling input/output from the business logic, you gain flexibility in how commands are executed and tested.
- Maintains CLI Capabilities: You can still offer a CLI to your users, either by retaining Cobra for just the CLI part or implementing a custom lightweight CLI layer.


##### Cons:
- Requires Significant Refactoring: Depending on the current codebase's design, this approach might require considerable effort to refactor.
- Learning Curve: Users and contributors need to understand the new architecture to contribute effectively or use the library programmatically.

##### FAQ:
1. Why Approach1 is recommended?
As CLI is our primary use case, but we also a need to support programmatic access for integration into other Go projects hence Approach1 seemed to be most balanced choice.

#### Open Questions:
- Which command we should start with deply, delete, app-group??
- Should be divide it into subtasks based on commands and have an estimation for each of the command?
-
###### Approach 1 Implementation Details

---


```
type DeployOption struct {
    ui ui.Ui
    
    AppFlags Flags
    FileFlags FileFlags
    ...
}

type Flags struct {
    Name           string
    AppNamespace   string
}

type Option func(*DeployOption)
```

Offering a function that returns an instance of the DeployOption struct and populates it with default values

```
func NewDefaultDeployOption(options ...Option) *DeployOption {
    op := &DeployOption{
        AppFlags: &Flags{
            Name: "app",
            Namespace: "default",
        }
    }
    for _, option := range options {
        option(op)
    }
    return op
}
```

Allowing Custom Configuration via functional Options
```
// WithDirectory returns a function that set the app name

func WithAppName(name string) func(*DeployOption) {
    return func(o *DeployOption) {
        o.AppFlags.Name = name
    }
}

func WithConfigFiles(files []string) func(*DeployOption) {
    return func(o *DeployOption) {
        o.FileFlags.Files = files
    }
}
```

How users can customize their configuration when creating a new instance:
```
o := NewDefaultDeployOption(WithAppName("app1"), WithConfigFiles("config"))
```



##### Important links:
- https://github.com/carvel-dev/kapp/issues/564
- https://kubernetes.slack.com/archives/CH8KCCKA5/p1659086135812959
- https://kubernetes.slack.com/archives/CH8KCCKA5/p1710271382904119
- https://kubernetes.slack.com/archives/CH8KCCKA5/p1663603452063589
- https://kubernetes.slack.com/archives/CH8KCCKA5/p1637702838489500 



