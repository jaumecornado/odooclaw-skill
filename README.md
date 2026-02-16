# odooclaw 🤖📊

Skill para gestionar Odoo ERP mediante `odooapi-cli`.

## Instalación

```bash
# Instalar odooapi-cli
brew install jaumecornado/tap/odooapi

# Configurar credenciales
odooapi auth set \
  --base-url https://tu-servidor.odoo.com \
  --db tu_base_datos \
  --username tu@email.com \
  --password tu_password
```

## Uso Rápido

```bash
# Verificar conexión
odooapi ping
odooapi whoami

# Listar modelos
odooapi models list --filter account

# Buscar facturas
odooapi records search account.move \
  --domain '[["move_type", "=", "in_invoice"]]' \
  --limit 10

# Describir modelo
odooapi fields describe account.move
```

## Documentación

Ver [SKILL.md](./SKILL.md) para guía completa.

## Requisitos

- [odooapi-cli](https://github.com/jaumecornado/odooapi-cli)
- Odoo 12+ (On-Premise u Online)

## Ejemplos

### Buscar proveedores
```bash
odooapi records search res.partner \
  --domain '[["supplier", "=", true]]' \
  --limit 20
```

### Leer factura específica
```bash
odooapi records read account.move 123 \
  --fields name,date,amount,state
```

### Listar asientos contables
```bash
odooapi records search account.move \
  --domain '[["state", "=", "posted"]]' \
  --limit 50 \
  --order date desc
```

---

*"That's what she said!"* — Michael Scott, probablemente
