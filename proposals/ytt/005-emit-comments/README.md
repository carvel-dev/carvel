**Title: Emitting comments from ytt templates** \
**Originating Issue: [ytt #63](https://github.com/carvel-dev/ytt/issues/63) \
Document Status**: Draft

### Objective

This document captures various customer requirements for the requested feature of  **Emitting comments through ytt
templates**. We would like to get consensus on the next steps for this effort, once this document has been processed and
approved. It elaborates on explored use cases and enumerates risks as well. We take into account inputs from internal
stakeholders and OSS stakeholders as well.

### Goals

* Emit **YAML comments** from ytt templates.
* Gather the requirements that exist in different sources and unify them in a single place.
* Assess the customer impact considering the possible risks.
* Provide possible solutions with pros and cons for the implementation.

### Anti Goals

* Account for future work (like overlay tracing) this effort paves the way for.

### Problem Statements

From all the feedback that we have collected so far about this issue, we can split the problems that the users are
facing into the following two problem statements:

1. **Emit YAML comments from YAML templates** - Configuration Authors
   want ytt to provide a facility to safely emit YAML comments from YAML templates. These are mainly used by the authors
   to add context to YAML configuration files. These comments work as a reference for the configuration consumers who
   may need to read and understand the configurations to make changes as per their requirements.
2. **Generate ytt with ytt** - Configuration Authors also want to generate ytt with ytt. In other words, they want to automate building ytt templates, primarily
   having the ability to make it possible to produce a yaml file that can be used as a template for further processing.

###  1. Emit YAML comments from YAML templates

* Without the ability to weave in context (in the form of YAML comments), our customers must burn hours sleuthing back
  through whatever process(es) executed ytt, to find their inputs.
* Authors also miss the opportunity to keep this important information in the template and the consumers may spend time
  connecting the dots. This is the time lost to making progress in their first-order work.

### Proposal

1. Configuration Authors can add yaml comments via the **#@yaml/comment** annotation followed by quotes surrounding the
   comment. These comments will appear in the final output as a valid yaml comment (#&lt;space>) and without quotes
   only if the **emit-comments flag** is set to true.
2. Existing yaml comments (#) or ytt comments (#!) will not be preserved.
4. Multiline comments would be shown as separate yaml comments on new line each starting with #&lt;space>.

### Implementation details

1. This feature can be implemented by adding comment post processing functionality to go over the annotated comments,
   convert them to YAML comments and attach them to the yaml nodes.
2. This can be done while evaluating the template with all the final data values after applying the overlays.

### Example Use Cases 

With this feature, using the  **#@yaml/comment** annotation along with **emit-comments** flag set to **true**, YAML
comments can be preserved in the output as shown below

1. **Single line comment**

**Input**
```yaml
databases:
name: foo
#@yaml/comment "alias for environment"
alias: dev1
hostname: myexampledb.xyz.com
```
**Expected output:**
```yaml
databases:
name: foo
# alias for environment
alias: dev1
hostname: myexampledb.xyz.com
```
2. **Multiline Comments**

**Input**
```yaml
#@yaml/comment "Source1 - source docs1 \nSource2 - source docs 2
databases:
name: foo
alias: dev1
hostname: myexampledb.xyz.com
```
**Expected output:**
```yaml
# Source1 - source docs1
# Source2 - source docs2
databases:
name: foo
alias: dev1
hostname: myexampledb.xyz.com
```
### Benefits to our customer

ytt users would benefit from being able to add some context behind decisions made by the template. As platform
operators read the final output from ytt, having helpful comments explaining why there are certain configurations present,
or why they have particular values, would speed up a new operator or remind an existing operator about why some
decisions were made.

Also, partners we chatted with called out that it can be challenging to trace changes made by an
overlay especially when dealing with larger configurations. This work would pave the way for us to introduce
source-tracing in the future.

### Known Risks

1. This feature will involve a lot of breaking changes because of the low level code changes required to use the API v3
   of the yaml package for Go -` yaml.v3` Currently, ytt is built around the v2 release of the yaml module which does
   not support emitting comments.` yaml.v2` is hard vendored in the code.
2. Due to the introduction of [Special Indentation for Sequences](https://github.com/go-yaml/yaml/issues/661) by using
   the `yaml.v3` library, the output of ytt will be different. This change will affect our test suite as well as the
   execution of ytt by its users. There is an update with [this issue](https://github.com/go-yaml/yaml/pull/750) and got
   superseded by [this](https://github.com/go-yaml/yaml/pull/753) issue.
3. The` yaml.v3` introduces a change in how the comments are emitted (with a space after #)
4. There are many [known/open issues](https://github.com/go-yaml/yaml/issues?q=is%3Aissue) in go-yaml/yaml since 2020/21
   that talk about comments not being emitted consistently using the go v3 parser.
   E.g. [The header comments get emitted as footer comments](https://github.com/go-yaml/yaml/issues/610) etc.
5. The output from ytt for the same input yaml may differ when using` yaml.v2` vs `yaml.v3` library.

### Possible Solutions 

To integrate the <code>yaml.v3<strong> </strong></code>code with the current implementation of ytt, there are few
possible solutions as below:

#### 1. Replacement of<code> yaml.v2</code> by <code>yaml.v3</code></strong>

**Pros**:

* As output from ytt may differ when using two parsers, this approach would keep the output consistent.
* Once this is implemented, we can leverage the yaml.v3 features of preserving the intermediate representation to solve
  many other issues reported by users that would need annotation for empty line, conversion of floating points numbers
  to integers, quotes issue with hexadecimal numbers etc

**Cons**:

* This will be a high risk approach that would bring in a lot of breaking changes. It would require making low level
  changes to the ytt code. So, the complete ytt codebase including the test suites will be impacted.
* There are many ongoing issues with this new parser and
  also [incompatibility issues](https://github.com/go-yaml/yaml/issues/783) with the old versions. This may affect our
  customers too who are using ytt programmatically. \

#### 2. Patch the vendored<code> yaml.v2</code></strong> 

Patch with the specific changes from**<code> yaml.v3</code> </strong>for emitting the comments.

**Pros:**

* This will eliminate the need to hard vendor in the` yaml.v3`
* This will reduce the code changes and testing efforts required than replacing the complete parser.

**Cons:**

* This would need finding all the changes done in` yaml.v3` for emitting comments and applying them on
  vendored` yaml.v2` code. This would also bring in breaking changes and much larger testing efforts to cover whole ytt
  functionality with new Marshallar when comments are included.
* There are some [open issues](https://github.com/go-yaml/yaml/issues/783) like` yaml.v3` being incompatible
  with` yaml.v2`. So we need to make sure such issues are not bringing in any new breaking changes.
* Also, make sure we are not bringing in any unwanted code because
  of [open issues ](https://github.com/go-yaml/yaml/issues/954)like panic unexpectedly etc. \

#### 3. Hybrid approach 

Marshal with <code>yaml.v3</code> only</strong> if the <strong>emit-comments</strong> flag is true. If not then no
change in current functionality. <code> </code>

**Pros:**

* This would require fewer changes in our current code base.
* Once this plumbing code is implemented, we can extend it to include other yaml.v3 features like preserving the
  intermediate representation to solve many other issues reported by users.

**Cons:**

* As this feature involves low level code changes, to minimize the impact of a lot of breaking changes, we need to keep
  using` yaml.v2` for Unmarshaling and use `yaml.v3` for Marshaling in very specific scenarios where` yaml.v3` features
  are required to use.
* The output of ytt will not be consistent and it will be dependent on presence of #@yaml/comment annotation. There
  might be more issues reported due to [known/open issues](https://github.com/go-yaml/yaml/issues?q=is%3Aissue) with
  the `yaml.v3`.

#### 4. Unmarshal with <code>yaml.v2 </code>and marshal with <code>yaml.v3</code></strong>

**Pros:**

* The same version of ytt will always provide the same output with or without the presence of the #@yaml/comment
  annotation
* Once this is implemented, we can extend it to include other yaml.v3 features like preserving the intermediate
  representation to solve many other issues reported by users.

**Cons**:

* As this feature involves low level code changes, to minimize the impact of a lot of breaking changes, we need to keep
  using` yaml.v2` for Unmarshaling and use `yaml.v3` for Marshaling. More work involved in maintaining two versions of
  YAML packages for Go..
* There are many ongoing issues with this new and
  also [incompatibility issues](https://github.com/go-yaml/yaml/issues/783) with the old versions. This may affect our
  customers too who are using ytt programmatically.
* Also this can introduce a few [open issues/bugs ](https://github.com/go-yaml/yaml/issues/954)like panic unexpectedly
  etc.

NOTE: Risks around breaking changes can be mitigated by an
ongoing [effort in kubernetes-sigs/yaml](https://github.com/kubernetes-sigs/yaml/pull/76). Which seems to guarantee
backwards compatibility on a fork
of `yaml.v3` ([ref](https://github.com/kubernetes-sigs/yaml/pull/76/files#diff-5afd41e7e0a70c3a6f0e1572f6938d9aacf5bc590033f7e798a0fb6f741e51ddR944)).

#### Open Questions

1. Can we achieve this kind of corner case mentioned in
   the[ issue](https://github.com/carvel-dev/ytt/issues/63#issuecomment-550976560) where a comment needs to be present
   without space. 
   “_A cloud-config file must contain a header: Either #cloud-config” _
2. How is the existing vendored `yaml.v2` package patched? Is there divergence from upstream?


#### Answered Questions 

1. What can be the impact of --ignore-unknown-comments = true flag? -  \
   Ans: Current working of this flag would not be changed.

### 2. Generate ytt with ytt - Emitting ytt templates for post processing

The main use case here is that template authors want to be able to allow certain bits of ytt to pass through and be processed at a later stage. 
They want to be able to output unprocessed templates from ytt. This is a requirement which was boiled down to being able to generate comments that are annotations.

**Example Use Cases from community**

1. [Use case 1](https://gist.github.com/vrabbi/6aeab52256cc3a346d94fd3f3734a204)
   
2. [Use case 2](https://github.com/vmware-tanzu/cartographer/issues/1119)

3. ytt power users will often end up overlaying Carvel package installations to cater to niche customer requirements,
   quick fixes or even platform specific discrepancies. It becomes much harder for platform engineers/operators to trace which overlay/file affected a particular part of the
   configuration when dealing with larger sets of configuration as ytt aggregates this into a single stream of output.
   This would enable users using ytt with larger projects to get to the root of iffy scenarios faster. A debug mode for
   template authors.

### Potential solution


If we decide to patch `yaml.v2` ourselves to allow emitting comments, we might be able to change the implementation to allow the lack of a leading space in a comment. However, there are factors such as limiting nesting to be considered even if we go with this approach. Allowing ytt to generate templates for further processing does not need to be coupled with emission of comments and is a separate problem.

### Blockers

* `yaml.v3` does not allow emission of comments without a leading space, this alone makes the implementation unfeasible.

* There are unresolved issues with yaml comments(add link for issue) using` yaml.v3`. Misplaced comments are a critical issue if we
  are generating ytt annotations, it is less critical as of now for YAML comments exempt from further processing.

* We can not export everything from  ytt - e.g.  a schema. Schema needs to be in it own file.
* We also need to consider limitations with respect to Starlark code empbedded in the templates.

### Appendix

Keep an eye out for below effort from the community:
Community is trying to support a fork of yaml.v3 to be compatible with yaml.v2 [current issue](https://github.com/go-yaml/yaml/issues/783)
If this work is complete, this could make some of the above mentioned work easier to be unblocked.
via:[https://github.com/kubernetes-sigs/yaml/pull/76](https://github.com/kubernetes-sigs/yaml/pull/76). They might be
hesitant to enable something that the YAML spec does not recommend.

