# A Guide to Ansible and Ansible Automation Platform Code Lifecycle

This guide outlines a robust workflow specifically for Ansible Automation Platform (AAP) users, detailing how to manage Ansible automation from concept to production. It emphasizes best practices sourced primarily from official Red Hat and Ansible documentation, tailored for the AAP environment.

---

## Guiding Principles (within AAP)

- **Treat Automation as Code**: Apply rigorous software development practices (version control, testing, reviews) to all Ansible artifacts managed within AAP Projects.
- **Simplicity and Clarity**: Keep structures and logic as simple as possible within your playbooks and roles. Readability counts for easier maintenance and collaboration within AAP.
- **Consistency**: Adhere to defined standards across the team for content stored in Git and executed via AAP.
- **Idempotency**: Ensure all automation executed via AAP Job Templates can be run multiple times without unintended side effects.

---

## Phase 1: Plan & Structure - Laying the Foundation for AAP

### 1. Define the Goal (Keep it Simple)

- Start with a clear, specific automation objective. Focus on the desired "Target State" for systems managed by AAP.
- Begin with a simple concept and iterate, adding complexity gradually within your playbooks and roles.

### 2. Manage Inventory Effectively (within AAP)

#### Identify The Sources of Truth

A single source of truth should exist for any specific piece of information. For example, the current systems deployed to a specific environment. There may be other sources of truth for other environments, or for other types of data, but for those systems in that environment, there is a single source. Having multiple sources of truth for a single type of data can result in unexpected behavior and data synchronization issues. If the same type of data is scattered across multiple systems, it should be consolidated into a single system.

**Note**: Different teams may have different sources of truth, but within that team they should standardize and enforce accuracy within their selected sources of truth.

#### Prioritize Dynamic Inventory Sources in AAP

Configure AAP Inventory Sources to pull dynamically from cloud providers, VMware, or CMDBs. This is generally preferred over static files for scalability and accuracy within AAP.

#### Use Separate AAP Inventories

Create distinct AAP Inventory objects for Dev, QA, and Prod environments. Assign hosts (statically or via dynamic sources) to the appropriate inventory. This ensures clear separation when targeting Job Templates.

#### Manage Variables in AAP Inventory

Define environment-specific variables directly within the AAP Inventory (at the Inventory, Group, or Host level) or leverage `group_vars`/`host_vars` sourced from the AAP Project (note potential path differences compared to CLI).

### 3. Setup the Development Environment

- Take your time looking for the most suitable development environment for your organization and for your use case.
- Make sure that it adheres to your organization standards and does not violate any company policy.
- **Key considerations** when choosing the development environment are: completeness, security, user-friendliness, integrations and of course it should do the job.
- The development environment could be **local**, like an IDE installed on the developer's machine, or **remote** like OpenShift Dev Spaces.
- Local DE offers greater flexibility for the developer but introduces risks; remote DE offers more control and is easier to adhere to existing policies.
- Red Hat provides a wide range of tools like linter and tester. You can find them packaged in **Ansible Development Tools (ADT)**.
- Red Hat also provides an **official Ansible plugin for VS Code** which greatly improves the developer's experience.
- If you're using a **Windows workstation**, consider using **WSL** if your company allows it; it provides you with a fully integrated Linux VM inside your Windows machine. VS Code has an excellent WSL integration plugin. If you cannot use WSL, VS Code also offers a Remote Connection plugin which allows you to develop directly on a remote Linux machine.

### 4. Adopt Recommended Project Structure (for Git Repository)

Use the **"Alternative Directory Layout"** in your Git repository to strictly separate environment configurations. This structure is essential for preventing errors when AAP manages Dev, QA, and Prod workflows. While this structure helps organize variables in Git, remember that AAP primarily uses its own Inventory objects, potentially sourced dynamically or from Git, for targeting and variable management during execution.

### 5. Standardize Role Creation (within Git Repository)

