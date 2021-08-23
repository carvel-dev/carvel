## Carvel Roadmap

### About this document
This document provides a high-level overview of the next big features the maintainers are planning to work on. This should serve as a reference point for Carvel users and contributors to understand where the project is heading, and help determine if a contribution could be conflicting with a longer term plan. [Carvel project backlog](https://app.zenhub.com/workspaces/carvel-backlog-6013063a24147d0011410709/) is prioritized based on this roadmap and it provides a more granular view of what the maintainers are working on a day-to-day basis.  

### How to help?
Discussion on the roadmap can take place during [community meetings](https://carvel.dev/community/). If you want to provide suggestions, use cases, and feedback to an item in the roadmap, please add them to the [meeting notes](https://hackmd.io/F7g3RT2hR3OcIh-Iznk2hw) and we will discuss them during community meetings. Please review the roadmap to avoid potential duplicated effort.

### How to add an item to the roadmap?
One of the most important aspects in any open source community is the concept of proposals. Large changes to the codebase and / or new features should be preceded by a [proposal](https://github.com/vmware-tanzu/carvel-community/tree/develop/proposals) in our repo.
For smaller enhancements, you can open an issue to track that initiative or feature request.
We work with and rely on community feedback to focus our efforts to improve Carvel and maintain a healthy roadmap.

### Current Roadmap
The following table includes the current roadmap for Carvel. If you have any questions or would like to contribute to Carvel, please attend a [community meeting](https://carvel.dev/community/) to discuss with our team. If you don't know where to start, we are always looking for contributors that will help us reduce technical, automation, and documentation debt.
Please take the timelines & dates as proposals and goals. Priorities and requirements change based on community feedback, roadblocks encountered, community contributions, etc. If you depend on a specific item, we encourage you to attend community meetings to get updated status information, or help us deliver that feature by contributing to Carvel.

|Theme|Description|Timeline|
|---|---|---|
|**[kapp-controller]** [Private Registry Authentication](https://github.com/vmware-tanzu/carvel/pull/208) | Software package consumers can access private registries that require authentication. [Epic](https://app.zenhub.com/workspaces/carvel-backlog-6013063a24147d0011410709/board?epics=220090417_145&filterLogic=any&repos=220090417,238705413) | August 2021 |
|**[ytt]** [Export ytt Schema as OpenAPI Schema](https://github.com/vmware-tanzu/carvel/pull/198) |Users can export ytt schema into OpenAPI schema so that package authors can provide this standardized OpenAPI schema for their configuration when creating a package. [Epic](https://app.zenhub.com/workspaces/carvel-backlog-6013063a24147d0011410709/issues/vmware-tanzu/carvel-ytt/357) |September 2021|
|**[ytt]** [Guides & Examples](https://github.com/vmware-tanzu/carvel-ytt/issues/314) | Provide more guides and examples so that ytt is easy to get started with and details how ic can be incorporate in different workflows. [Epic](https://app.zenhub.com/workspaces/carvel-backlog-6013063a24147d0011410709/board?epics=173207060_314&filterLogic=any&repos=173207060) | October 2021|
|**[imgpkg]** [Renaming Images When Copying Bundles](https://github.com/vmware-tanzu/carvel-community/tree/003-copy-bundles-with-rename/proposals/imgpkg/003-copy-bundles-with-rename) | Allow users that are copying bundles between registries to have more control over the location where the images are copied to. |TBD|
|**[ytt]** Improve compatibility with other tools | In order to grow ytt's capabilities, we want to ensure that it integrates well with common tools in the open-source ecosystem |TBD|
|**[ytt]** [Schema Validations](https://hackmd.io/pODV3wzbT56MbQTxbQOOKQ#Part-7-Validating-Documents)|Configuration authors can specify the valid range or format of the data values. |TBD|
|**[imgpkg]** TanzuNet Support | Allow TanzuNet users to seamlessly use imgpkg. |TBD|
|**[imgpkg]** image signing & verification | imgpkg supports the ability to sign and verify images/bundles. |TBD|
|**[kapp-controller]** Package Management API Enhancements | Continue to evolve the Package Management APIs based on feedback. | TBD |
|**[kapp-controller]** Dependency Management |  | TBD |

Please note that the maintainers are actively monitoring other Carvel tools that are not explicitly listed in the roadmap, e.g. kapp, kbld, vendir etc. While the maintainers have prioritized the big features listed above, if you would like us to address issues that are important to you please don't hesitate to share them with us. One way to share your feedback is by voting on an existing issue or you could simply bring them up during our community meeting.

`Last Updated: August 2021`
