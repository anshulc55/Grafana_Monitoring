
# 🚀 Install and Configure Grafana Loki as a Systemd Service on Ubuntu

> This guide walks you through installing Grafana Loki on Ubuntu, configuring it, and setting it up as a systemd service so it runs automatically on boot.

---

## ✅ Prerequisites

Make sure you have:
- Ubuntu 20.04+ (or compatible)
- `curl`, `wget`, or `apt` installed
- `sudo` privileges

---

## 📥 Step 1: Download the Latest Loki Binary

```bash
# Directory for Loki
sudo mkdir -p /opt/loki
cd /opt/loki

# Download the latest release (replace version if needed)
wget https://github.com/grafana/loki/releases/latest/download/loki-linux-amd64.zip

# Unzip the binary
sudo apt install unzip -y
unzip loki-linux-amd64.zip

# Rename it to 'loki' for simplicity
mv loki-linux-amd64 loki

# Make it executable
chmod a+x loki
```

---

## 📥 Step 2: Configure Loki

```bash
# Download Configuration File
cd /opt/loki
wget https://raw.githubusercontent.com/grafana/loki/main/cmd/loki/loki-local-config.yaml
mv loki-local-config.yaml loki-config.yaml
```

---

## 📥 Step 3: Create Systemd Service

```bash
# Create user for loki (optional but recommended)
sudo useradd --system --home /opt/loki --shell /bin/false loki

# Change ownership of Loki files
sudo chown -R loki:loki /opt/loki

# Create a Systemd Service for Loki
sudo vi /etc/systemd/system/loki.service
```

### File Content:

```ini
[Unit]
Description=Grafana Loki Log Aggregator
After=network.target

[Service]
User=loki
Group=loki
Type=simple
ExecStart=/opt/loki/loki -config.file=/opt/loki/loki-config.yaml
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

---

## 📥 Step 5: Start and Enable the Loki Service

```bash
# Reload systemd to recognize the service
sudo systemctl daemon-reload

# Enable and start the service
sudo systemctl enable loki
sudo systemctl start loki

# Check the status
sudo systemctl status loki
```

---

## 📥 Step 6: Verify Loki is Running

```bash
curl http://localhost:3100/ready
curl http://localhost:3100/metrics
```

---

## Optional: Add UFW Rule (if firewall is enabled)

```bash
sudo ufw allow 3100/tcp
```
