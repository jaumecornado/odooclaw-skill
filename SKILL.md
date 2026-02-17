---
name: odooclaw
description: "Odoo ERP management via odooapi-cli. Use this skill for: (1) Connecting to Odoo and configuring credentials, (2) Listing and describing models (account.move, account.invoice, res.partner, etc.), (3) Searching and reading records, (4) Executing actions and methods in Odoo. Requires odooapi-cli installed (brew install jaumecornado/tap/odooapi). CRITICAL: Before creating ANY invoice or accounting entry, you MUST verify accounting rules for the company's country (e.g., PGCE for Spain)."
---

# Odoo CLI - Management Skill

This skill provides instructions for connecting to and managing an Odoo server using `odooapi-cli`.

## Installation

```bash
brew install jaumecornado/tap/odooapi
```

## ⚠️ CRITICAL: Pre-Accounting Validation Protocol

**BEFORE creating ANY invoice, vendor bill, or journal entry in Odoo, you MUST:**

1. **Identify the company's country** (check `res.company` or `res.partner`)
2. **Apply the local accounting standards** for that country
3. **Verify account codes** comply with national regulations
4. **CONSULT THE PGC EXPERT SKILL** before proceeding

### 🔴 MANDATORY: Always Consult Local Accounting Rules

**For ANY accounting operation, you MUST follow this workflow:**

```
1. Identificar el país de la empresa destinataria
2. Consultar las normas contables del país (PGCE para España)
3. Seleccionar las cuentas correctas según el tipo de gasto
4. Validar la deductibilidad del IVA
5. Crear el documento en Odoo
```

**For Spanish companies (PGCE):**

You **MUST** consult the PGCE expert before any accounting operation:

```bash
# Always consult PGCE expert for correct account selection
cd /Users/jaume/.openclaw/workspace-michaelscott/skills/pgc-contable-experto
python3 scripts/pgc_lookup.py --query "<tipo de gasto>"
```

**Common Spanish account mappings:**
- **600-609** - Purchases and expenses
- **621-629** - External services (rent, insurance, repairs)
- **630-639** - Personnel expenses and social security
- **640-649** - Staff costs
- **662** - Interest on debts
- **472** - HP VAT supported (deductible)
- **477** - HP VAT charged

**Validation checklist before posting:**
- [ ] Company country identified and local GAAP applied
- [ ] Account code verified against local accounting plan (PGCE for Spain)
- [ ] VAT treatment validated (deductible/partial/non-deductible)
- [ ] Expense deductibility assessed according to tax law
- [ ] Correct journal selected (purchase/sales/bank/etc.)

**⚠️ NEVER create an invoice or journal entry without completing this checklist!**

**Example workflow:**
1. User asks: "Create a restaurant expense invoice for 50€+VAT"
2. **CONSULT PGCE**: `python3 scripts/pgc_lookup.py --query "restaurante comida negocio"`
3. PGCE response: Account 629 - Other services / NO VAT deductible for restaurants
4. Create invoice in Odoo with validated account
5. Verify the entry is correctly posted

**Never post entries without this validation!**

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
3. **Pre-Accounting Check**: Determine company country → Apply local GAAP (e.g., PGCE for Spain)
4. **Validate accounts**: Consult local accounting rules before creating entries
5. **Explore models**: `odooapi models list --filter account`
6. **Describe model**: `odooapi fields describe account.move`
7. **Create with validation**: Apply verified account codes to all entries
8. **Search/Read records**: `odooapi records search/read ...`

## ⚠️ CRITICAL: Creating Invoices in Draft State (MANDATORY)

**ALL invoices MUST be created in "draft" state for manual validation.** Never auto-post invoices.

### 📝 Mandatory: Draft State Policy

When creating any invoice (vendor bill, customer invoice, credit note), you **MUST**:

1. **Always create in `draft` state** - this is the default, do NOT override it
2. **Never call `action_post` automatically** after creation
3. **Leave validation for manual review** by the user

**Correct behavior:**
```bash
# Create invoice - stays in draft automatically
odooapi records create account.move --json --data '{
  "move_type": "in_invoice",
  "partner_id": 123,
  "invoice_date": "2026-02-17",
  "line_ids": [...]
}'
# Result: Invoice created in "draft" state ✅
```

