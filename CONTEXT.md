# Contexte Projet Fil Rouge - IC Group DevOps
# A coller en debut de session Claude pour reprendre sans perte de contexte

## Stack technique
- Terraform 1.14.5 | AWS us-east-1 | Backend S3 : terraform-backend-balde
- Ansible >= 2.12 | Collection community.docker
- Docker | Images : alphabalde/ic-webapp:1.0, jenkins/jenkins:lts, odoo:13.0, dpage/pgadmin4
- Minikube v1.38.1 | kubectl v1.34.1 | driver Docker sur Windows
- Repo infra  : https://github.com/nolse/projet_fil_rouge_infra
- Repo ansible: https://github.com/nolse/projet-fils-rouge

## Architecture serveurs AWS (Partie 2)
| Serveur | Type      | Ce qui tourne                     | Ports        |
|---------|-----------|-----------------------------------|--------------|
| jenkins | t3.medium | jenkins/jenkins:lts               | 8080, 50000  |
| webapp  | t3.micro  | ic-webapp (port 80) + pgAdmin     | 80, 5050     |
| odoo    | t3.medium | Odoo 13 + PostgreSQL              | 8069, 5432   |

## Architecture Kubernetes (Partie 3)
| Ressource        | Type        | Image                      | Port   |
|------------------|-------------|----------------------------|--------|
| postgres         | Deployment  | postgres:13                | 5432   |
| postgres-service | ClusterIP   | -                          | 5432   |
| postgres-pvc     | PVC         | -                          | 2Gi    |
| odoo             | Deployment  | odoo:13.0                  | 8069   |
| odoo-service     | NodePort    | -                          | 30069  |
| odoo-config      | ConfigMap   | odoo.conf                  | -      |
| pgadmin          | Deployment  | dpage/pgadmin4             | 80     |
| pgadmin-service  | NodePort    | -                          | 30050  |
| pgadmin-servers  | ConfigMap   | servers.json               | -      |
| ic-webapp        | Deployment  | alphabalde/ic-webapp:1.0   | 8080   |
| ic-webapp-service| NodePort    | -                          | 30080  |
| icgroup-secrets  | Secret      | 5 cles BDD + pgAdmin       | -      |

## Credentials
- Odoo login    : admin / admin
- pgAdmin login : admin@icgroup.fr / pgadmin_password
- PostgreSQL    : odoo / odoo_password

## Workflow Kubernetes (a suivre a chaque session)
# 1. Demarrer Minikube
minikube start --driver=docker

# 2. Deployer toutes les ressources
bash kubernetes/commandes_utils.sh deploy

# 3. Ouvrir les tunnels (necessaire sur Windows - ports changent a chaque session)
bash kubernetes/commandes_utils.sh open
# -> Noter les ports 127.0.0.1:PORT affiches pour chaque service

# 4. Mettre a jour les URLs de la vitrine avec les ports tunnels actifs
bash kubernetes/commandes_utils.sh update-urls PORT_WEBAPP PORT_ODOO PORT_PGADMIN
# Exemple : bash kubernetes/commandes_utils.sh update-urls 50177 50178 50179

# 5. Fin de session
minikube stop

## Points importants Kubernetes
- Sur Windows driver Docker : IP 192.168.49.x non accessible depuis navigateur
  -> Toujours utiliser minikube service pour creer des tunnels 127.0.0.1
  -> Les ports tunnels changent a chaque session
- --init=base : arg CLI uniquement, ne pas mettre dans odoo.conf
  -> A retirer du deployment une fois la BDD initialisee
- Caracteres speciaux (emojis, tirets) dans les YAML : probleme encodage Windows
  -> Utiliser uniquement ASCII dans les commentaires YAML

## Structure Kubernetes
kubernetes/
├── namespace.yml
├── secrets.yml
├── commandes_utils.sh
├── architecture.svg
├── https_ingress_flow.svg
├── README.md
├── postgres/
│   ├── deployment.yml
│   ├── service.yml
│   └── pvc.yml
├── odoo/
│   ├── deployment.yml    # contient --init=base a retirer apres init
│   ├── service.yml
│   └── configmap.yml     # odoo.conf avec connexion TCP postgres-service
├── pgadmin/
│   ├── deployment.yml
│   ├── service.yml
│   └── configmap.yml     # servers.json preconfiguree
└── webapp/
    ├── deployment.yml    # ODOO_URL et PGADMIN_URL a mettre a jour chaque session
    └── service.yml

## Workflow WSL Partie 2 (a suivre a chaque session)
# 1. Depuis Git Bash - deployer infra
cd ~/cursus-devops/projet_fil_rouge_infra/app && terraform apply
# 2. Depuis Git Bash - exporter les IPs
terraform output -json public_ips > ~/cursus-devops/projet-fils-rouge/inventaire/terraform_ips.json
# 3. Depuis WSL - resync + inventaire + deploiement
wsl
rm -rf ~/projet-fils-rouge
cp -r /mnt/c/Users/balde/cursus-devops/projet-fils-rouge ~/projet-fils-rouge
cp /mnt/c/Users/balde/cursus-devops/projet_fil_rouge_infra/.secrets/projet-fil-rouge-key.pem ~/projet-fil-rouge-key.pem
chmod 600 ~/projet-fil-rouge-key.pem
cd ~/projet-fils-rouge
bash inventaire/generate_inventory.sh
ansible-playbook -i inventaire/hosts.yml playbook.yml -v
# 4. Depuis Git Bash - destroy fin de session
cd ~/cursus-devops/projet_fil_rouge_infra/app && terraform destroy

## Avancement
- [x] Partie 1 : Conteneurisation Docker - COMPLETE
- [x] Partie 2 : CI/CD Jenkins + Ansible - COMPLETE
- [x] Partie 3 : Kubernetes (Minikube) - EN COURS
      Reste : retirer --init=base, fixer URLs vitrine, HTTPS Ingress (bonus)

