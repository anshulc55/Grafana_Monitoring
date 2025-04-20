# 📘 MySQL Logging and Grafana Dashboard Setup (Using Promtail + Loki)

## 🧱 Step 1: Configure MySQL Logging (if not already done)

Make sure MySQL logging is enabled. Edit `my.cnf` or `my.ini`:

```ini
[mysqld]
general_log = 1
general_log_file = /var/log/mysql/mysql.log

slow_query_log = 1
slow_query_log_file = /var/log/mysql/mysql-slow.log
long_query_time = 1
log_error = /var/log/mysql/mysql-error.log
```

Then restart MySQL:

```bash
sudo systemctl restart mysql
```

---

## 🔧 Step 2: Configure Promtail to Scrape MySQL Logs

Edit your `promtail-config.yaml` and add the following under `scrape_configs:`:

```yaml
scrape_configs:
  - job_name: mysql-general
    static_configs:
      - targets:
          - localhost
        labels:
          job: mysql
          log_type: general
          __path__: /var/log/mysql/mysql.log

  - job_name: mysql-slow
    static_configs:
      - targets:
          - localhost
        labels:
          job: mysql
          log_type: slow
          __path__: /var/log/mysql/mysql-slow.log

  - job_name: mysql-error
    static_configs:
      - targets:
          - localhost
        labels:
          job: mysql
          log_type: error
          __path__: /var/log/mysql/mysql-error.log
```

Then restart Promtail:

```bash
sudo systemctl restart promtail
```