- Always use `ansible-galaxy role init <role_name>` to create roles, ensuring a consistent structure.
- **Crucially**: Place variables intended for user customization in `defaults/main.yml`. These have the lowest precedence and are easily overridden by AAP Inventory variables or Job Template extra vars.
- Use `vars/main.yml` only for internal role variables that users should not override. This is a common point of failure if done incorrectly.
- **Prefix role variables** with the role name (e.g., `nginx_port` not `port`) to prevent naming collisions when roles are combined in AAP.
- **Prefix internal variables** such as loop and register variables with a double underscore to make it obvious in code reviews and troubleshooting that these variables are for internal use only, and should not be overridden by users.
- Design roles around **functionality** (e.g., `configure_webserver`) rather than specific software (e.g., `install_apache`).
- Include a comprehensive `README.md` for each role. To help get started writing good README.md's, take a look at the **docsible** tool.

### 6. Utilize Collections (within AAP Ecosystem)

- Package reusable roles, modules, and plugins into Ansible Collections for better namespacing, dependency management, and distribution via Automation Hub or Git.
- Reference content using **Fully Qualified Collection Names (FQCNs)** like `namespace.collection_name.module_name` in your playbooks and roles.
- Manage collection dependencies via a `requirements.yml` file in your Git project root. This file is used when building Execution Environments or can be processed during AAP Project syncs.
- Prioritize **Red Hat Certified** for supported content and **Ansible Validated Content** for enterprise-grade automation, both available through Automation Hub within AAP.

---

## Phase 2: Develop & Version - Building Reliable Code for AAP

### 1. Write High-Quality Code (for Playbooks/Roles in Git)

- **Mandate Idempotency**: Ensure playbooks run via AAP Job Templates yield the same outcome on subsequent runs. Use module parameters like `state`, and for `command`/`shell` modules, use `creates`, `removes`, or `changed_when`.
- **Name Everything**: Always use the `name:` attribute for plays, blocks, and tasks. These names appear in AAP job output, aiding debugging.
- **Be Explicit**: Use `state: present` or `state: absent` even if it's the default for clarity.
- **Prefer Native Modules**: Use Ansible's built-in modules over `command` or `shell` for better reliability and integration with AAP's reporting.
- **Use Linters**: Integrate `ansible-lint` into your local development and CI pipeline to enforce best practices before code reaches AAP.

### 2. Manage Secrets Securely (Primarily within AAP)

#### For Secrets Stored in Git (Use Sparingly)

If absolutely necessary to store secrets with code, use `ansible-vault`. Use the indirection pattern (unencrypted `vars.yml` referencing encrypted `vault.yml`).

#### For Runtime Secrets (Recommended)

Strongly prefer using **AAP Credentials**. Store SSH keys, API tokens, Vault passwords, etc., securely within AAP, managed by RBAC. Assign these credentials to Job Templates; AAP injects them securely at runtime.

### 3. Implement Version Control (Git for AAP Projects)

#### Mandatory Git

Store all Ansible code (playbooks, roles, requirements.yml, Molecule tests, CaC definitions) in Git. AAP Projects sync directly from Git. Commit frequently with clear messages.

#### Recommended Branching Strategy: Trunk-Based Development with Tags

- Use a single **main branch** (e.g., `main`) in Git.
- Develop features/fixes in **short-lived branches**, merging them back to `main` frequently via Pull/Merge Requests.
- **Promote code to environments** (QA, Prod) using **Git tags**. Create immutable tags (e.g., `qa-v1.1.0`, `prod-v1.0.0`) on specific commits in `main`.
- Configure AAP Projects for QA and Prod environments to check out these specific tags. The Dev environment's AAP Project typically tracks the `main` branch head.

**Why this strategy for AAP?** It simplifies Git management, avoids environment branch synchronization issues, and integrates cleanly with AAP Projects' ability to deploy specific tags.

#### Mandate Code Reviews

Use Pull Requests (PRs) or Merge Requests (MRs) in your Git platform for all changes merged into `main`. This ensures code quality before it's pulled into AAP.

