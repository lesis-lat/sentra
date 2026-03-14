<p align="center">
  <h3 align="center"><b>Sentra</b></h3>
  <p align="center">The first autonomous source code posture risk score tool</p>
  <p align="center">
    <a href="https://github.com/lesis-lat/sentra/blob/master/LICENSE.md">
      <img src="https://img.shields.io/badge/license-MIT-blue.svg">
    </a>
     <a href="https://github.com/lesis-lat/sentra/releases">
      <img src="https://img.shields.io/badge/version-0.0.2-blue.svg">
    </a>
    <img src="https://github.com/lesis-lat/sentra/actions/workflows/linter.yml/badge.svg">
    <img src="https://github.com/lesis-lat/sentra/actions/workflows/zarn.yml/badge.svg">
    <img src="https://github.com/lesis-lat/sentra/actions/workflows/security-gate.yml/badge.svg">
  </p>
</p>

---

### Summary

Sentra is a collection of Perl modules designed to help gain speed and increase the maturity of security processes. These modules can be used independently or together to analyze GitHub repositories, manage Dependabot alerts, and send notifications via Slack.

---

### Installation

```bash
# Clone the repository
$ git clone https://github.com/lesis-lat/sentra && cd sentra

# Install Perl module dependencies
$ cpanm --installdeps .
```

---

### Usage

`perl sentra.pl` without flags exits with code `1` and produces no output.
Use `-h` to print the help text:

```
$ perl sentra.pl -h

Sentra v0.0.1
Core Commands
==============
Command                         Description
-------                         -----------
-o, --org                       Specify the name of the organization
-r, --repo                      Scan only one repository (use with --org)
-t, --token                     Set the GitHub Token to use during actions
-mt, --maintained               Get alerts about repositories with a last commit date greater than 90 days old
-d, --dependency                Check if repositories has dependabot.yaml file
-M, --metrics                   Show all security alert metrics (dependabot, secret, code)
--metrics-dependabot            Show only Dependabot alert metrics
--metrics-secret                Show only Secret Scanning alert metrics
--metrics-code                  Show only Code Scanning alert metrics
--static-analysis               Check repositories for security tools (SAST, secret scanning, SCA)
-w, --webhook                   Set the webhook address for Slack
-m, --message                   Message to send via Slack webhook
```

Run checks individually:

```bash
perl sentra.pl --org <org> --token <token> --dependency
perl sentra.pl --org <org> --token <token> --maintained
perl sentra.pl --org <org> --token <token> --metrics
perl sentra.pl --org <org> --token <token> --metrics-dependabot
perl sentra.pl --org <org> --token <token> --metrics-secret
perl sentra.pl --org <org> --token <token> --metrics-code
perl sentra.pl --org <org> --token <token> --static-analysis

# optional: target a single repository
perl sentra.pl --org <org> --repo <repo-name> --token <token> --metrics
```

---

### Workflows examples

```yaml
```

---

### Contribution

Your contributions and suggestions are heartily ♥ welcome. Please report bugs via the [issues page](https://github.com/lesis-lat/sentra/issues), and for security issues see the [security policy](/SECURITY.md). (✿ ◕‿◕)

---

### License

This work is licensed under [MIT License.](/LICENSE.md)
