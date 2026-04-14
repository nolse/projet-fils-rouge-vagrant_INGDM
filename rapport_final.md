# Rapport Final — Projet Fil Rouge DevOps IC-GROUP

## Table des matières

1. [Contexte et objectifs](#1-contexte-et-objectifs)
2. [Infrastructure et environnement](#2-infrastructure-et-environnement)
3. [Architecture applicative](#3-architecture-applicative)
4. [Question théorique — Identification des ressources](#4-question-théorique--identification-des-ressources)
5. [Déploiement des manifests Kubernetes](#5-déploiement-des-manifests-kubernetes)
6. [Persistance des données](#6-persistance-des-données)
7. [Vérification du déploiement](#7-vérification-du-déploiement)
8. [Tests de fonctionnement](#8-tests-de-fonctionnement)
9. [Conclusion](#9-conclusion)

---

## 1. Contexte et objectifs

Ce projet fil rouge s'inscrit dans le cadre de la formation DevOps. Il a pour objectif de déployer une infrastructure applicative complète sur un cluster **Minikube** (single-node), en utilisant **Kubernetes** comme orchestrateur de conteneurs.

### Applications déployées

| Application | Rôle |
|---|---|
| **ic-webapp** | Application web front-end IC-GROUP |
| **Odoo** | ERP — interface de gestion métier |
| **pgAdmin** | Interface graphique d'administration PostgreSQL |
| **PostgreSQL** | Base de données relationnelle (BDD Odoo) |

---

## 2. Infrastructure et environnement

### Stack technique

| Composant | Version / Détail |
|---|---|
| Hyperviseur | VirtualBox |
| Provisioning VM | Vagrant |
| OS VM | Ubuntu (minikube) |
| Orchestrateur | Minikube (single-node) |
| Namespace | `icgroup` |
| IP du nœud | `192.168.56.100` |

### Organisation du projet

```
projet-fils-rouge-vagrant/
├── Vagrantfile
├── setup-network.sh
├── kubernetes/
│   ├── commandes_utils.sh
│   ├── namespace.yaml
│   ├── postgres-deployment.yaml
│   ├── postgres-service.yaml
│   ├── postgres-pvc.yaml
│   ├── odoo-deployment.yaml
│   ├── odoo-service.yaml
│   ├── odoo-pvc.yaml
│   ├── pgadmin-deployment.yaml
│   ├── pgadmin-service.yaml
│   ├── ic-webapp-deployment.yaml
│   └── ic-webapp-service.yaml
```

---

## 3. Architecture applicative

L'architecture respecte le schéma synoptique fourni par le formateur. Elle s'organise autour de 4 applications interconnectées, exposées via des Services Kubernetes de types **NodePort** ou **ClusterIP** selon le besoin d'accès externe ou interne.

```
[Navigateur Windows]
        |
        | :30080           :30069           :30050
        ↓                   ↓                 ↓
[A] ic-webapp-service  odoo-service     pgadmin-service
        |                   |                 |
   [B] ic-webapp x2    [D] odoo x2       [H] pgadmin
                            |                 |
                       [E] postgres-service   |
                            |_________________|
                            ↓
                       [F] postgres
```

---

## 4. Question théorique — Identification des ressources

En se basant sur le schéma synoptique `synoptique_Kubernetes.jpeg` fourni, voici l'identification de chacune des ressources A à H :

| Ressource | Type Kubernetes | Nom dans le projet | Rôle |
|---|---|---|---|
| **A** | Service NodePort | `ic-webapp-service` | Point d'entrée externe — expose ic-webapp sur le port `30080`, accessible depuis le navigateur Windows |
| **B** | Deployment (2 Pods) | `ic-webapp` | Application front-end IC-GROUP, déployée en **2 réplicas** pour la haute disponibilité |
| **C** | Service NodePort | `odoo-service` | Expose Odoo en interne (appelé par ic-webapp) et en externe sur le port `30069` |
| **D** | Deployment (2 Pods) | `odoo` | Application ERP Odoo Web, déployée en **2 réplicas** pour la haute disponibilité |
| **E** | Service ClusterIP | `postgres-service` | Service interne uniquement — relie Odoo et pgAdmin à PostgreSQL, non exposé à l'extérieur |
| **F** | Deployment (1 Pod) | `postgres` | Base de données PostgreSQL (BDD_Odoo) — données persistées via un PersistentVolumeClaim |
| **G** | Service NodePort | `pgadmin-service` | Expose pgAdmin vers l'extérieur sur le port `30050` |
| **H** | Deployment (1 Pod) | `pgadmin` | Interface graphique pgAdmin pour l'administration de PostgreSQL |

### Points clés de l'architecture

- **PostgreSQL (E)** est le seul service en **ClusterIP** : la base de données n'est jamais exposée directement à l'extérieur, uniquement accessible par Odoo et pgAdmin au sein du cluster.
- **ic-webapp, Odoo** sont déployés en **2 réplicas** conformément au schéma (haute disponibilité).
- **pgAdmin et PostgreSQL** sont déployés en **1 réplica** (pas de réplication dans le schéma).

---

## 5. Déploiement des manifests Kubernetes

### Procédure de déploiement

```bash
# 1. Démarrage du cluster
minikube start

# 2. Configuration réseau
bash setup-network.sh

# 3. Déploiement de toutes les ressources
bash kubernetes/commandes_utils.sh deploy
```

### Détail des manifests appliqués

#### Namespace
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: icgroup
```

#### Exemple — Déploiement PostgreSQL
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: icgroup
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    spec:
      containers:
        - name: postgres
          image: postgres:13
          env:
            - name: POSTGRES_DB
              value: odoo
            - name: POSTGRES_USER
              value: odoo
            - name: POSTGRES_PASSWORD
              value: odoo_password
          volumeMounts:
            - mountPath: /var/lib/postgresql/data
              name: postgres-storage
      volumes:
        - name: postgres-storage
          persistentVolumeClaim:
            claimName: postgres-pvc
```

---

## 6. Persistance des données

Deux **PersistentVolumeClaims** ont été créés pour garantir la persistance des données applicatives :

| PVC | Application | Capacité | Mode d'accès |
|---|---|---|---|
| `postgres-pvc` | PostgreSQL | 2 Gi | ReadWriteOnce |
| `odoo-pvc` | Odoo | 1 Gi | ReadWriteOnce |

```
NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES
odoo-pvc       Bound    pvc-34147d49-f4a2-4f3c-8f37-a414cd756640   1Gi        RWO
postgres-pvc   Bound    pvc-3e35963e-4c56-4b26-9910-3ca9d07cafdd   2Gi        RWO
```

Les volumes sont automatiquement provisionnés par le **StorageClass `standard`** de Minikube.

---

## 7. Vérification du déploiement

### État des Pods

```
NAME                         READY   STATUS    RESTARTS   AGE
ic-webapp-69db74c864-9bj7d   1/1     Running   0          3h37m
ic-webapp-69db74c864-wdv5p   1/1     Running   0          30s
odoo-775d57c458-ggghh        1/1     Running   0          10s
odoo-775d57c458-q6sx4        1/1     Running   0          3h38m
pgadmin-78f5966bc7-8qlsv     1/1     Running   0          3h37m
postgres-784c6d4b47-tmgs8    1/1     Running   0          3h39m
```

✅ 2 réplicas pour ic-webapp — conforme au schéma
✅ 2 réplicas pour Odoo — conforme au schéma
✅ Tous les pods en état `Running`

### État des Services

```
NAME                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)
ic-webapp-service   NodePort    10.99.108.174   <none>        8080:30080/TCP
odoo-service        NodePort    10.105.25.244   <none>        8069:30069/TCP
pgadmin-service     NodePort    10.107.15.134   <none>        80:30050/TCP
postgres-service    ClusterIP   10.106.88.245   <none>        5432/TCP
```

✅ postgres-service en ClusterIP — base de données non exposée à l'extérieur
✅ Les 3 autres services en NodePort — accessibles depuis Windows

---

## 8. Tests de fonctionnement

### URLs d'accès depuis Windows

| Application | URL | Port NodePort |
|---|---|---|
| ic-webapp | http://192.168.56.100:30080 | 30080 |
| Odoo | http://192.168.56.100:30069 | 30069 |
| pgAdmin | http://192.168.56.100:30050 | 30050 |

### Identifiants de connexion

**pgAdmin**
- Email : `admin@icgroup.fr`
- Mot de passe : `pgadmin_password`

**Odoo**
- Login : `admin`
- Mot de passe : `admin`

**PostgreSQL (via pgAdmin)**
- Host : `postgres-service`
- Port : `5432`
- Base : `odoo`
- User : `odoo`
- Mot de passe : `odoo_password`

### Captures d'écran

#### ic-webapp accessible sur http://192.168.56.100:30080
> *[Insérer capture ic-webapp]*

#### Odoo accessible sur http://192.168.56.100:30069
> *[Insérer capture Odoo - page de connexion]*

#### pgAdmin accessible sur http://192.168.56.100:30050
> *[Insérer capture pgAdmin - dashboard]*

#### Connexion PostgreSQL via pgAdmin
> *[Insérer capture de la connexion BDD Odoo dans pgAdmin]*

---

## 9. Conclusion

Ce projet a permis de déployer une infrastructure applicative complète sur Kubernetes (Minikube), en respectant les contraintes suivantes :

- ✅ Architecture conforme au schéma synoptique du formateur
- ✅ Namespace dédié `icgroup`
- ✅ Haute disponibilité : 2 réplicas pour ic-webapp et Odoo
- ✅ Persistance des données via PVC pour PostgreSQL et Odoo
- ✅ Isolation réseau : PostgreSQL uniquement accessible en interne (ClusterIP)
- ✅ Accès externe via NodePort pour ic-webapp, Odoo et pgAdmin
- ✅ Toutes les applications accessibles et fonctionnelles depuis Windows

La prochaine étape consistera à mettre en place un **Ingress Controller** avec des noms de domaine personnalisés, afin de remplacerles accès par ports NodePort par des URLs propres et lisibles.