**❌ NEVER do this:**
```bash
# DON'T auto-post invoices!
odooapi actions run invoice.post --ids 123
# This bypasses manual validation - NOT ALLOWED
```

---

## ⚠️ CRITICAL: Creating Invoices with Tax Calculation

**When creating invoices via API, taxes are NOT calculated automatically** because `onchange` methods don't fire via API calls.

### ✅ CORRECT WAY: Create Invoice with Lines in Single Call

**Always create the invoice with `invoice_line_ids`/`line_ids` in ONE call** to trigger Odoo's internal calculations:

```bash
# Create vendor bill (account.move) with lines - taxes calculate automatically
odooapi records create account.move --json --data '{
  "move_type": "in_invoice",
  "partner_id": 123,
  "invoice_date": "2026-02-17",
  "line_ids": [
    [0, 0, {
      "name": "Consulting services",
      "quantity": 1,
      "price_unit": 100.00,
      "account_id": 627,
      "tax_ids": [[6, 0, [21]]]
    }]
  ]
}'
```

**Key points:**
- Use `line_ids` with format `[[0, 0, {line_data}]]` for Odoo 16+
- Include `tax_ids` in each line: `[[6, 0, [tax_id_1, tax_id_2]]]`
- **Never** create the invoice and lines in separate calls - taxes won't calculate!

### ❌ WRONG WAY (taxes won't calculate)

```bash
# DON'T DO THIS - creates invoice without lines
odooapi records create account.move --data '{"move_type": "in_invoice", "partner_id": 123}'

# Then adding lines separately - taxes will be ZERO!
odooapi records create account.move.line --data '{...}'
```

### Field Mapping Reference

| Odoo Version | Invoice Model | Line Field | Tax Field |
|--------------|---------------|------------|-----------|
| Odoo 16+ | `account.move` | `line_ids` | `tax_ids` |
| Odoo 15- | `account.invoice` | `invoice_line_ids` | `invoice_line_tax_ids` |

**Always verify tax calculation after creating invoices!**

## 🛠️ Helper Scripts

### 1. Check Account Existence (MANDATORY before invoice creation)

**ALWAYS verify the account exists for the target company before creating an invoice:**

```bash
# Check if account exists for company (default: BAZINGA=2)
./scripts/check-account.sh 629000

# Check for specific company
./scripts/check-account.sh 629000 2
```

**Possible outputs:**
- ✅ `CUENTA ENCONTRADA: 629000 - Otros servicios (ID: 382)` → Procede a crear factura
- ❌ `CUENTA NO ENCONTRADA` → Crea la cuenta primero
- ❌ `SIN ACCESO: La cuenta existe pero pertenece a otra compañía` → Crea la cuenta para la compañía objetivo

### 2. Create Account (if doesn't exist)

```bash
# Create an expense account
./scripts/create-account.sh 629000 "Otros servicios" expense

# Create account for specific company
./scripts/create-account.sh 629000 "Otros servicios" expense 2
```

**Common account types:**
- `expense` - Gastos (Grupo 6: 60x-69x)
- `income` - Ingresos (Grupo 7: 70x-79x)
- `asset_fixed` - Inmovilizado (Grupo 2: 21x-28x)
- `asset_current` - Activo corriente (Grupo 3: 30x-39x)
- `liability` - Pasivo (Grupo 4: 40x-49x)

### 3. Create Invoice in Draft

A helper script is provided to ensure invoices are always created in draft state:

```bash
# Use the helper script (recommended)
./scripts/create-invoice-draft.sh \
  --partner-id 123 \
  --date 2026-02-17 \
  --lines '[[0,0,{"name":"Consulting","quantity":1,"price_unit":100}]]' \
  --reference "FAC-001"
```

**Features:**
- ✅ Always creates in **draft** state
- ✅ Validates authentication before creating
- ✅ Provides clear output with invoice ID
- ✅ Reminds user that manual validation is required

---

## 📋 Complete Workflow: Create Invoice with Account Verification

### Step-by-step process (MANDATORY):

