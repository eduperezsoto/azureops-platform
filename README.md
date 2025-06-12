# DevSecOps Pipeline for Secure Azure Deployments

Este repositorio contiene el proyecto de TFM “Implementación de una Estrategia de DevSecOps para la Automatización de Despliegues Seguros en Azure”. Incluye:

- Una **API REST ligera** en Flask/Python  
- Infraestructura como código con **Terraform**  
- Un pipeline CI/CD en **GitHub Actions** con pruebas unitarias, pruebas de integracion, SAST, DAST, escaneo de IaC, gestión de secretos y monitorización  
- Ejemplos de configuración de **Azure Key Vault**, **App Service**, **Log Analytics** y **Application Insights**  

---

## 📋 Contenido

1. [Requisitos](#-requisitos)  
2. [Estructura del proyecto](#-estructura-del-proyecto)  
3. [Desarrollo y pruebas locales](#-desarrollo-y-pruebas-locales)  
4. [Pipeline CI/CD](#-pipeline-cicd)  


---

## 🚀 Requisitos
- Docker (para pruebas locales)  
- Python 3.13   

---

## 📂 Estructura del proyecto


├── .github/  
│ └── workflows/ci-cd.yml # Workflow CI/CD  
├── app/ # Código de la API Flask  
│ ├── static/ # Estilos CSS  
│ ├── templates/ # Vistas Jinja2   
│ ├── config.py # Variables de entorno  
│ ├── main.py # Punto de entrada y endpoints  
│ └── requirements.txt # Dependencias de la aplicación  
├── azure-policies/ # Politicas de Azure  
├── tests/ # Pruebas unitarias e integración  
│ ├── unit/  
│ └── integration/  
├── terraform/ # Infraestructura como código  
│ ├── backend.tf  
│ ├── modules/ # Módulos (plan, service, monitor, policy)  
│ ├── main.tf  
│ ├── variables.tf  
│ └── outputs.tf  
├── Dockerfile # Imagen para pruebas locales  
├── docker-compose.yml # Entorno local con Docker  
├── .dockerignore  
├── .gitignore  
├── dev-requirements.txt # Dependencias de pruebas  
├── sonar-project.properties # Configuración SonarCloud  
└── README.md # Esta guía  


---

## 🛠️ Desarrollo y pruebas locales

1. Clona el repositorio:  
   ```bash
   git clone https://github.com/eduperezsoto/azureops-platform.git
   cd azureops-platform
   ```

2. Con Docker Compose podemos ejecutar cualquiera de los siguientes comandos:

    ```bash
    docker-compose up -d Web        # Levanta la API
    docker-compose run --rm tests   # Ejecuta los tests unitarios y de integracion
    ```
---

## 🔄 Pipeline CI/CD
El workflow .github/workflows/ci-cd.yml define cuatro jobs:

- build-and-test

    - Ejecuta tests unitarios/integración

    - Genera cobertura con pytest-cov

    - Publica resultados de las pruebas y cobertura

    - Ejecuta SonarCloud

- iac-scan

    - Escanea IaC con TFSec y Checkov

    - Publica resultados en SARIF

    - Publica Code Scanning Alerts

- deploy

    - terraform init/validate/plan/apply

    - Crea App Service y recursos asociados

    - Extrae la URL de la app para el escaneo dinámico

- dast

    - Lanza OWASP ZAP full-scan contra la URL desplegada

    - Publica informes HTML/JSON


### Secretos y variables en GitHub
- AZURE_CREDENTIALS → JSON del Service Principal
- SONAR_TOKEN → Token SonarCloud
- APP_NAME → Nombre de la aplicación en Azure

---