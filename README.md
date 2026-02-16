# odooclaw 🤖📊

Skill for managing Odoo ERP using `odooapi-cli`.

## Installation

```bash
# Install odooapi-cli
brew install jaumecornado/tap/odooapi

# Configure credentials
odooapi auth set \
  --base-url https://your-server.odoo.com \
  --db your_database \
  --username your@email.com \
  --password your_password
```

## Quick Start

```bash
# Verify connection
odooapi ping
odooapi whoami

# List models
odooapi models list --filter account

# Search invoices
odooapi records search account.move \
  --domain '[["move_type", "=", "in_invoice"]]' \
  --limit 10

# Describe model
odooapi fields describe account.move
```

## Documentation

See [SKILL.md](./SKILL.md) for complete guide.

## Requirements

- [odooapi-cli](https://github.com/jaumecornado/odooapi-cli)
- Odoo 12+ (On-Premise or Online)

## Examples

### Search suppliers
```bash
odooapi records search res.partner \
  --domain '[["supplier", "=", true]]' \
  --limit 20
```

### Read specific invoice
```bash
odooapi records read account.move 123 \
  --fields name,date,amount,state
```

### List journal entries
```bash
odooapi records search account.move \
  --domain '[["state", "=", "posted"]]' \
  --limit 50 \
  --order date desc
```

---

*"That's what she said!"* — Michael Scott, probably
