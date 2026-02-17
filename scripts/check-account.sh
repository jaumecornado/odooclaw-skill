#!/bin/bash
#
# check-account.sh - Verifica si una cuenta contable existe para una compañía
# Uso: ./check-account.sh <account_code> [company_id]

set -e

ACCOUNT_CODE="$1"
COMPANY_ID="${2:-2}"  # Por defecto BAZINGA SYSTEMS SL

if [ -z "$ACCOUNT_CODE" ]; then
    echo "Uso: $0 <account_code> [company_id]"
    echo "Ejemplo: $0 629000"
    exit 1
fi

# Verificar autenticación
if ! odooapi ping &> /dev/null; then
    echo "❌ Error: No autenticado en Odoo"
    exit 1
fi

# Buscar la cuenta usando Python para manejar mejor el contexto de compañía
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
    # Buscar cuenta con contexto de la compañía especificada
    accounts = models.execute_kw(db, uid, api_key, 'account.account', 'search_read', 
        [[['code', '=', '$ACCOUNT_CODE']]], 
        {'fields': ['id', 'name', 'code'], 'context': {'allowed_company_ids': [$COMPANY_ID]}})
    
    if accounts:
        acc = accounts[0]
        print(f"✅ CUENTA ENCONTRADA: {acc['code']} - {acc['name']} (ID: {acc['id']})")
        exit(0)
    else:
        print(f"❌ CUENTA NO ENCONTRADA: $ACCOUNT_CODE")
        print(f"   No existe la cuenta '$ACCOUNT_CODE' para la compañía ID $COMPANY_ID")
        exit(1)
except Exception as e:
    error_msg = str(e)
    if "no tiene permiso" in error_msg or "ultrasecretos" in error_msg:
        print(f"❌ SIN ACCESO: La cuenta '$ACCOUNT_CODE' existe pero pertenece a otra compañía")
        print(f"   Error: Permiso denegado para la compañía ID $COMPANY_ID")
    else:
        print(f"❌ ERROR: {error_msg}")
    exit(1)
EOF