---

## Phase 3: Test - Ensuring Quality Before AAP Execution

### 1. Mandate Molecule Testing (Locally/CI)

Use **Molecule** as the standard framework for testing Ansible roles and collections before deploying them via AAP.

### 2. Set Up Molecule Scenarios

- Initialize scenarios within your role or collection directory using `molecule init scenario`.
- **Configure `molecule.yml`**:
  - **Driver**: Use `podman` or `docker` for local container-based testing.
  - **Platforms**: Define multiple platforms (e.g., RHEL 8, RHEL 9 based images) to ensure compatibility. Use images supporting systemd if testing services.
  - **Provisioner**: Use `ansible`. Configure `provisioner.env` if needed to set `ANSIBLE_ROLES_PATH`.
  - **Verifier**: Use `ansible` for simplicity, writing tests in `verify.yml` using standard Ansible modules.
  - **Linters**: Enable `ansible-lint`.

### 3. Execute Tests (Locally/CI)

- **Local Development**: Use `molecule converge` and `molecule verify` iteratively. Use `molecule login` for debugging.
- **CI/CD Integration**: Run `molecule test` in your CI/CD pipeline (triggered on PRs) to execute the full test sequence before merging code that AAP will consume.
- **Idempotence Check**: Ensure the idempotence check within `molecule test` passes.

---

## Phase 4: Deploy & Orchestrate - Using Ansible Automation Platform (AAP)

### 1. Use Execution Environments (EEs)

- EEs are **mandatory** for consistent, portable runtimes in AAP. They package Ansible, Python, collections, and dependencies into container images used by AAP jobs.
- Use `ansible-builder` to create custom EEs based on an `execution-environment.yml` definition file (specifying collections via `requirements.yml`, etc.).
- Push built EE images to a container registry (Automation Hub).
- Add the EE to AAP Controller (Administration → Execution Environments).
- **Avoid exposing EE's to local paths**. The `Paths to expose to isolated jobs` option may provide a quick fix, but limits the scalability of Automation Controller.
- Assign the appropriate EE to your Job Templates in AAP.

### 2. Integrate Code via AAP Projects

- Create AAP Projects that point to your Git repository.
- **Configure the SCM Branch/Tag/Commit field** for each environment's project:
  - **Dev Project**: Points to `main` branch.
  - **QA Project**: Points to the relevant `qa-vX.Y.Z` tag.
  - **Prod Project**: Points to the relevant `prod-vX.Y.Z` tag.
- Use **SCM Update Options** like "Update Revision on Launch" to ensure AAP jobs run with the specified code version.
- Configure necessary SCM Credentials in AAP if the repository is private.

### 3. Define Execution with Job Templates (JTs)

- Create **Job Templates (JTs)** in AAP to define how to run specific playbooks.
- Link each JT to the correct Project (Dev, QA, or Prod version), Playbook file, Inventory (Dev, QA, or Prod), Execution Environment, and necessary Credentials.
- Use "Prompt on Launch" sparingly; prefer separate JTs or Workflows for distinct environment configurations.

### 4. Orchestrate Promotion with Workflow Job Templates (WFJTs)

- Use **Workflow Job Templates (WFJTs)** in AAP to automate the Dev → QA → Prod promotion pipeline.
- **Build workflows graphically** in the AAP UI:
  - **Sequence nodes**: Start → Sync Project (using appropriate tag for QA/Prod) → Run JT (deploy/test) → Approval Node (for QA/Prod gates) → Sync Next Project → Run Next JT.
  - Define success/failure paths for conditional logic (e.g., run rollback JT on failure).
- Trigger workflows based on SCM webhooks or schedules within AAP.

---

## Phase 5: Manage AAP - Configuration as Code (CaC)

### 1. Mandate AAP Configuration as Code

