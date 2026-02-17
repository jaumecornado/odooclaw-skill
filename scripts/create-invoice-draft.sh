#!/bin/bash
#
# odooclaw-create-invoice-draft.sh
# Helper script to create Odoo invoices ALWAYS in draft state for manual validation
#
# Usage: ./odooclaw-create-invoice-draft.sh --partner-id 123 --date 2026-02-17 --lines '[...]'

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  OdooClaw - Crear Factura en Borrador${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
echo ""

# Validate odooapi is installed
if ! command -v odooapi &> /dev/null; then
    echo -e "${RED}Error: odooapi-cli no está instalado${NC}"
    echo "Instala con: brew install jaumecornado/tap/odooapi"
    exit 1
fi

# Check authentication
if ! odooapi ping &> /dev/null; then
    echo -e "${RED}Error: No autenticado en Odoo${NC}"
    echo "Configura con: odooapi auth set --base-url URL --db DB --username USER --password PASS"
    exit 1
fi

# Parse arguments
PARTNER_ID=""
INVOICE_DATE=""
LINES_JSON=""
REFERENCE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --partner-id)
            PARTNER_ID="$2"
            shift 2
            ;;
        --date)
            INVOICE_DATE="$2"
            shift 2
            ;;
        --lines)
            LINES_JSON="$2"
            shift 2
            ;;
        --reference)
            REFERENCE="$2"
            shift 2
            ;;
        --help)
            echo "Uso: $0 [OPCIONES]"
            echo ""
            echo "Opciones:"
            echo "  --partner-id ID       ID del proveedor/cliente (requerido)"
            echo "  --date YYYY-MM-DD     Fecha de la factura (requerido)"
            echo "  --lines JSON          Líneas de factura en formato JSON (requerido)"
            echo "  --reference TEXT      Referencia/número de factura (opcional)"
            echo ""
            echo "Ejemplo:"
            echo "  $0 --partner-id 42 --date 2026-02-17 --lines '[[0,0,{\"name\":\"Servicios\",\"quantity\":1,\"price_unit\":100}]]' --reference 'FAC-001'"
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Opción desconocida $1${NC}"
            exit 1
            ;;
    esac
done

# Validate required args
if [[ -z "$PARTNER_ID" ]] || [[ -z "$INVOICE_DATE" ]] || [[ -z "$LINES_JSON" ]]; then
    echo -e "${RED}Error: Faltan argumentos requeridos${NC}"
    echo "Usa --help para ver la ayuda"
    exit 1
fi

# Build invoice data
INVOICE_DATA=$(cat <<EOF
{
  "move_type": "in_invoice",
  "partner_id": $PARTNER_ID,
  "invoice_date": "$INVOICE_DATE",
  "line_ids": $LINES_JSON
EOF
)

# Add reference if provided
if [[ -n "$REFERENCE" ]]; then
    INVOICE_DATA="$INVOICE_DATA, \"ref\": \"$REFERENCE\""
fi

INVOICE_DATA="$INVOICE_DATA }"

echo -e "${YELLOW}Creando factura en estado BORRADOR...${NC}"
echo "  - Proveedor ID: $PARTNER_ID"
echo "  - Fecha: $INVOICE_DATE"
[[ -n "$REFERENCE" ]] && echo "  - Referencia: $REFERENCE"
echo ""

# Create invoice (will be in draft state by default)
RESULT=$(odooapi records create account.move --json --data "$INVOICE_DATA" 2>&1)

if [[ $? -eq 0 ]]; then
    INVOICE_ID=$(echo "$RESULT" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
    
    echo -e "${GREEN}✅ Factura creada exitosamente${NC}"
    echo ""
    echo -e "${GREEN}Detalles:${NC}"
    echo "  - ID: $INVOICE_ID"
    echo "  - Estado: ${YELLOW}BORRADOR${NC} (requiere validación manual)"
    echo ""
    echo -e "${YELLOW}ℹ️  IMPORTANTE:${NC}"
    echo "   La factura queda en borrador para revisión manual."
    echo "   El usuario debe validarla en Odoo cuando esté listo."
    echo ""
    echo -e "${GREEN}Para ver la factura:${NC}"
    echo "  odooapi records read account.move $INVOICE_ID --json"
else
    echo -e "${RED}❌ Error al crear la factura:${NC}"
    echo "$RESULT"
    exit 1
fi
