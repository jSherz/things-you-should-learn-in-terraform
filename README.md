![Things you should learn in Terraform](./assets/logo.png)

# Things you should learn in Terraform (Terraform koans)

This tutorial series guides you through a number of real-world scenarios that
you'll likely encounter as a builder using Terraform. These examples are
written for AWS, but could easily be adapted into a cloud provider of your
choice.

## Pre-requisites ✅

It's recommended that you have a basic grasp of HCL, the language Terraform
projects use, before you get started.

Check out [Get Started - AWS in the Terraform docs] if you want a refresher
first.

[Get Started - AWS in the Terraform docs]: https://developer.hashicorp.com/terraform/tutorials/aws-get-started

## Getting started 👩‍💻

1. Install Terraform v1.5.

   Follow the instructions in [Install Terraform].

2. Install the AWS CLI (version 2).

3. Clone the project

4. `cd` into the directory of the exercise you want to try.

5. Follow the instructions in the `README.md` file.

[Install Terraform]: https://developer.hashicorp.com/terraform/downloads?product_intent=terraform

## Exercises 🏋️

* [1 - Setting up remote state]

* [2 - Pull and inspect the state]

* [3 - Recovering the state after bad changes]

* [4 - Keep a resource]

* [5 - Move a resource into a module]

* [6 - Set variables based on the current Terraform workspace]

* [7 - Expand and contract migrations]

* [8 - Importing an existing resource with no disruption]

* [9 - Fast feedback when changing modules]

* [10 - Trigger dependant pipelines when using remote state]

[1 - Setting up remote state]: ./exercises/01_setting-up-remote-state/README.md

[2 - Pull and inspect the state]: ./exercises/02_pull-and-inspect-state/README.md

[3 - Recovering the state after bad changes]: ./exercises/03_recovering-the-state-after-bad-changes/README.md

[4 - Keep a resource]: ./exercises/04_keep-a-resource/README.md

[5 - Move a resource into a module]: ./exercises/05_move-a-resource-into-a-module/README.md

[6 - Set variables based on the current Terraform workspace]: ./exercises/06_set-variables-based-on-the-current-workspace/README.md

[7 - Expand and contract migrations]: ./exercises/07_expand-contract-migrations/README.md

[8 - Importing an existing resource with no disruption]: ./exercises/08_import-existing-resources-no-disruption/README.md

[9 - Fast feedback when changing modules]: ./exercises/09_fast-feedback-changing-modules/README.md

[10 - Trigger dependant pipelines when using remote state]: ./exercises/10_trigger-dependant-pipelines-remote-state/README.md
