# Revisión del XML (`Lazaro.drawio.xml`)

## 1) Interfaz visual (resumen)
Se identifican 3 visiones principales:
- Administrador
- Cliente/Residente
- Conserje

Módulos funcionales detectados:
- Mis Edificios / selección de edificio
- Reservas
- Configuraciones
- Link de pago
- Gastos comunes y pagos
- Documentos
- Proveedores
- Dashboard (estadística/consumo/pendientes)
- Calendario
- Votaciones
- Encomiendas
- Visitas
- Noticias / Alertas / Novedades
- Gestión interna (conserje)

## 2) Infra y sistema
Se detecta una arquitectura moderna:
- Frontend React
- CDN/Edge
- API Gateway
- Backend Java Spring Boot
- Redis
- PostgreSQL
- PgBouncer
- Mensajería (Kafka/RabbitMQ)
- Observabilidad
- Seguridad OAuth2/JWT/RBAC

## 3) Patrones y diseño
Se detectan patrones esperados:
- Clean Architecture + Hexagonal
- Controller, DTO, Service Layer, Repository
- Adapter, Strategy, Factory, Facade
- Resilience4j, Cache Aside, Event-Driven

## 4) Opciones adicionales sugeridas para menú
Para reforzar operación y trazabilidad:
- Incidencias/Tickets
- Bitácora de mantenimiento
- Multi-condominio (switch rápido)
- Centro de notificaciones unificado
- Auditoría de acciones administrativas
- Gestión de permisos por rol granular
- Conciliación bancaria de pagos
- Reportes exportables (PDF/CSV)
