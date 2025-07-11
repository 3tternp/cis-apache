# cis-apache

A lightweight Bash-based audit tool to check Apache HTTP Server 2.4 configurations against the [CIS Benchmark v2.2.0](https://www.cisecurity.org/benchmark/apache_http_server). It performs automated security checks and generates a professional HTML report with remediation guidance and an executive summary.

---

## 🚀 Features

- ✅ Automated compliance checks from CIS Apache Benchmark
- 🧪 Evaluates modules, SSL/TLS settings, file permissions, and more
- 📄 Generates a clean and structured HTML report
- 📊 Visual pie chart and executive summary
- 📁 Logs detailed findings with remediation and evidence
- 🖥️ CLI-friendly with clear banner branding

---

## 📦 Requirements

- Bash (Linux or macOS)
- Apache HTTP Server 2.4 installed and configured
- sudo/root access to read Apache configurations and file ownerships

---

## 📂 Output

- `./cis_apache_report/apache_cis_report.html` — the main report file

Example sections included:
- ID and Title of each CIS control
- Risk level (High, Medium, Low)
- Status (Pass/Fail)
- Remediation steps
- Evidence (output of the check)

---

## 🔧 Usage

```bash
# Make the script executable
chmod +x cis_apache_audit.sh

# Run it with root privileges
sudo ./cis_apache_audit.sh


<img width="697" height="133" alt="image" src="https://github.com/user-attachments/assets/d8957a3e-a4ac-41ef-8a89-df08be7e13c9" />

# output 

<img width="1874" height="887" alt="image" src="https://github.com/user-attachments/assets/78fceb0a-0ff4-4b0f-a16e-6393dc00a400" />
