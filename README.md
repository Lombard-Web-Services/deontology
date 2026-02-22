# License Header Framework (LHF)

### Ethical Licensing & Transparency Framework

**Author:** Thibaut LOMBARD\
**Repository:** https://github.com/Lombard-Web-Services/deontology/ 

**License:** MIT © 2026 Thibaut LOMBARD



## Executive Summary

The **License Header Framework (LHF)** is a professional-grade Bash
utility designed to enforce ethical clarity, authorship transparency,
and structured licensing across software projects.

As artificial intelligence and automated systems increasingly
participate in content and software production, identifying
responsibility and authorship has become more complex. LHF establishes a
verifiable, structured, and auditable framework to document:

> **Who • What • When • Where • Why • How • Exact Timestamp • Tools Used
> • Contributors • Applied License**

LHF promotes intellectual honesty, traceability, and professional
accountability in modern development environments.



## Manifesto

We are living in an era where artificial intelligence is progressively establishing itself across all sectors. This expansion makes it increasingly difficult to identify the true actors who design, build, and publish projects or works.

It is legitimate to refuse that our skills, expertise, or core values be replaced or distorted by systems or individuals lacking competence or integrity. We are facing a loss of reference points: it is becoming more and more challenging to determine who does what, and with what intention.

My personal observation is clear: it is becoming increasingly difficult to distinguish an honest individual from an impostor. It is therefore urgent to restore intellectual honesty.

It is in this spirit that I developed **LHF** — a Bash application capable of generating `.deont` files and automatically adding the appropriate software licenses to each project.

This approach aims to guarantee transparency and traceability by reliably and verifiably documenting:

> **Who • What • When • Where • Why • How • Exact Time • With Which Tools • With Whom • Under Which License**

This project establishes a clear and auditable deontological working framework, designed to restore trust, responsibility, and transparency at the core of technological creation and decision-making processes.

I sincerely hope that this initiative will resonate even at the highest levels, reminding us that ethics and rigor must always precede performance and convenience.



## Core Features

-   Interactive or rapid creation of `.deont` metadata files (JSON
    format)
-   Support for all major licenses (MIT, GPL, Apache, BSD, Creative
    Commons, etc.)
-   Automatic insertion of language-adapted license headers (Python,
    JavaScript, C, C++, HTML, Shell, and 20+ more)
-   Recursive or single-directory processing modes
-   Professional LaTeX report generation with optional PDF export
-   Advanced mode including:
    -   AI usage declaration
    -   Creator role specification
    -   Compliance / managerial notes
-   Automatic detection of previously licensed files
-   Colored terminal output and robust error handling
-   **NEW:** Apply license to single files using external `.deont` configuration
-   **NEW:** Use external `.deont` files from any location



## Technical Architecture

-   100% Portable Bash (POSIX-friendly)
-   Single external dependency: `jq`
-   `set -o pipefail` enabled for strict error propagation
-   Secure JSON and LaTeX escaping
-   Support for 20+ comment syntaxes
-   Automatic temporary file cleanup via trap handlers
-   Modular, maintainable, and extensible codebase



## Installation

``` bash
git clone https://github.com/Lombard-Web-Services/deontology.git 
cd deontology
chmod +x lhf.sh
```

Install dependency:

``` bash
sudo apt install jq
```



## Usage

### Full Interactive Creation

``` bash
./lhf.sh create
```

### Advanced Interactive Mode

``` bash
./lhf.sh create --advanced
```

### One-Line Quick Creation

``` bash
./lhf.sh create -a "Thibaut LOMBARD" -l "MIT" -t "@LICENSE.txt" -y 2026
```

### Apply License Headers

Recursive mode:

``` bash
./lhf.sh apply -e js -r
```

Specific directory:

``` bash
./lhf.sh apply -e py --dir ./src
```

### Apply License to Single File with External .deont

You can apply a license header to a single specific file using an external `.deont` configuration file:

``` bash
./lhf.sh apply -f /path/to/external.deont -e sh --dir ./monfichier.sh
```

This is particularly useful when:
- You want to use a centralized `.deont` file for multiple projects
- You need to license a single file without creating a local `.deont`
- You manage licenses across different directories with shared configuration

**Parameters:**
- `-f /path/to/external.deont` : Path to the external `.deont` configuration file
- `-e sh` : File extension to match (must match the target file)
- `--dir ./monfichier.sh` : Path to the specific file to license

**Example with JavaScript file:**

``` bash
./lhf.sh apply -f .deont -e js --dir ./folder/
```

Or for a specific file:

``` bash
./lhf.sh apply -f ~/.config/lhf/templates/mit.deont -e js --dir ./src/app.js
```

### Generate Professional Report (PDF Only)

``` bash
./lhf.sh report --pdf-only
```



## Changelog

### Version 2.0.7

- **Improved:** Enhanced comment header handling for better compatibility across all supported languages
- **Fixed:** Display issues for C, Python, and CSS language headers
- **Fixed:** Display formatting for HTML, CSS, and JavaScript comment blocks
- **Added:** Single file licensing support — apply license headers to individual files instead of entire directories
- **Added:** External `.deont` file support — use configuration files from any location using the `-f` flag



## Governance Philosophy

LHF is not merely a licensing script.

It is a **deontological governance layer** for software creation.\
Its objectives are to:

-   Reinforce ethical responsibility in development workflows
-   Clarify human and AI contributions
-   Ensure auditability and long-term traceability
-   Elevate professional standards in digital production

Technology must remain accountable. Automation must not replace
integrity.



## Contributing

Contributions are welcome, provided they align with the ethical and
transparency principles of the framework.



## License

Distributed under the MIT License.

© 2026 Thibaut LOMBARD
