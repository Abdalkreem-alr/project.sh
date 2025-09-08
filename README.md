# 🛡️ Cyber Recon Toolkit

A simple and powerful Bash-based reconnaissance tool for penetration testers and bug bounty hunters.

**Developed by:**  
Abdulkarim Ramzi, Khaled Jaradeh, Rami Safi, Hasan Alqudra

---

## 🚀 Description

Cyber Recon Toolkit is a Bash script that automates common reconnaissance tasks during penetration testing. It includes subdomain enumeration, port and service scanning,  and endpoint discovery using tools like `subfinder`, `httpx`, `waybackurls`, and `naabu`.

---
## 📦 Requirements

Make sure the following tools are installed on your system:

- [subfinder](https://github.com/projectdiscovery/subfinder)
- [jq](https://stedolan.github.io/jq/)
- [httpx](https://github.com/projectdiscovery/httpx)
- [waybackurls](https://github.com/tomnomnom/waybackurls)
- [naabu](https://github.com/projectdiscovery/naabu)/)
- `dig` (usually comes with the `dnsutils` package)

### Installation example (Ubuntu/Debian):

```bash
sudo apt install -y nmap dnsutils jq
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
go install -v github.com/tomnomnom/waybackurls@latest
go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
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
    |    └── waybackurls.txt
    └── dns_records/
    |    └── domain.txt    
    └── Scan_service
         └── domsin.txt

```

### Usage
```
bash RScan.sh [options]
```

Available Options:
| Option      | Description                                           |
| ----------- | ----------------------------------------------------- |
| `-r domain` | Run subdomain enumeration using subfinder + crt.sh    |
| `-w domain` | Gather historical endpoints using Wayback Machine     |
| `-n target` | Scan open ports and services using naabu              |
| `-l domain` | Filter live subdomains using httpx                    |
| `-d domain` | Get DNS A, CNAME, and TXT records                     |
| `-h `       | help                                                  |


### Examples

##### Subdomain enumeration
```
./RScan.sh -r example.com
```
##### Filter live subdomains
```
./RScan.sh -l example.com
```
##### Gather endpoints from Wayback Machine
```
./RScan.sh -w example.com
```

##### Scan for open ports
```
./RScan.sh -n 93.184.216.34
```

##### find record dns
```
./RScan.sh -d example.com
```
