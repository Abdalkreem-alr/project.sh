#!/bin/bash

# ألوان للإخراج
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

print_banner() {
    echo -e "${GREEN}"
    echo "██████╗   ██████╗      ██████╗        ██╗    ███████╗  ██████╗  ████████╗"
    echo "██╔══██╗ ██╔   ██║    ██╔═══██╗       ██║    ██╔════╝ ██╔════╝  ╚══██╔══╝"
    echo "██████╔╝ ██╔██╔██║    ██║   ██║       ██║    █████╗   ██║          ██║   "
    echo "██╔═══╝  ██╔   ██║    ██║   ██║       ██║    ██╔══╝   ██║          ██║   "
    echo "██║      ██╔    ██║   ╚██████╔╝║██    ██║    ███████╗ ╚██████╗     ██║   "
    echo "╚═╝      ╚════════╝             ╚█████╔╝     ╚══════╝  ╚═════╝     ╚═╝   "
    echo -e "${NC}"
    echo -e "${GREEN}Cyber Recon Toolkit by Abdulkarim Ramzi, Khaled Jaradeh, Rami Safi, Hasan Alqudra${NC}\n"
}

print_banner


usage() {
    echo -e "${GREEN}Usage: $0 [-r domain] [-n domain] [-v domain] [-a domain] [-l domain] [-w domain] ${NC}"
    echo "  -r domain    Run subdomain_enum (Subdomain Enumeration)"
    echo "  -w domain    scan endpoint"
    echo "  -n domain    Scan for open ports and running services"
    echo "  -v domain    Search for known vulnerabilities"
    echo "  -l domain    Filter live domains using httpx"
    echo "  -a domain    Run all: subdomain_enum + Services + Vulnerabilities"
    echo "  -d domain    Get DNS A, CNAME, and TXT records"
    exit 1
}


# دالة لجمع Subdomains
subdomain_enum() {
    domain=$1
    echo -e "${GREEN}[+] Running Subdomain Enumeration on $domain using subfinder and crt.sh...${NC}"

    # التحقق من الأدوات
    output_dir=~/recon/$domain/subdomain
    mkdir -p "$output_dir"

    if ! command -v subfinder &>/dev/null; then
        echo -e "${RED}[-] subfinder not found. Please install it.${NC}"
        return
    fi

    if ! command -v jq &>/dev/null; then
        echo -e "${RED}[-] jq not found. Please install it.${NC}"
        return
    fi

    # تنفيذ subfinder
    echo "[*] Using subfinder..."
    subfinder -d "$domain" --silent -o "$output_dir/subfinder.txt"

    # تنفيذ crt.sh
    echo "[*] Using crt.sh..."
    curl -s "https://crt.sh/?q=%25.$domain&output=json" | jq -r '.[].name_value' | sort -u > "$output_dir/crt.txt"

    # دمج النتائج
    echo "[*] Merging and deduplicating results..."
    cat "$output_dir/subfinder.txt" "$output_dir/crt.txt" | sort -u > "$output_dir/subdomains.txt"
    echo -e "${GREEN}[+] Done! Results saved to $output_dir/subdomains.txt${NC}"

    # حذف المؤقتات
    rm -f "$output_dir/subfinder.txt" "$output_dir/crt.txt"
}

