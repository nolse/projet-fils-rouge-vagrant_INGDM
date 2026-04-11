#!/bin/bash
# ============================================================
# reproduce_infra.sh — Partie 2 : Provisioning AWS
# A lancer depuis Vagrant
#
# Etapes :
#   1. terraform init  — initialisation du backend S3
#   2. terraform apply — creation des 3 instances EC2 + EIPs
#   3. Export des IPs  — terraform_ips.json pour Ansible
#
# Prerequis :
#   - AWS CLI configure (credentials valides)
#   - Bucket S3 terraform-backend-balde existant
#   - Cle SSH projet-fil-rouge-key.pem disponible
#
# Utilisation :
#   bash reproduce_infra.sh
# ============================================================

set -e  # Arret immediat si une commande echoue

# Chemins relatifs au repo — tout est dans le meme repo
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INFRA_DIR="$SCRIPT_DIR/terraform/app"
IPS_FILE="$SCRIPT_DIR/inventaire/terraform_ips.json"

echo "============================================================"
echo " Reproduction Partie 2 — Provisioning AWS"
echo "============================================================"

# --------------------------------------------------------
# Etape 1 : Initialisation Terraform
# --------------------------------------------------------
echo ""
echo "[1/3] Initialisation Terraform..."
cd "$INFRA_DIR"
terraform init -reconfigure

# --------------------------------------------------------
# Etape 2 : Creation de l'infrastructure AWS
# -auto-approve evite la confirmation manuelle
# --------------------------------------------------------
echo ""
echo "[2/3] Creation de l'infrastructure AWS..."
echo "      (3 instances EC2 + Security Group + EIPs)"
terraform apply -auto-approve

echo ""
echo "✅ Infrastructure creee avec succes"

# --------------------------------------------------------
# Etape 3 : Export des IPs publiques pour Ansible
# --------------------------------------------------------
echo ""
echo "[3/3] Export des IPs publiques..."
terraform output -json public_ips > "$IPS_FILE"

echo ""
echo "✅ IPs exportees dans : $IPS_FILE"
echo ""
terraform output public_ips

echo ""
echo "============================================================"
echo " Infrastructure prete !"
echo " Prochaine etape : bash reproduce_deploy.sh"
echo "============================================================"
