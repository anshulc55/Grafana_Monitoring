
# Log Stream Selectors

## Operators

| Operator | Description               |
|----------|---------------------------|
| =        | equals                    |
| !=       | not equals                |
| =~       | regex matches             |
| !~       | regex does not match      |

## Examples

**Return all log lines for the job `varlog`:**
```logql
{job="varlogs"}
```

**Return all log lines for the filename `/var/log/syslog`:**
```logql
{filename="/var/log/syslog"}
```

**Return all log lines for the job `varlogs` and the filename `/var/log/auth.log`:**
```logql
{filename="/var/log/auth.log", job="varlogs"}
```

**Show all log lines for 2 jobs with different names:**
```logql
{filename=~"/var/log/auth.log|/var/log/syslog"}
```

**Show everything you have using regex:**
```logql
{filename=~".+"}
```

**Show data from all filenames, except for syslog:**
```logql
{filename=~".+", filename!="/var/log/syslog"}
```

---

# Filter Expressions

Used for testing **text content within** log lines after they are selected.

## Operators

| Operator | Description               |
|----------|---------------------------|
| |=       | equals                    |
| !=       | not equals                |
| |~       | regex matches             |
| !~       | regex does not match      |

## Examples

**Return lines including the text `"error"`:**
```logql
{job="varlogs"} |= "error"
```

**Return lines not including the text `"error"`:**
```logql
{job="varlogs"} != "error"
```

**Return lines including `"error"` or `"info"` using regex:**
```logql
{job="varlogs"} |~ "error|info"
```

**Return lines not including `"error"` or `"info"` using regex:**
```logql
{job="varlogs"} !~ "error|info"
```

**Return lines including `"error"` but not including `"info"`:**
```logql
{job="varlogs"} |= "error" != "info"
```

**Return lines including `"Invalid user"` and also `"bob"` or `"redis"` using regex:**
```logql
{job="varlogs"} |~ "Invalid user (bob|redis)"
```

**Return lines including `"status 403"` or `"status 503"` using regex:**
```logql
{job="varlogs"} |~ "status [45]03"
```
