#!/bin/bash
# =============================================================
# COMMANDES UTILITAIRES - Partie 3 Kubernetes
# =============================================================
# Ce script regroupe toutes les commandes utiles du projet.
# Usage : bash kubernetes/commandes_utils.sh [action]
#
# Actions disponibles :
#   deploy    -> deploie toutes les ressources Kubernetes
#   status    -> affiche l'etat de tous les pods/services
#   urls      -> affiche les URLs d'acces aux applications
#   inject-ip -> injecte l'IP Minikube dans les manifests
#   open      -> ouvre les 3 services dans le navigateur
#   clean     -> supprime toutes les ressources du namespace
# =============================================================

set -e  # Arrete le script si une commande echoue

# --- Couleurs pour les messages ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Injection IP Minikube dans webapp/deployment.yml ---
inject_ip() {
  echo -e "${YELLOW}>>> Recuperation de l'IP Minikube...${NC}"
  MINIKUBE_IP=$(minikube ip)
  echo -e "${GREEN}IP Minikube : $MINIKUBE_IP${NC}"

  # Remplace toute IP existante par la nouvelle IP Minikube
  sed -i "s|http://[0-9.]*:30069|http://$MINIKUBE_IP:30069|g" kubernetes/webapp/deployment.yml
  sed -i "s|http://[0-9.]*:30050|http://$MINIKUBE_IP:30050|g" kubernetes/webapp/deployment.yml

  echo -e "${GREEN}>>> IP injectee dans kubernetes/webapp/deployment.yml${NC}"
  grep "http://" kubernetes/webapp/deployment.yml
}

# --- Deploiement complet dans l'ordre des dependances ---
deploy_all() {
  echo -e "${YELLOW}>>> Injection de l'IP Minikube...${NC}"
  inject_ip

  echo -e "${YELLOW}>>> Deploiement du namespace...${NC}"
  kubectl apply -f kubernetes/namespace.yml

  echo -e "${YELLOW}>>> Deploiement des secrets...${NC}"
  kubectl apply -f kubernetes/secrets.yml

  echo -e "${YELLOW}>>> Deploiement de PostgreSQL...${NC}"
  kubectl apply -f kubernetes/postgres/
  echo ">>> Attente demarrage PostgreSQL (30s)..."
  sleep 30

  echo -e "${YELLOW}>>> Deploiement d'Odoo...${NC}"
  kubectl apply -f kubernetes/odoo/
  echo ">>> Attente demarrage Odoo (60s)..."
  sleep 60

  echo -e "${YELLOW}>>> Deploiement de pgAdmin...${NC}"
  kubectl apply -f kubernetes/pgadmin/
  echo ">>> Attente demarrage pgAdmin (30s)..."
  sleep 30

  echo -e "${YELLOW}>>> Deploiement de ic-webapp...${NC}"
  kubectl apply -f kubernetes/webapp/

  echo -e "${GREEN}>>> Deploiement termine !${NC}"
  status
  urls
}

# --- Statut de tous les pods et services ---
status() {
  echo -e "${YELLOW}>>> Pods :${NC}"
  kubectl get pods -n icgroup

  echo -e "${YELLOW}>>> Services :${NC}"
  kubectl get services -n icgroup

  echo -e "${YELLOW}>>> PVC :${NC}"
  kubectl get pvc -n icgroup
}

# --- Affichage des URLs d'acces ---
# IMPORTANT - Sur Windows avec Minikube driver Docker :
# L'IP Minikube (192.168.x.x) n'est PAS accessible depuis le navigateur.
# Il faut utiliser "minikube service" qui cree un tunnel vers 127.0.0.1.
# Les ports tunnels (ex: 50177, 50178) changent a chaque session.
# Utiliser l'action "open" pour lancer les tunnels automatiquement.
urls() {
  MINIKUBE_IP=$(minikube ip)
  echo -e "${GREEN}======================================${NC}"
  echo -e "${GREEN}URLs Minikube (non accessibles Windows)${NC}"
  echo -e "${GREEN}======================================${NC}"
  echo -e "ic-webapp -> http://$MINIKUBE_IP:30080"
  echo -e "Odoo      -> http://$MINIKUBE_IP:30069"
  echo -e "pgAdmin   -> http://$MINIKUBE_IP:30050"
  echo -e ""
  echo -e "${YELLOW}Sur Windows : utiliser 'open' pour les tunnels${NC}"
  echo -e "${YELLOW}bash kubernetes/commandes_utils.sh open${NC}"
  echo -e "${GREEN}======================================${NC}"
}