- Manage **Authenticators** via CaC and leverage Authenticator Maps to populate Users, Teams, and Organizations.
- Manage the configuration of AAP itself (Projects, Inventories, Credentials, JTs, WFJTs, EEs, Settings) using code stored in Git. This ensures consistency, repeatability, and auditability across potentially multiple AAP instances (Dev AAP, Prod AAP).
- **Organization administrators** should manage their own objects in their own repositories with CaC. This allows each organization to push changes when they are ready and not affect or have to wait on other teams/orgs.

### 2. Use the Recommended Tool

Employ the **`infra.aap_configuration`** Ansible collection (maintained by Red Hat CoP) to declaratively define AAP objects in YAML files within a dedicated Git repository.

### 3. Adopt a GitOps Workflow

- Store CaC YAML definitions in a dedicated Git repository.
- Use Pull/Merge Requests for proposing changes to the AAP configuration.
- Implement a **CI/CD pipeline** (potentially using AAP itself or another tool like Jenkins/GitLab CI) that automatically triggers on merges to specific branches (e.g., `main` for Prod AAP, `develop` for Dev AAP). This pipeline runs an Ansible playbook using the `infra.aap_configuration` roles against the target AAP instance to apply the configuration.

### 4. Manage Environment-Specific Variables within CaC

- Keep the core CaC definitions (e.g., structure of a JT) identical across environments.
- Handle differences (e.g., SCM tags in Projects, Inventory names in JTs, Credential names) using a combination of:
  - **Ansible Variables per AAP Environment**: Define an Ansible inventory for your AAP instances (e.g., `[aap_dev]`, `[aap_prod]`). Use `group_vars/aap_dev.yml`, `group_vars/aap_prod.yml`, etc., within your CaC repository to set environment-specific overrides.
  - **AAP Object Name Referencing** (Especially for Credentials): Define AAP Credentials securely within each AAP instance. In your CaC definitions (e.g., for a Job Template), reference the name of the credential. AAP resolves this name to the actual credential specific to that AAP instance at runtime. This avoids storing sensitive details in the CaC code.
  - **Lookup Plugins** (Optional): Use Ansible lookup plugins like `env` or cloud parameter stores within CaC definitions for dynamic values.
- Use **Ansible Vault** within the CaC repository only for secrets needed by the CaC playbook itself (e.g., an AAP service account password), not for the runtime credentials AAP uses.

---

## Phase 6: Putting It All Together - Synchronizing the Lifecycle

The phases described above work together to create a synchronized and controlled lifecycle for your Ansible automation within AAP. Here's how the different components stay in sync and move through environments without introducing unintended changes:

### 1. The Central Role of Git and Tagging

- The **Trunk-Based Development with Tags** Git strategy is the cornerstone of synchronization. All code changes (playbooks, roles, collection definitions, EE definitions, CaC definitions) are merged into the `main` branch after development and testing (including Molecule tests on feature branches).
- **Git tags** (e.g., `qa-v1.1.0`, `prod-v1.0.0`) are created on specific, validated commits on the `main` branch. These tags represent a complete, tested, and approved state of the automation intended for a specific environment. A tag bundles together the application code, the required EE definition, and potentially the corresponding AAP configuration state.

### 2. Synchronizing Application Code (Playbooks, Roles, Collections)

- AAP Projects configured for QA and Production environments are set to sync only the specific Git tag corresponding to that environment's release.
- When a promotion is triggered (often via an AAP Workflow), the first step is typically a **Project Sync node** that checks out the designated tag. This ensures that only the code belonging to that specific, tagged release is present for execution in that environment. Untagged changes on `main` or code from other feature branches are not pulled.

### 3. Synchronizing Execution Environments (EEs)

