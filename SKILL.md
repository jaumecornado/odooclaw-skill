---
name: odooclaw
description: "Odoo ERP management via odooapi-cli. Use this skill for: (1) Connecting to Odoo and configuring credentials, (2) Listing and describing models (account.move, account.invoice, res.partner, etc.), (3) Searching and reading records, (4) Executing actions and methods in Odoo. Requires odooapi-cli installed (brew install jaumecornado/tap/odooapi)."
---

# Odoo CLI - Management Skill

This skill provides instructions for connecting to and managing an Odoo server using `odooapi-cli`.

## Installation

```bash
brew install jaumecornado/tap/odooapi
```

## Credential Configuration

### Method 1: Explicit flags
```bash
odooapi --base-url https://your-server.odoo.com --db your_database --username your@email.com --password your_password models list
```

### Method 2: Environment variables
```bash
export ODOO_URL="https://your-server.odoo.com"
export ODOO_DB="your_database"
export ODOO_USERNAME="your@email.com"
export ODOO_PASSWORD="your_password"
```

### Method 3: Config file
```bash
odooapi auth set --base-url https://your-server.odoo.com --db your_database --username your@email.com --password your_password
odooapi auth status
```

## Essential Commands

### Verify connection
```bash
odooapi ping
odooapi whoami
```

### Models
```bash
# List models (with filter)
odooapi models list --filter account

# Describe model fields
odooapi fields describe account.move
odooapi fields describe account.invoice
odooapi fields describe res.partner
```

### Records
```bash
# Search records (domain)
odooapi records search account.move --domain '[["state", "=", "posted"]]' --limit 10 --json

# Read specific record
odooapi records read account.move 123 --fields name,date,amount --json

# Search supplier invoices
odooapi records search account.move --domain '[["move_type", "=", "in_invoice"]]' --limit 20 --json
```

### Actions
```bash
# List available actions
odooapi actions list

# Run action
odooapi actions run <action-id> --model account.move --method post
```

## Common Accounting Models

| Model | Description |
|-------|-------------|
| `account.move` | Journal entries / Invoices |
| `account.move.line` | Journal items |
| `account.invoice` | Invoices (legacy) |
| `res.partner` | Contacts / Suppliers |
| `account.payment` | Payments |
| `account.journal` | Journals |
| `account.account` | Chart of accounts |

## Typical Workflow

1. **Connect**: `odooapi auth set ...`
2. **Verify**: `odooapi ping`
3. **Explore models**: `odooapi models list --filter account`
4. **Describe model**: `odooapi fields describe account.move`
5. **Search records**: `odooapi records search ...`
6. **Read details**: `odooapi records read ...`

## Notes

- Use `--json` for machine-readable output
- Complex arguments use JSON syntax: `--domain '[["field", "operator", "value"]]'`
- Supports both Odoo On-Premise and Odoo Online (Enterprise/Community)
