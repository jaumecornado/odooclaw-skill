---
name: odooclaw
description: "Gestión de Odoo ERP mediante odooapi-cli. Usa esta skill para: (1) Conectar con Odoo y configurar credenciales, (2) Listar y describir modelos (account.move, account.invoice, res.partner, etc.), (3) Buscar y leer registros, (4) Ejecutar acciones y métodos en Odoo. Requiere odooapi-cli instalado (brew install jaumecornado/tap/odooapi)."
---

# Odoo CLI - Skill de Gestión

Esta skill proporciona instrucciones para conectar y gestionar un servidor Odoo usando `odooapi-cli`.

## Instalación

```bash
brew install jaumecornado/tap/odooapi
```

## Configuración de Credenciales

### Método 1: Flags explícitos
```bash
odooapi --base-url https://tu-servidor.odoo.com --db tu_base_datos --username tu@email.com --password tu_password models list
```

### Método 2: Variables de entorno
```bash
export ODOO_URL="https://tu-servidor.odoo.com"
export ODOO_DB="tu_base_datos"
export ODOO_USERNAME="tu@email.com"
export ODOO_PASSWORD="tu_password"
```

### Método 3: Archivo de configuración
```bash
odooapi auth set --base-url https://tu-servidor.odoo.com --db tu_base_datos --username tu@email.com --password tu_password
odooapi auth status
```

## Comandos Esenciales

### Verificar conexión
```bash
odooapi ping
odooapi whoami
```

### Modelos
```bash
# Listar modelos (con filtro)
odooapi models list --filter account

# Describir campos de un modelo
odooapi fields describe account.move
odooapi fields describe account.invoice
odooapi fields describe res.partner
```

### Registros
```bash
# Buscar registros (domain)
odooapi records search account.move --domain '[["state", "=", "posted"]]' --limit 10 --json

# Leer registro específico
odooapi records read account.move 123 --fields name,date,amount --json

# Buscar facturas de proveedor
odooapi records search account.move --domain '[["move_type", "=", "in_invoice"]]' --limit 20 --json
```

### Acciones
```bash
# Listar acciones disponibles
odooapi actions list

# Ejecutar acción
odooapi actions run <action-id> --model account.move --method post
```

## Modelos Comunes para Contabilidad

| Modelo | Descripción |
|--------|-------------|
| `account.move` | Asientos contables / Facturas |
| `account.move.line` | Líneas de asiento |
| `account.invoice` | Facturas (legacy) |
| `res.partner` | Contactos / Proveedores |
| `account.payment` | Pagos |
| `account.journal` | Diarios contables |
| `account.account` | Plan de cuentas |

## Flujo de Trabajo Típico

1. **Conectar**: `odooapi auth set ...`
2. **Verificar**: `odooapi ping`
3. **Explorar modelos**: `odooapi models list --filter account`
4. **Describir modelo**: `odooapi fields describe account.move`
5. **Buscar registros**: `odooapi records search ...`
6. **Leer detalles**: `odooapi records read ...`

## Notas

- Usar `--json` para salida procesable programmatically
- Los argumentos complejos usar sintaxis JSON: `--domain '[["field", "operator", "value"]]'`
- Soporta tanto Odoo On-Premise como Odoo Online (Enterprise/Community)