```bash
# 1. Identify the correct account based on expense type
#    - Material oficina → 629 (Otros servicios)
#    - Suministros → 628 (Suministros)
#    - Consultoría → 623 (Servicios profesionales)
#    - etc.

# 2. VERIFY account exists for target company
./scripts/check-account.sh 629000 2

# 3. If account doesn't exist, CREATE it
./scripts/create-account.sh 629000 "Otros servicios" expense 2

# 4. CONFIRM account now exists
./scripts/check-account.sh 629000 2

# 5. Create the invoice
./scripts/create-invoice-draft.sh \
  --partner-id 28 \
  --date 2026-02-17 \
  --reference "ES6J9SGAEUI - Amazon Papel A4" \
  --lines '[[0,0,{"name":"Amazon Basics Papel A4","quantity":1,"price_unit":24.79,"account_id":XXX,"tax_ids":[[6,0,[227]]]}]]'
```

### ⚠️ Multi-Company Considerations

**CRITICAL for SaaS Odoo environments:**

1. **Account ownership**: Accounts may belong to a parent company (e.g., PlenaTres) but invoices to a child company (e.g., BAZINGA)
2. **Permission errors**: If you get "ultrasecretos" / "no tiene permiso" errors, the account exists but for another company
3. **Solution**: Create the same account code for the target company

**Error patterns and solutions:**

| Error | Cause | Solution |
|-------|-------|----------|
| `CUENTA NO ENCONTRADA` | Account doesn't exist | Create account with `create-account.sh` |
| `SIN ACCESO` | Account exists for different company | Create account for target company ID |
| `company inconsistencies` | Account vs Invoice company mismatch | Verify account belongs to invoice company |

## Quick Reference: Draft State Checklist

Before executing ANY invoice creation:

- [ ] Confirm invoice should be in **draft** state
- [ ] Do NOT call `action_post` or similar posting actions
- [ ] Verify user will manually validate later
- [ ] Use `create` method only (no auto-posting)

## 📚 Example: Complete Invoice Creation Flow

### Scenario: Amazon Office Supplies Invoice

```bash
# 1. Check if account 629000 exists for BAZINGA (company 2)
./scripts/check-account.sh 629000 2
# Output: ✅ CUENTA ENCONTRADA: 629000 - Other services (ID: 1026)

# 2. If account doesn't exist, create it
./scripts/create-account.sh 629000 "Otros servicios" expense 2

# 3. Create the invoice with full workflow
./scripts/create-invoice-full.sh \
  --partner-id 28 \
  --date 2026-02-17 \
  --account-code 629000 \
  --account-name "Otros servicios" \
  --amount 24.79 \
  --description "Amazon Basics Papel A4 80gsm 2500u" \
  --reference "ES6J9SGAEUI - Amazon Papel A4" \
  --company-id 2

# Expected output:
# ✅ Factura creada exitosamente
#    Número: FACTU/2026/02/0002
#    Estado: BORRADOR
#    Base: 24.79 €
#    IVA: 5.21 €
#    Total: 30.0 €
```

### Common Expense Account Mapping

| Expense Type | PGCE Account | Account Name | Type |
|--------------|--------------|--------------|------|
| Office supplies (paper, etc.) | 629000 | Otros servicios | expense |
| Utilities (water, electricity) | 628000 | Suministros | expense |
| Professional services | 623000 | Servicios profesionales | expense |
| Rent/Lease | 621000 | Arrendamientos y cánones | expense |
| Repairs | 622000 | Reparaciones y conservación | expense |
| Insurance | 625000 | Primas de seguros | expense |
| Advertising | 627000 | Publicidad, propaganda | expense |
| Bank fees | 626000 | Servicios bancarios | expense |

## Notes

- Use `--json` for machine-readable output
- Complex arguments use JSON syntax: `--domain '[["field", "operator", "value"]]'`
- Supports both Odoo On-Premise and Odoo Online (Enterprise/Community)
- **CRITICAL:** All invoices created via this skill MUST remain in draft state for manual validation
- **CRITICAL:** Always verify account exists for target company before creating invoices
- Multi-company environments require accounts to be created per-company or shared via parent company