- The definition file for your EE (`execution-environment.yml`) lives in the same Git repository and is versioned along with the code it supports.
- When a code release (represented by a Git tag) requires changes to the EE (e.g., a new collection version specified in `requirements.yml`), a new EE image must be built using `ansible-builder`.
- **Crucially**, this new EE image should be tagged with a version that corresponds to the Git tag (e.g., `my-registry/my-ee:qa-v1.1.0`). This creates an immutable link between the code version and its runtime environment.
- The tagged EE image is pushed to your container registry (Automation Hub, Quay, etc.).
- The AAP Job Template or Workflow for the target environment (QA/Prod) must be configured (often via CaC) to use this specific, version-tagged EE image. AAP will pull this exact image version when the job runs. Setting the pull policy appropriately (e.g., "Always pull container" or "Only pull if not present") ensures the correct image is used.

### 4. Synchronizing AAP Configuration (CaC)

- The Configuration as Code (CaC) definitions for AAP (managed in a separate Git repo or the main one) also follow the same Git tagging strategy for promotion.
- When promoting a release to QA or Prod, the CaC definitions associated with that release tag are applied to the corresponding AAP instance (QA AAP or Prod AAP).
- These CaC definitions ensure that the AAP objects (Projects, Job Templates, Workflows, EE references) are configured correctly for that specific release tag. For example, the QA Job Template definition in CaC will point to the `qa-vX.Y.Z` Git tag in its Project configuration and the `my-registry/my-ee:qa-vX.Y.Z` image in its EE configuration.

### 5. Orchestration with AAP Workflows

AAP Workflows are the engine that drives the synchronized promotion. A typical promotion workflow for QA might look like this:

1. **Trigger**: Manual launch or triggered by the creation of a `qa-vX.Y.Z` Git tag.
2. **Node 1: Sync QA Project**: Syncs the AAP Project using the specific `qa-vX.Y.Z` tag.
3. **Node 2: (Optional) Run QA Tests**: Executes a Job Template containing integration or acceptance tests against the QA environment, using the tagged code and the corresponding version-tagged EE.
4. **Node 3: (Optional) Approval Gate**: Pauses the workflow for manual QA sign-off.
5. **Node 4: Run QA Deployment**: Executes the main deployment Job Template for QA, which uses the tagged code, the version-tagged EE, and targets the QA inventory.

This ensures that each step uses the consistent, tagged set of components for that specific release.

### How This Prevents Unintended Changes

- **Immutable Releases**: Git tags create immutable pointers to specific versions of your codebase, EE definitions, and CaC. Only tagged commits are promoted.
- **Version-Locked EEs**: By tagging EE container images to match code release tags and explicitly referencing these tagged images in AAP Job Templates, you guarantee that the correct runtime environment is used for each release.
- **Targeted Configuration**: CaC ensures that AAP configurations (Project SCM refs, JT EE settings, Inventory targets) are precisely set for each environment based on the promoted tag.
- **Workflow Control**: AAP Workflows enforce the sequence of operations (sync correct tag, run tests, get approval, deploy), preventing steps from being skipped or run with incorrect components.

By tightly coupling the versioning of application code, Execution Environments, and AAP configuration through Git tags and orchestrating the promotion using AAP Workflows, you create a robust system where only fully tested and approved releases move between environments.

---

## Conclusion

By following these steps within the Ansible Automation Platform ecosystem, you can establish a streamlined, reliable, and maintainable lifecycle for your enterprise automation.

---

## References

This guide is based on best practices from official Red Hat and Ansible documentation, Red Hat Communities of Practice, and industry standards. Key resources include:

- [Red Hat CoP - Automation Good Practices](https://redhat-cop.github.io/automation-good-practices/)
- [Ansible Best Practices - Official Documentation](https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html)
- [AAP Configuration as Code](https://www.redhat.com/en/blog/ansible-automation-controller-cac-gitops)
- [Execution Environments Documentation](https://docs.ansible.com/automation-controller/latest/html/userguide/execution_environments.html)
- [Molecule Testing Framework](https://ansible.readthedocs.io/projects/molecule/)
- [Ansible Builder](https://ansible.readthedocs.io/projects/builder/)

---

**Document Version**: 1.0
**Last Updated**: 2025-01-04
**Maintained By**: Platform Engineering Team

