
# 📦 Promtail Installation & Configuration on Ubuntu (Systemd Service)

Promtail is an agent which ships the contents of local logs to a Loki instance or Grafana Cloud. It is usually deployed to every machine that has applications needed to be monitored.

---

## 🧰 Prerequisites

- Ubuntu 20.04 / 22.04
- `curl` or `wget`
- Grafana Loki instance ready

---

## 🔽 Step 1: Download Promtail Binary

```bash
# Create a directory for promtail
sudo mkdir -p /opt/promtail
cd /opt/promtail

# Download latest Promtail release (update version as needed)
wget https://github.com/grafana/loki/releases/latest/download/promtail-linux-amd64.zip

# Unzip the downloaded file
sudo apt install unzip -y
unzip promtail-linux-amd64.zip

# Make it executable
chmod +x promtail-linux-amd64

# Rename for convenience
mv promtail-linux-amd64 promtail
```

---

## 📥 Step 2: Configure PromTail

```bash
# Download Configuration File
cd /opt/promtail
wget https://raw.githubusercontent.com/grafana/loki/main/clients/cmd/promtail/promtail-local-config.yaml
mv promtail-local-config.yaml promtail-config.yaml

# Create a Position File (Used by Promtail to track where it left off)
touch /opt/promtail/positions.yaml
```

Update the file path in the `promtail-config.yaml` accordingly.

---

## 🛠️ Step 3: Create a Systemd Service File for Promtail

```bash
sudo vi /etc/systemd/system/promtail.service
```

### File Content:

```ini
[Unit]
Description=Promtail Service
After=network.target

[Service]
Type=simple
ExecStart=/opt/promtail/promtail -config.file=/opt/promtail/promtail-config.yaml
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

---

## ✅ Step 5: Enable and Start the Promtail Service

```bash
# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable the service to start on boot
sudo systemctl enable promtail

# Start Promtail
sudo systemctl start promtail

# Check status
sudo systemctl status promtail
```

---

## 🧪 Step 6: Verify Logs Are Being Sent to Loki

```bash
curl http://localhost:3100/ready
curl http://localhost:3100/metrics
```
