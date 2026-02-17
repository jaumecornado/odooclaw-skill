#!/bin/bash
#
# create-invoice-full.sh - Flujo completo: verificar cuenta → crear si no existe → crear factura
# Uso: ./create-invoice-full.sh --partner-id 28 --date 2026-02-17 --account-code 629000 --account-name "Otros servicios" --amount 24.79 --description "Amazon Papel A4"

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  OdooClaw - Crear Factura con Verificación de Cuenta${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Parse arguments
PARTNER_ID=""
INVOICE_DATE=""
ACCOUNT_CODE=""
ACCOUNT_NAME=""
AMOUNT=""
DESCRIPTION=""
REFERENCE=""
COMPANY_ID="2"  # Default: BAZINGA
TAX_ID="227"    # Default: 21% IVA

while [[ $# -gt 0 ]]; do
    case $1 in
        --partner-id) PARTNER_ID="$2"; shift 2 ;;
        --date) INVOICE_DATE="$2"; shift 2 ;;
        --account-code) ACCOUNT_CODE="$2"; shift 2 ;;
        --account-name) ACCOUNT_NAME="$2"; shift 2 ;;
        --amount) AMOUNT="$2"; shift 2 ;;
        --description) DESCRIPTION="$2"; shift 2 ;;
        --reference) REFERENCE="$2"; shift 2 ;;
        --company-id) COMPANY_ID="$2"; shift 2 ;;
        --tax-id) TAX_ID="$2"; shift 2 ;;
        --help)
            echo "Uso: $0 [OPCIONES]"
            echo ""
            echo "Opciones requeridas:"
            echo "  --partner-id ID       ID del proveedor"
            echo "  --date YYYY-MM-DD     Fecha de factura"
            echo "  --account-code CODE   Código cuenta (ej: 629000)"
            echo "  --account-name NAME   Nombre de la cuenta"
            echo "  --amount NUM          Importe base"
            echo "  --description TEXT    Descripción línea"
            echo ""
            echo "Opciones opcionales:"
            echo "  --reference TEXT      Referencia factura"
            echo "  --company-id ID       ID compañía (default: 2)"
            echo "  --tax-id ID           ID impuesto (default: 227 = 21%)"
            echo ""
            echo "Ejemplo:"
            echo "  $0 --partner-id 28 --date 2026-02-17 --account-code 629000 \\"
            echo "     --account-name 'Otros servicios' --amount 24.79 \\"
            echo "     --description 'Amazon Papel A4' --reference 'ES6J9SGAEUI'"
            exit 0
            ;;
        *) echo -e "${RED}Error: Opción desconocida $1${NC}"; exit 1 ;;
    esac
done

# Validate required args
if [[ -z "$PARTNER_ID" || -z "$INVOICE_DATE" || -z "$ACCOUNT_CODE" || -z "$ACCOUNT_NAME" || -z "$AMOUNT" || -z "$DESCRIPTION" ]]; then
    echo -e "${RED}Error: Faltan argumentos requeridos${NC}"
    echo "Usa --help para ver la ayuda"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Step 1: Check if account exists
echo -e "${YELLOW}PASO 1: Verificando cuenta $ACCOUNT_CODE para compañía $COMPANY_ID...${NC}"
ACCOUNT_ID=$($SCRIPT_DIR/check-account.sh "$ACCOUNT_CODE" "$COMPANY_ID" 2>/dev/null | grep "CUENTA ENCONTRADA" | grep -o 'ID: [0-9]*' | cut -d' ' -f2 || echo "")

if [[ -z "$ACCOUNT_ID" ]]; then
    echo -e "${YELLOW}⚠️  La cuenta $ACCOUNT_CODE no existe o no está disponible para la compañía $COMPANY_ID${NC}"
    echo ""
    
    # Step 2: Create account
    echo -e "${YELLOW}PASO 2: Creando cuenta $ACCOUNT_CODE...${NC}"
    read -p "¿Crear cuenta $ACCOUNT_CODE - $ACCOUNT_NAME? (s/N): " confirm
    if [[ $confirm =~ ^[Ss]$ ]]; then
        $SCRIPT_DIR/create-account.sh "$ACCOUNT_CODE" "$ACCOUNT_NAME" "expense" "$COMPANY_ID"
        
        # Step 3: Verify account was created
        echo ""
        echo -e "${YELLOW}PASO 3: Verificando cuenta creada...${NC}"
        ACCOUNT_ID=$($SCRIPT_DIR/check-account.sh "$ACCOUNT_CODE" "$COMPANY_ID" 2>/dev/null | grep "CUENTA ENCONTRADA" | grep -o 'ID: [0-9]*' | cut -d' ' -f2 || echo "")
        
        if [[ -z "$ACCOUNT_ID" ]]; then
            echo -e "${RED}❌ Error: No se pudo crear/verificar la cuenta${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Cancelado por el usuario${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Cuenta verificada: ID $ACCOUNT_ID${NC}"
fi

echo ""
echo -e "${YELLOW}PASO 4: Creando factura en borrador...${NC}"
echo "   Proveedor ID: $PARTNER_ID"
echo "   Fecha: $INVOICE_DATE"
echo "   Cuenta: $ACCOUNT_CODE (ID: $ACCOUNT_ID)"
echo "   Importe: $AMOUNT €"
echo "   Descripción: $DESCRIPTION"
[[ -n "$REFERENCE" ]] && echo "   Referencia: $REFERENCE"
echo ""

# Step 4: Create invoice using Python for better error handling
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

invoice_data = {
    "move_type": "in_invoice",
    "partner_id": $PARTNER_ID,
    "journal_id": 11,  # Vendor Bills de BAZINGA
    "invoice_date": "$INVOICE_DATE",
    "date": "$INVOICE_DATE",
    "ref": "$REFERENCE" if "$REFERENCE" else "$DESCRIPTION",
    "invoice_line_ids": [
        [0, 0, {
            "name": "$DESCRIPTION",
            "quantity": 1,
            "price_unit": $AMOUNT,
            "account_id": $ACCOUNT_ID,
            "tax_ids": [[6, 0, [$TAX_ID]]]
        }]
    ]
}

try:
    invoice_id = models.execute_kw(db, uid, api_key, 'account.move', 'create', [invoice_data],
        {'context': {'allowed_company_ids': [$COMPANY_ID]}})
    
    invoice = models.execute_kw(db, uid, api_key, 'account.move', 'read', [invoice_id],
        {'fields': ['name', 'state', 'amount_total', 'amount_untaxed', 'amount_tax']})
    
    inv = invoice[0]
    print(f"${GREEN}✅ Factura creada exitosamente${NC}")
    print(f"")
    print(f"${GREEN}Detalles:${NC}")
    print(f"   Número: {inv['name']}")
    print(f"   ID: {inv['id']}")
    print(f"   Estado: ${YELLOW}BORRADOR${NC}")
    print(f"   Base: {inv['amount_untaxed']} €")
    print(f"   IVA: {inv['amount_tax']} €")
    print(f"   Total: {inv['amount_total']} €")
    print(f"")
    print(f"${YELLOW}⚠️  IMPORTANTE: La factura está en borrador para validación manual${NC}")
    
except Exception as e:
    error_msg = str(e)
    print(f"${RED}❌ Error al crear factura: {error_msg}${NC}")
    
    if "company inconsistencies" in error_msg:
        print(f"")
        print(f"${YELLOW}💡 Posible solución: La cuenta pertenece a otra compañía${NC}")
        print(f"   Intenta crear la cuenta específicamente para la compañía $COMPANY_ID")
    
    exit(1)
EOF
