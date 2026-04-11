#!/bin/bash
# ============================================================
# bootstrap.sh — Installation des prerequis
# A lancer une seule fois sur la VM Vagrant
#
# Installe :
#   - Terraform
#   - AWS CLI
#   - jq
#   - Ansible + collection community.docker
#
# Utilisation :
#   bash bootstrap.sh
# ============================================================

set -e

echo "============================================================"
echo " Bootstrap — Installation des prerequis"
echo "============================================================"

# --------------------------------------------------------
# Mise a jour des paquets
# --------------------------------------------------------
echo ""
echo "[1/5] Mise a jour des paquets..."
sudo apt update -y
echo "✅ Paquets mis a jour"

# --------------------------------------------------------
# Installation de jq
# --------------------------------------------------------
echo ""
echo "[2/5] Installation de jq..."
sudo apt install -y jq
echo "✅ jq $(jq --version) installe"

# --------------------------------------------------------
# Installation de Terraform
# --------------------------------------------------------
echo ""
echo "[3/5] Installation de Terraform..."
sudo apt install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update -y
sudo apt install -y terraform
echo "✅ $(terraform --version | head -1) installe"

# --------------------------------------------------------
# Installation de AWS CLI
# --------------------------------------------------------
echo ""
echo "[4/5] Installation de AWS CLI..."
sudo apt install -y unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
sudo /tmp/aws/install
rm -rf /tmp/awscliv2.zip /tmp/aws
echo "✅ $(aws --version) installe"

# --------------------------------------------------------
# Installation de Ansible
# --------------------------------------------------------
echo ""
echo "[5/5] Installation de Ansible..."
sudo apt install -y ansible
ansible-galaxy collection install community.docker --upgrade
echo "✅ $(ansible --version | head -1) installe"
echo "✅ Collection community.docker installee"

# --------------------------------------------------------
# Recapitulatif
# --------------------------------------------------------
echo ""
echo "============================================================"
echo " Bootstrap termine !"
echo "============================================================"
echo ""
echo " Versions installees :"
echo "   Terraform : $(terraform --version | head -1)"
echo "   AWS CLI   : $(aws --version)"
echo "   jq        : $(jq --version)"
echo "   Ansible   : $(ansible --version | head -1)"
echo ""
echo " Prochaine etape :"
echo "   aws configure  # Configurer les credentials AWS"
echo "   cp projet-fil-rouge-key.pem ~/.ssh/"
echo "   bash reproduce_infra.sh"
echo "============================================================"
