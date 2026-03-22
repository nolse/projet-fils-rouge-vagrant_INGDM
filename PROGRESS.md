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
- [x] Partie 2 : CI/CD Jenkins + Ansible
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
- [x] Partie 3 : Kubernetes (Minikube) - EN COURS
      - [x] Minikube v1.38.1 installe + cluster demarre (driver Docker)
      - [x] kubectl v1.34.1 disponible
      - [x] Namespace icgroup (env=prod)
      - [x] Secret icgroup-secrets (5 cles : postgres x3, pgadmin x2)
      - [x] PostgreSQL - Deployment + Service (ClusterIP) + PVC 2Gi
      - [x] Odoo - Deployment + Service (NodePort 30069) + ConfigMap odoo.conf
            - BDD initialisee via --init=base (arg CLI)
            - Login : admin / admin
      - [x] pgAdmin - Deployment + Service (NodePort 30050) + ConfigMap servers.json
            - Login : admin@icgroup.fr / pgadmin_password
      - [x] ic-webapp - Deployment + Service (NodePort 30080)
      - [x] Script commandes_utils.sh (deploy/status/urls/open/update-urls/clean)
      - [ ] Retirer --init=base du deployment Odoo (base deja initialisee)
      - [ ] Fixer les URLs vitrine -> Odoo/pgAdmin (boutons app vitrine)
      - [ ] HTTPS avec Ingress (bonus)
      - [ ] Mettre a jour README kubernetes/

## Problemes rencontres et solutions - Partie 3
| Probleme | Cause | Solution |
|---|---|---|
| 192.168.49.2 inaccessible navigateur | IP interne Docker non routee Windows | minikube service -> tunnel 127.0.0.1 |
| Odoo : ir_module_module does not exist | BDD non initialisee | --init=base en arg CLI |
| command/args ignore HOST/PORT | Odoo lit son propre conf, pas les env vars | ConfigMap odoo.conf + --config= |
| init = base dans odoo.conf ignore | Option CLI uniquement | Garde dans args du deployment |
| Encodage YAML Windows | Emojis et tirets speciaux dans commentaires | Supprimer tous caracteres speciaux des YAML |
| Ports tunnels changent a chaque session | Limitation Minikube driver Docker Windows | Script update-urls pour mettre a jour webapp |