filter_live_domains() {
    domain=$1
    input_file=~/recon/$domain/subdomain/subdomains.txt
    output_file=~/recon/$domain/subdomain/live.txt

    echo -e "${GREEN}[+] Filtering live domains for: $domain${NC}"

    if ! command -v httpx &>/dev/null; then
        echo -e "${RED}[-] httpx not found. Please install it.${NC}"
        return 1
    fi

    if [[ ! -f "$input_file" || ! -s "$input_file" ]]; then
        echo -e "${YELLOW}[!] Subdomains file missing or empty.${NC}"
        read -p "❓ Do you want to run subdomain_enum now? (y/n): " confirm
        if [[ $confirm == "y" || $confirm == "Y" ]]; then
            subdomain_enum "$domain"
        else
            echo -e "${RED}[-] Operation cancelled. Please run '-r' first.${NC}"
            return 1
        fi
    fi

    if [[ ! -s "$input_file" ]]; then
        echo -e "${RED}[-] Still no subdomains found. Aborting.${NC}"
        return 1
    fi

    httpx1 -silent -l "$input_file" -o "$output_file"

    count=$(wc -l < "$output_file")
    echo -e "${GREEN}[+] Found $count live domains. Results saved to $output_file${NC}"
}
gather_endpoints() {
    domain=$1
    echo -e "${GREEN}[+] Gathering endpoints for $domain using waybackurls and gau...${NC}"

    # تحقق من توفر الأدوات
    if ! command -v waybackurls &>/dev/null; then
        echo -e "${RED}[-] waybackurls not found. Please install it.${NC}"
        return 1
    fi

    subdomains_file=~/recon/$domain/subdomain/subdomains.txt
    output_dir=~/recon/$domain/endpoint
    output_file="$output_dir/waybackurls.txt"
    mkdir -p "$output_dir"

    # التحقق من ملف subdomains
    if [[ ! -f "$subdomains_file" || ! -s "$subdomains_file" ]]; then
        echo -e "${YELLOW}[!] Subdomains file missing or empty for $domain.${NC}"
        read -p "❓ Do you want to run subdomain_enum now? (y/n): " confirm
        if [[ $confirm == "y" || $confirm == "Y" ]]; then
            subdomain_enum "$domain"
        else
            echo -e "${RED}[-] Operation cancelled. Please run '-r' first to collect subdomains.${NC}"
            return 1
        fi
    fi

    # إعادة التحقق بعد تشغيل subdomain_enum
    if [[ ! -s "$subdomains_file" ]]; then
        echo -e "${RED}[-] Still no subdomains found after running subdomain_enum. Aborting.${NC}"
        return 1
    fi

    echo -e "${GREEN}[*] Fetching URLs from $(wc -l < "$subdomains_file") subdomains...${NC}"
    cat "$subdomains_file" | waybackurls > "$output_file"

    # دمج مع gau إن وجدت
    if command -v gau &>/dev/null; then
        cat "$subdomains_file" | gau --threads 50 >> "$output_file"
        sort -u "$output_file" -o "$output_file"
        echo -e "${GREEN}[+] Merged with gau results.${NC}"
    fi

    # تصفية الملفات الغير مهمة
    grep -vE '\.(jpg|jpeg|png|gif|svg|css|woff|woff2|ttf|eot|ico)$' "$output_file" | sort -u > "$output_dir/filtered.txt"

    # تقسيم حسب النوع
    grep '\.js' "$output_file" > "$output_dir/js.txt"
    grep '\.php' "$output_file" > "$output_dir/php.txt"
    grep '\.aspx\|\.asp' "$output_file" > "$output_dir/aspx.txt"
    grep -E '\.json|\.xml' "$output_file" > "$output_dir/api.txt"

    # استخراج المعاملات
    cat "$output_file" | grep '?' | cut -d '?' -f2 | cut -d '&' -f1 | cut -d '=' -f1 | sort -u > "$output_dir/parameters.txt"

    # طباعة الإحصائيات
    count=$(wc -l < "$output_file")
    filtered=$(wc -l < "$output_dir/filtered.txt")
    echo -e "${GREEN}[+] Total endpoints: $count | Filtered: $filtered${NC}"
    echo -e "${GREEN}[+] Saved to $output_dir${NC}"
}




# دالة لفحص الخدمات
scan_services() {
    target=$1
    echo -e "${GREEN}[+] Scanning $target for open ports and services...${NC}"
    nmap -sV "$target"
}

# اضافة دالة ال DNS وذلك لتسهيل معرفة ال IP Origin وايضا لمعرفة استغلال ثغرة ال subdomain tackeover 

dns_records() {
    domain=$1
    output_dir=~/recon/$domain/dns
    output_file="$output_dir/dns_records.txt"

    mkdir -p "$output_dir"

    echo -e "${GREEN}[+] Gathering A, CNAME, and TXT records for $domain...${NC}"

    {
        echo "=== A Record ==="
        dig +short A "$domain"
        echo ""

        echo "=== CNAME Record ==="
        dig +short CNAME "$domain"
        echo ""

        echo "=== TXT Record ==="
        dig +short TXT "$domain"
    } > "$output_file"

    echo -e "${GREEN}[+] DNS records saved to $output_file${NC}"
}
# دالة للثغرات
find_vulnerabilities() {
    target=$1
    echo -e "${GREEN}[+] Scanning $target for known vulnerabilities...${NC}"
    nmap -sV --script vuln "$target"
}

# التحقق من المعطيات
if [[ $# -lt 2 ]]; then
    usage
fi

while getopts ":r:n:v:a:w:l:d:" opt; do
    case $opt in
        r)
            subdomain_enum "$OPTARG"
            ;;
        l)
            filter_live_domains "$OPTARG"
            ;;
        n)
            scan_services "$OPTARG"
            ;;
        v)
            find_vulnerabilities "$OPTARG"       
            ;;

        w)
            gather_endpoints "$OPTARG"
             ;;
        d)
            dns_records "$OPTARG"
            ;;
        a)
            domain="$OPTARG"
            ip=$(dig +short "$domain" | tail -n1)
            echo -e "${GREEN}[*] Domain: $domain => IP: $ip${NC}"
            subdomain_enum "$domain"
            scan_services "$ip"
            find_vulnerabilities "$ip"
            gather_endpoints "$domain"
            ;;
        *)
            usage
            ;;
    esac
done
