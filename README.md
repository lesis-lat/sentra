<p align="center">
  <h3 align="center"><b>Sentra</b></h3>
  <p align="center">The first autonomous source code posture risk score tool</p>
  <p align="center">
    <a href="https://github.com/instriq/sentra/blob/master/LICENSE.md">
      <img src="https://img.shields.io/badge/license-MIT-blue.svg">
    </a>
     <a href="https://github.com/instriq/sentra/releases">
      <img src="https://img.shields.io/badge/version-0.0.3-blue.svg">
    </a>
    <img src="https://github.com/instriq/sentra/actions/workflows/linter.yml/badge.svg">
    <img src="https://github.com/instriq/sentra/actions/workflows/zarn.yml/badge.svg">
    <img src="https://github.com/instriq/sentra/actions/workflows/security-gate.yml/badge.svg">
    <img src="https://img.shields.io/badge/coverage-93.3%25-brightgreen.svg">
  </p>
</p>

---

### Summary

Sentra is a collection of Perl modules designed to help gain speed and increase the maturity of security processes. These modules can be used independently or together to analyze GitHub repositories, manage Dependabot alerts, and send notifications via Slack.

---

### Installation

```bash
# Clone the repository
$ git clone https://github.com/instriq/sentra && cd sentra

# Install Perl module dependencies
$ cpanm --installdeps .
```

---

### Usage

```
$ perl sentra.pl

Sentra v0.0.1
Core Commands
==============
Command                         Description
-------                         -----------
-o, --org                       Specify the name of the organization
-t, --token                     Set the GitHub Token to use during actions
-mt, --maintained               Check last commit date of repositories
-d, --dependency                Check for dependabot.yaml file in repositories
-M, --metrics                   See some metrics based on GHAS
-w, --webhook                   Set the webhook address for Slack
-m, --message                   Message to send via Slack webhook
```

---

### Workflows examples

```yaml
```

---

### Contribution

Your contributions and suggestions are heartily ♥ welcome. [See here the contribution guidelines.](/.github/CONTRIBUTING.md) Please, report bugs via [issues page](https://github.com/instriq/sentra/issues) and for security issues, see here the [security policy.](/SECURITY.md) (✿ ◕‿◕)

---

### License

This work is licensed under [MIT License.](/LICENSE.md)