# --- Ouverture des tunnels + navigateur (necessaire sur Windows) ---
# Lance 3 tunnels en arriere-plan via minikube service.
# Les URLs reelles (127.0.0.1:PORT) s'affichent dans le terminal.
# IMPORTANT : ne pas fermer ce terminal - les tunnels s'arretent sinon.
# Les ports changent a chaque session - noter les URLs affichees.
open() {
  echo -e "${YELLOW}>>> Ouverture des tunnels Minikube...${NC}"
  echo -e "${YELLOW}IMPORTANT : ne pas fermer ce terminal !${NC}"
  echo -e "${YELLOW}Les ports tunnels changent a chaque session.${NC}"
  echo -e "${YELLOW}Notez les URLs 127.0.0.1:PORT affichees ci-dessous.${NC}"
  echo ""

  # Lance les 3 tunnels - le & met en arriere-plan
  minikube service ic-webapp-service -n icgroup &
  minikube service odoo-service -n icgroup &
  # Le dernier reste au premier plan pour garder le terminal actif
  minikube service pgadmin-service -n icgroup
}

# --- Mise a jour des URLs vitrine apres obtention des ports tunnels ---
# Usage : bash kubernetes/commandes_utils.sh update-urls 50177 50178 50179
# Args  : $2=port ic-webapp, $3=port odoo, $4=port pgadmin
update_urls() {
  if [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
    echo -e "${RED}Usage : bash kubernetes/commandes_utils.sh update-urls PORT_WEBAPP PORT_ODOO PORT_PGADMIN${NC}"
    echo -e "${RED}Exemple : bash kubernetes/commandes_utils.sh update-urls 50177 50178 50179${NC}"
    exit 1
  fi

  echo -e "${YELLOW}>>> Mise a jour des URLs dans webapp/deployment.yml...${NC}"
  # Remplace les URLs Odoo et pgAdmin par les ports tunnels actifs
  # NOUVEAU - cible la ligne value: qui suit ODOO_URL et PGADMIN_URL
  sed -i "/ODOO_URL/{n; s|value:.*|value: \"http://127.0.0.1:$3\"|}" kubernetes/webapp/deployment.yml
  sed -i "/PGADMIN_URL/{n; s|value:.*|value: \"http://127.0.0.1:$4\"|}" kubernetes/webapp/deployment.yml

  kubectl apply -f kubernetes/webapp/
  echo -e "${GREEN}>>> URLs mises a jour et webapp redemarree${NC}"
  echo -e "ic-webapp -> http://127.0.0.1:$2"
  echo -e "Odoo      -> http://127.0.0.1:$3"
  echo -e "pgAdmin   -> http://127.0.0.1:$4"
}

# --- Nettoyage complet ---
clean() {
  echo -e "${RED}>>> Suppression de toutes les ressources icgroup...${NC}"
  kubectl delete namespace icgroup
  echo -e "${GREEN}>>> Namespace icgroup supprime.${NC}"
}

# --- Point d'entree ---
case "$1" in
  deploy)      deploy_all ;;
  status)      status ;;
  urls)        urls ;;
  inject-ip)   inject_ip ;;
  open)        open ;;
  update-urls) update_urls "$@" ;;
  clean)       clean ;;
  *)
    echo "Usage : bash kubernetes/commandes_utils.sh [action]"
    echo ""
    echo "Actions disponibles :"
    echo "  deploy                            -> deploie toutes les ressources"
    echo "  status                            -> etat des pods/services/pvc"
    echo "  urls                              -> affiche les URLs Minikube"
    echo "  inject-ip                         -> injecte l'IP dans webapp"
    echo "  open                              -> ouvre les tunnels + navigateur"
    echo "  update-urls PORT_WEB PORT_O PORT_P -> met a jour URLs vitrine"
    echo "  clean                             -> supprime le namespace icgroup"
    ;;
esac
