pipeline {
    agent any

    environment {
        DOCKER_HUB_CREDS = credentials('docker-hub-credentials')
        DOCKER_HUB_USER  = 'alphabalde'
        IMAGE_NAME       = 'ic-webapp'
        ANSIBLE_KEY      = credentials('ansible-ssh-key')
    }

    stages {

        // ----------------------------------------------------
        // Etape 1 : Recuperation du code source
        // ----------------------------------------------------
        stage('Checkout') {
            steps {
                echo ' Recuperation du code source...'
                checkout scm
            }
        }

        // ----------------------------------------------------
        // Etape 2 : Lecture de la version depuis releases.txt
        // ----------------------------------------------------
        stage('Read Version') {
            steps {
                echo ' Lecture de la version depuis releases.txt...'
                script {
                    env.APP_VERSION = sh(
                        script: "awk '/version/{print \$2}' releases.txt",
                        returnStdout: true
                    ).trim()

                    env.ODOO_URL = sh(
                        script: "awk '/ODOO_URL/{print \$2}' releases.txt",
                        returnStdout: true
                    ).trim()

                    env.PGADMIN_URL = sh(
                        script: "awk '/PGADMIN_URL/{print \$2}' releases.txt",
                        returnStdout: true
                    ).trim()

                    echo "Version detectee   : ${env.APP_VERSION}"
                    echo "ODOO_URL           : ${env.ODOO_URL}"
                    echo "PGADMIN_URL        : ${env.PGADMIN_URL}"
                }
            }
        }

        // ----------------------------------------------------
        // Etape 3 : Build de l'image Docker
        // ----------------------------------------------------
        stage('Build') {
            steps {
                echo " Build de l'image ${IMAGE_NAME}:${env.APP_VERSION}..."
                sh """
                    docker build \
                        --build-arg ODOO_URL=${env.ODOO_URL} \
                        --build-arg PGADMIN_URL=${env.PGADMIN_URL} \
                        -t ${DOCKER_HUB_USER}/${IMAGE_NAME}:${env.APP_VERSION} .
                """
            }
        }

        // ----------------------------------------------------
        // Etape 4 : Test du container ic-webapp
        // IMPORTANT :
        // - Test fait depuis l'intérieur du container (docker exec)
        //   car Jenkins tourne lui-même dans Docker
        // - Utilisation de variables shell ($VAR) et NON ${env.VAR}
        // ----------------------------------------------------
        stage('Test') {
            steps {
                echo ' Test du container ic-webapp...'
                sh '''
                    # 1. Vérifier la taille de l'image
                    IMAGE_SIZE=$(docker image inspect $DOCKER_HUB_USER/$IMAGE_NAME:$APP_VERSION --format='{{.Size}}')
                    echo "Taille image : $IMAGE_SIZE bytes"
                    [ "$IMAGE_SIZE" -lt 200000000 ] || exit 1
                    echo "Taille image OK (< 200MB)"

                    # 2. Lancer le container
                    docker run -d \
                        --name test-ic-webapp \
                        -p 8085:8080 \
                        -e ODOO_URL=$ODOO_URL \
                        -e PGADMIN_URL=$PGADMIN_URL \
                        $DOCKER_HUB_USER/$IMAGE_NAME:$APP_VERSION

                    sleep 10

                    # 3. Vérifier qu'il tourne
                    docker ps | grep test-ic-webapp || exit 1
                    echo "Container démarré OK"

                    # 4. Test HTTP depuis le container (important en Docker-in-Docker)
                    HTTP_CODE=$(docker exec test-ic-webapp curl -s -o /dev/null -w "%{http_code}" http://localhost:8080)
                    echo "HTTP_CODE=$HTTP_CODE"
                    [ "$HTTP_CODE" = "200" ] || exit 1
                    echo "HTTP 200 OK"

                    # 5. Vérifier contenu
                    docker exec test-ic-webapp curl -s http://localhost:8080 | grep -i "IC GROUP" || exit 1
                    echo "Contenu IC GROUP OK"

                    docker exec test-ic-webapp curl -s http://localhost:8080 | grep -i "$ODOO_URL" || exit 1
                    echo "Lien Odoo présent OK"

                    docker exec test-ic-webapp curl -s http://localhost:8080 | grep -i "$PGADMIN_URL" || exit 1
                    echo "Lien PgAdmin présent OK"
                '''
            }
            post {
                always {
                    sh '''
                        docker stop test-ic-webapp || true
                        docker rm test-ic-webapp || true
                    '''
                }
            }
        }

        // ----------------------------------------------------
        // Etape 5 : Push Docker Hub
        // ----------------------------------------------------
        stage('Push') {
            steps {
                echo " Push de l'image sur Docker Hub..."
                sh '''
                    echo $DOCKER_HUB_CREDS_PSW | docker login -u $DOCKER_HUB_CREDS_USR --password-stdin
                    docker push $DOCKER_HUB_USER/$IMAGE_NAME:$APP_VERSION
                    docker tag $DOCKER_HUB_USER/$IMAGE_NAME:$APP_VERSION $DOCKER_HUB_USER/$IMAGE_NAME:latest
                    docker push $DOCKER_HUB_USER/$IMAGE_NAME:latest
                '''
            }
        }

        // ----------------------------------------------------
        // Etape 6 : Generation inventaire Ansible
        // ----------------------------------------------------
        stage('Generate Inventory') {
            steps {
                echo ' Generation de l inventaire Ansible...'
                sh '''
                    cat > inventaire/hosts.yml << EOF
---
all:
  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: $ANSIBLE_KEY
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
  children:
    jenkins:
      hosts:
        jenkins_server:
          ansible_host: $JENKINS_IP
    webapp:
      hosts:
        webapp_server:
          ansible_host: $WEBAPP_IP
    odoo:
      hosts:
        odoo_server:
          ansible_host: $ODOO_IP
EOF
                '''
            }
        }

        // ----------------------------------------------------
        // Etape 7 : Deploy
        // ----------------------------------------------------
        stage('Deploy') {
            steps {
                echo ' Deploiement via Ansible...'
                sh '''
                    chmod 600 $ANSIBLE_KEY
                    ansible-playbook \
                        -i inventaire/hosts.yml \
                        --private-key=$ANSIBLE_KEY \
                        -e "webapp_image=$DOCKER_HUB_USER/$IMAGE_NAME:$APP_VERSION" \
                        -e "odoo_url=$ODOO_URL" \
                        -e "pgadmin_url=$PGADMIN_URL" \
                        playbook.yml
                '''
            }
        }

    }

    // --------------------------------------------------------
    // Notifications Slack
    // --------------------------------------------------------
    post {
        success {
            slackSend(
                channel: '#jenkins-eazytraining-alpha-alerte',
                color: '#00FF00',
                message: "SUCCESS: ${env.JOB_NAME} [${env.BUILD_NUMBER}] - ${env.BUILD_URL}"
            )
        }
        failure {
            slackSend(
                channel: '#jenkins-eazytraining-alpha-alerte',
                color: '#FF0000',
                message: "FAILED: ${env.JOB_NAME} [${env.BUILD_NUMBER}] - ${env.BUILD_URL}"
            )
        }
        always {
            sh 'docker image prune -f || true'
        }
    }
}
