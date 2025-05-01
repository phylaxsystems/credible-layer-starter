# Credible Layer Example Project

This repository provides a minimal example of a Credible Layer assertion setup, designed to demonstrate the fundamental structure and implementation of assertions in a project.

## Overview

This project serves as a template for implementing Credible Layer assertions. You can use this structure as a foundation for your own projects. The content is based on the [Credible Layer Quickstart Guide](https://docs.phylax.systems/credible/pcl-quickstart).

For additional examples and detailed documentation, please refer to:

- [Assertion Examples Repository](https://github.com/phylaxsystems/assertion-examples)
- [Assertions Book](https://docs.phylax.systems/assertions-book/assertions-book-intro)

## Prerequisites

Before getting started, ensure you have:

- Phylax Credible CLI (`pcl`) installed
  - Follow the [Credible Layer Installation Guide](https://docs.phylax.systems/credible/credible-install)
  - Alternatively, install directly using:

    ```bash
    cargo install --git https://github.com/phylaxsystems/pcl
    ```

## Getting Started

### Clone the Repository

This repository uses Git submodules. Clone it using:

```bash
git clone --recurse-submodules https://github.com/phylaxsystems/credible-layer-starter.git
```

If you've already cloned without submodules, initialize them with:

```bash
git submodule update --init --recursive
```

### Project Setup

The project comes pre-configured with:

- `credible-std`: Core Credible Layer functionality
- `forge-std`: Forge standard library that we rely on for testing

Install any additional dependencies your project requires.

## Testing Assertions

Run the test suite using:

```bash
pcl test
```

This command executes tests located in the `assertions/test` directory.

## Additional Resources

For comprehensive documentation on the Credible Layer CLI, including:

- Writing assertions
- Testing procedures
- Storing and submitting assertions
- Creating test transactions

Please refer to the [Credible Layer Quickstart Guide](https://docs.phylax.systems/credible/pcl-quickstart).
