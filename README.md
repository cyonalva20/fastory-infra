# Fastory Infrastructure

Este repositorio contiene la infraestructura como código (IaC) para el proyecto Fastory, construida con Terraform, y los scripts de configuración (Ansible) para el despliegue automatizado de la aplicación.

---

## Guía de Ejecución Rápida (Para presentar en otra PC)

Si vas a presentar desde una computadora nueva, asegúrate de tener instalado **Terraform** y **AWS CLI**. Luego sigue estos pasos:

### 1. Configurar Credenciales de AWS
En la nueva PC, necesitas vincular la terminal a tu cuenta de AWS. Abre tu terminal (CMD) y ejecuta:
```cmd
aws configure
```
Te pedirá 4 datos:
1. **AWS Access Key ID:** (Cópialo de la consola web de AWS)
2. **AWS Secret Access Key:** (El código secreto largo)
3. **Default region name:** Escribe `us-east-1`
4. **Default output format:** Escribe `json`

Borrar Cuenta de AWS

rmdir /s /q %USERPROFILE%\.aws


### 2. Construir la Infraestructura
Navega a la carpeta del proyecto y ejecuta la magia de Terraform:

```cmd
# 1. Ubicarte en la carpeta donde está el código de Terraform
cd c:\Ruta\Al\Proyecto\fastory-infra\terraform

# 2. Inicializar Terraform (solo se hace la primera vez)
terraform init

# 3. Simulación (verifica que la sintaxis sea correcta y no haya errores)
terraform plan

# 4. Crear todos los recursos en la nube
terraform apply
```
*(Escribe `yes` cuando se te pida confirmar. El proceso tomará alrededor de 12 minutos debido a la Base de Datos).*

> **Importante al terminar:** Para evitar cobros en la tarjeta, recuerda siempre ejecutar `terraform destroy` (y escribir `yes`).

## Arquitectura de Módulos (Terraform)

El código de Terraform está dividido en módulos. Cada carpeta representa un componente clave de tu diagrama de arquitectura:

* **Networking (`/modules/networking`)**: Representa la red base (VPC, Subredes, Internet Gateway y NAT Gateway). Define cómo entra el tráfico de Internet hacia los recursos.
* **Security (`/modules/security`)**: Son los "guardias de seguridad". Contiene los Firewalls (Security Groups) que bloquean accesos no deseados, además del Secrets Manager y llaves KMS para cifrar contraseñas.
* **Compute (`/modules/compute`)**: El poder de procesamiento. Aquí vive el Load Balancer (ALB) que reparte el tráfico, y el Auto Scaling Group (ASG) que enciende y apaga servidores EC2 según la cantidad de usuarios.
* **Database (`/modules/database`)**: La capa de persistencia. Contiene la base de datos RDS PostgreSQL y el RDS Proxy, que evita que la base de datos se sature si recibe muchas conexiones al mismo tiempo.
* **Cache (`/modules/cache`)**: La memoria de acceso rápido. Contiene ElastiCache (Redis) para guardar sesiones y respuestas comunes, haciendo que el backend responda en milisegundos.
* **Storage (`/modules/storage`)**: El alojamiento estático. Contiene un bucket de S3 configurado como servidor web público para hospedar los archivos del Frontend.
* **Messaging (`/modules/messaging`)**: El sistema asíncrono. Contiene colas SQS para que el sistema encole trabajos pesados (como mandar emails masivos) sin congelar la pantalla de los usuarios.
* **Backup (`/modules/backup`)**: El seguro de vida. Automatiza la toma de "fotos" (snapshots) de la base de datos cada noche por si hay pérdida de datos.
* **Monitoring (`/modules/monitoring`)**: Los "ojos" del sistema. Alarmas de CloudWatch (ej. CPU por encima del 80%) que envían correos electrónicos de alerta usando SNS.

---

## ⚙️ Despliegue de la Aplicación (Ansible)

**¿Qué hay en la carpeta `ansible` y para qué sirve?**

Mientras que Terraform construye la "casa vacía" (servidores, redes y bases de datos), **Ansible** es el encargado de amueblarla. 

Los *playbooks* de Ansible son recetas automáticas que entran por SSH a los servidores EC2 recién creados por Terraform, instalan las dependencias necesarias (ej. Docker, Java), descargan el código de tu Backend (`fastory-backend`), le inyectan las contraseñas de la base de datos y arrancan la aplicación. 

**En resumen:** Terraform levanta la infraestructura de AWS, y Ansible despliega tu aplicación dentro de ella.

---

## Justificaciones de Seguridad y Costos (Para Evaluación)

Durante el desarrollo de esta infraestructura, se realizaron escaneos de seguridad estática utilizando la herramienta **Checkov**. Se corrigieron y mitigaron las vulnerabilidades críticas, tales como:
- Forzar el uso de **IMDSv2** en las instancias EC2 para evitar robo de credenciales.
- Bloquear cabeceras HTTP inválidas en el Load Balancer (ALB) para mitigar ataques de Desync.

Sin embargo, en el código se encontrarán etiquetas `#checkov:skip` para ciertas advertencias. 
**Justificación:** 
Dichas advertencias fueron evaluadas y omitidas deliberadamente porque exigen **estándares de grado Enterprise** (ej. despliegues multi-región, protección estricta contra borrado de bases de datos, rotación automática de secretos y WAFs avanzados). Implementar estas reglas generaría **costos económicos altísimos** e injustificables para un entorno académico o de prueba de concepto en AWS Learner Lab. El diseño actual mantiene un balance óptimo entre las mejores prácticas de arquitectura segura y la viabilidad económica del proyecto.

### Omisión de CDN (CloudFront) y Dominio Personalizado (Route 53)
En el diagrama de arquitectura se contempla el uso de CloudFront, ACM y Route 53. Sin embargo, para fines de esta demostración técnica, **estos módulos se encuentran desactivados en el código (`main.tf`)**.
**Justificación:** 
1. **Restricciones de Cuentas Nuevas:** AWS bloquea por defecto la creación de redes CDN (CloudFront) en cuentas recientemente creadas para prevenir abusos de red o *phishing*, requiriendo una validación manual por parte del Soporte Técnico que suele demorar días hábiles.
2. **Costos de Dominio:** La configuración de Route 53 y certificados ACM (HTTPS) requiere la compra de un nombre de dominio real registrado.
Para mantener la demostración fluida, ágil y sin bloqueos o costos extra, se optó por exponer el S3 temporalmente como *Static Website Hosting* y consumir el Backend directamente desde el *Application Load Balancer (ALB)*. El código de Terraform (Módulos CDN y DNS) ya está programado y listo para habilitarse instantáneamente cuando se adquiera un dominio corporativo.