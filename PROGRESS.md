# Projet Fil Rouge - Avancement

## Stack
- Terraform 1.14.5 | AWS us-east-1
- Backend S3 : terraform-backend-balde
- Repo infra  : https://github.com/nolse/projet_fil_rouge_infra
- Repo ansible: https://github.com/nolse/projet-fils-rouge

## IPs (dynamiques - regenerer apres chaque apply)
- Workflow : terraform apply -> terraform_ips.json -> generate_inventory.sh

## Etapes
- [x] Partie 1 : Conteneurisation Docker - COMPLETE
      - [x] Dockerfile (python:3.6-alpine, awk releases.txt)
      - [x] releases.txt (ODOO_URL, PGADMIN_URL, version)
      - [x] ic-webapp:1.0 buildee et pushee -> alphabalde/ic-webapp:1.0
      - [x] odoo/docker-compose.yml
      - [x] pgadmin/docker-compose.yml + servers.json
      - [x] jenkins-tools/
- [x] Partie 2 : CI/CD Jenkins + Ansible - COMPLETE
      - [x] roles : odoo_role / pgadmin_role / webapp_role / jenkins_role
      - [x] inventaire dynamique Terraform->Ansible
      - [x] playbook.yml + ansible.cfg + requirements.yml
      - [x] Jenkinsfile
      - [x] Deploiement 3 serveurs valide
      - [x] Jenkins  -> http://<jenkins_ip>:8080
      - [x] ic-webapp -> http://<webapp_ip>
      - [x] pgAdmin  -> http://<webapp_ip>:5050
      - [x] Odoo     -> http://<odoo_ip>:8069
      - [x] Configurer credentials Jenkins (docker-hub + ansible-ssh-key)
      - [x] Creer job Jenkins (pointer vers repo GitHub)
      - [x] Tester pipeline end-to-end
- [x] Partie 3 : Kubernetes (Minikube) - COMPLETE
      - [x] Minikube v1.38.1 + kubectl v1.34.1 (driver Docker Windows)
      - [x] Namespace icgroup (label env=prod)
      - [x] Secret icgroup-secrets (5 cles : postgres x3, pgadmin x2)
      - [x] PostgreSQL : Deployment + Service ClusterIP + PVC 2Gi
      - [x] Odoo : Deployment + Service NodePort 30069 + ConfigMap odoo.conf + PVC 1Gi
            - BDD initialisee via --init=base (retire apres init)
            - Assets regeneres via --update=web (dans les args)
            - Login : admin / admin
      - [x] pgAdmin : Deployment + Service NodePort 30050 + ConfigMap servers.json
            - Login : admin@icgroup.fr / pgadmin_password
      - [x] ic-webapp : Deployment + Service NodePort 30080
            - Boutons Odoo et pgAdmin fonctionnels
      - [x] Script commandes_utils.sh (deploy/status/urls/open/update-urls/clean)
      - [x] Diagrammes SVG : architecture.svg + https_ingress_flow.svg
      - [x] README kubernetes/
      - [x] Commit git : "Partie 3 : Kubernetes - deploiement complet icgroup"
      - [ ] HTTPS avec Ingress (bonus - a faire prochaine session)
      - [ ] Script reproduction Partie 2 avec sleeps

## Problemes rencontres et solutions - Partie 3
| Probleme | Cause | Solution |
|---|---|---|
| 192.168.49.2 inaccessible | IP interne Docker non routee Windows | minikube service -> tunnel 127.0.0.1 |
| Ports tunnels changent a chaque session | Limitation Minikube driver Docker Windows | Script update-urls dans commandes_utils.sh |
| Odoo : ir_module_module does not exist | BDD non initialisee | --init=base en arg CLI au premier demarrage |
| command/args ignore HOST/PORT | Odoo lit son propre conf | ConfigMap odoo.conf + --config= |
| init = base dans odoo.conf ignore | Option CLI uniquement | Garde dans args du deployment |
| Encodage YAML Windows | Emojis et tirets speciaux | Supprimer tous caracteres speciaux des YAML |
| Page blanche Odoo apres redemarrage | Assets CSS/JS perdus | --update=web dans args + PVC /var/lib/odoo |
| update-urls corrompt le deployment | sed mal cible | sed avec {n; s|...|...} pour cibler la ligne suivante |

