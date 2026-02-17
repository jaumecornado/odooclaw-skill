#!/bin/bash
#
# create-account.sh - Crea una cuenta contable para una compañía
# Uso: ./create-account.sh <account_code> <account_name> <account_type> [company_id]

set -e

ACCOUNT_CODE="$1"
ACCOUNT_NAME="$2"
ACCOUNT_TYPE="$3"  # expense, asset, liability, etc.
COMPANY_ID="${4:-2}"  # Por defecto BAZINGA SYSTEMS SL

if [ -z "$ACCOUNT_CODE" ] || [ -z "$ACCOUNT_NAME" ] || [ -z "$ACCOUNT_TYPE" ]; then
    echo "Uso: $0 <account_code> <account_name> <account_type> [company_id]"
    echo ""
    echo "Tipos de cuenta disponibles:"
    echo "  - expense      (Gastos - Grupo 6)"
    echo "  - asset_fixed  (Inmovilizado material - Grupo 2)"
    echo "  - asset_current (Activo corriente - Grupo 3)"
    echo "  - liability    (Pasivo - Grupo 4)"
    echo "  - equity       (Patrimonio neto - Grupo 1)"
    echo "  - income       (Ingresos - Grupo 7)"
    echo ""
    echo "Ejemplo: $0 629000 'Otros servicios' expense"
    exit 1
fi

# Verificar autenticación
if ! odooapi ping &> /dev/null; then
    echo "❌ Error: No autenticado en Odoo"
    exit 1
fi

echo "🔍 Verificando si la cuenta ya existe..."

# Primero verificar si existe
python3 << EOF
import xmlrpc.client
import json

url = "https://plenatres.odoo.com"
db = "plenatres"
username = "jcornado@me.com"
api_key = "4666ccf0ced4fb5465d1e1ee4c65e881d83a3654"

common = xmlrpc.client.ServerProxy(f'{url}/xmlrpc/2/common')
uid = common.authenticate(db, username, api_key, {})

models = xmlrpc.client.ServerProxy(f'{url}/xmlrpc/2/object')

# Verificar si existe
existing = models.execute_kw(db, uid, api_key, 'account.account', 'search', 
    [[['code', '=', '$ACCOUNT_CODE']]], 
    {'context': {'allowed_company_ids': [$COMPANY_ID]}})

if existing:
    print(f"⚠️  La cuenta $ACCOUNT_CODE ya existe con ID {existing[0]}")
    print("   No es necesario crearla.")
    exit(0)

print(f"✅ La cuenta $ACCOUNT_CODE no existe. Procediendo a crearla...")
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "📝 Datos de la nueva cuenta:"
    echo "   Código: $ACCOUNT_CODE"
    echo "   Nombre: $ACCOUNT_NAME"
    echo "   Tipo: $ACCOUNT_TYPE"
    echo "   Compañía ID: $COMPANY_ID"
    echo ""
    
    read -p "¿Crear esta cuenta? (s/N): " confirm
    if [[ $confirm =~ ^[Ss]$ ]]; then
        python3 << EOF
import xmlrpc.client
import json

url = "https://plenatres.odoo.com"
db = "plenatres"
username = "jcornado@me.com"
api_key = "4666ccf0ced4fb5465d1e1ee4c65e881d83a3654"

common = xmlrpc.client.ServerProxy(f'{url}/xmlrpc/2/common')
uid = common.authenticate(db, username, api_key, {})

models = xmlrpc.client.ServerProxy(f'{url}/xmlrpc/2/object')

try:
    # Crear la cuenta
    account_data = {
        'code': '$ACCOUNT_CODE',
        'name': '$ACCOUNT_NAME',
        'account_type': '$ACCOUNT_TYPE',
    }
    
    account_id = models.execute_kw(db, uid, api_key, 'account.account', 'create', [account_data],
        {'context': {'allowed_company_ids': [$COMPANY_ID]}})
    
    print(f"✅ Cuenta creada exitosamente con ID: {account_id}")
    print(f"   Código: $ACCOUNT_CODE")
    print(f"   Nombre: $ACCOUNT_NAME")
    print(f"   Tipo: $ACCOUNT_TYPE")
    
except Exception as e:
    print(f"❌ Error al crear cuenta: {e}")
    exit(1)
EOF
    else
        echo "❌ Creación cancelada por el usuario"
        exit 1
    fi
fi
