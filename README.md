# 🛡️ Cyber Recon Toolkit

A simple and powerful Bash-based reconnaissance tool for penetration testers and bug bounty hunters.

**Developed by:**  
Abdulkarim Ramzi, Khaled Jaradeh, Rami Safi, Hasan Alqudra

---

## 🚀 Description

Cyber Recon Toolkit is a Bash script that automates common reconnaissance tasks during penetration testing. It includes subdomain enumeration, port and service scanning, vulnerability detection, and endpoint discovery using tools like `subfinder`, `httpx`, `waybackurls`, and `nmap`.

---
## 📦 Requirements

Make sure the following tools are installed on your system:

- [subfinder](https://github.com/projectdiscovery/subfinder)
- [jq](https://stedolan.github.io/jq/)
- [httpx](https://github.com/projectdiscovery/httpx)
- [waybackurls](https://github.com/tomnomnom/waybackurls)
- [nmap](https://nmap.org/)
- `dig` (usually comes with the `dnsutils` package)

### Installation example (Ubuntu/Debian):

```bash
sudo apt install -y nmap dnsutils jq
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
go install -v github.com/tomnomnom/waybackurls@latest
```


### 📂 Directory Structure

After execution, the script creates the following directory structure under your home folder:

```bash
~/recon/
└── example.com/
    ├── subdomain/
    │   ├── subdomains.txt
    │   └── live.txt
    └── endpoint/
        └── waybackurls.txt
```

### Usage
```
bash cyberrecon.sh [options]
```

Available Options:
| Option      | Description                                           |
| ----------- | ----------------------------------------------------- |
| `-r domain` | Run subdomain enumeration using subfinder + crt.sh    |
| `-w domain` | Gather historical endpoints using Wayback Machine     |
| `-n target` | Scan open ports and services using Nmap               |
| `-v target` | Scan for known vulnerabilities (Nmap scripts)         |
| `-l domain` | Filter live subdomains using httpx                    |
| `-a domain` | Run full recon: subdomains + scan + vulns + endpoints |


### Examples

```
# Subdomain enumeration
bash cyberrecon.sh -r example.com

# Filter live subdomains
bash cyberrecon.sh -l example.com

# Gather endpoints from Wayback Machine
bash cyberrecon.sh -w example.com

# Scan for open ports
bash cyberrecon.sh -n 93.184.216.34

# Find known vulnerabilities
bash cyberrecon.sh -v 93.184.216.34

# Full recon on a target
bash cyberrecon.sh -a example.com
```
