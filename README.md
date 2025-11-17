# Sistema de Hackathon Colaborativa (Proyecto Finalhy)

Sistema completo en Elixir para gestionar un hackathon con equipos, proyectos, mentores, registro de usuarios, seguridad básica y una CLI interactiva.
Toda la información se persiste en archivos CSV dentro de priv/storage.

## Instalación

```bash
cd hackathon
mix deps.get
mix compile
iex -S mix
```

## Uso Básico

### Crear equipos y participantes

```elixir
Hackathon.crear_equipo("Los Innovadores", "IA para educación")
Hackathon.agregar_participante("Los Innovadores", "Ana García", "ana@email.com")
Hackathon.listar_equipos()
```

### Crear proyectos

```elixir
Hackathon.crear_proyecto("Los Innovadores", "Plataforma de aprendizaje adaptativo", :educativo)
Hackathon.actualizar_estado_proyecto("Los Innovadores", :en_progreso)
Hackathon.agregar_avance_proyecto("Los Innovadores", "Diseño de interfaz completado")
```

### Sistema de chat

```elixir
Hackathon.crear_sala("Los Innovadores")
Hackathon.enviar_mensaje("Los Innovadores", "Ana", "¡Hola equipo!")
Hackathon.obtener_historial("Los Innovadores")
```

### Mentores

```elixir
{:ok, mentor} = Hackathon.registrar_mentor("Dr. Pedro López", "Inteligencia Artificial")
Hackathon.Mentors.MentorManager.listar_mentores()
Hackathon.enviar_retroalimentacion(mentor.id, "Los Innovadores", "Excelente progreso")
```

## 🖥️ CLI Interactivo

```elixir
Hackathon.CLI.iniciar_modo_interactivo()
```

### Comandos disponibles:

- `/teams` - Lista equipos
- `/project <nombre_equipo>` - Info del proyecto
- `/join <equipo> <nombre> <email>` - Únete a un equipo
- `/chat <sala>` - Ver historial
- `/chat_create <sala>` - Crea una sala de chat
- `/chat_send <sala>` - Envía un mensaje a una sala
- `/mentors` - Lista mentores
- `/persist_save` -  Guarda todo el estado a disco
- `/persist_info` -   Muestra conteo de entidades persistidas
- `/help` - Ayuda

## Estructura

```bash
lib/
 ├── hackathon.ex
 ├── application.ex
 ├── cli.ex
 ├── cmd.ex
 ├── storage.ex
 ├── auth.ex
 ├── security.ex
 ├── chat/
 │     └── chat.ex
 ├── teams/
 │     ├── team.ex
 │     └── team_manager.ex
 ├── mentors/
 │     ├── mentor.ex
 │     └── mentor_manager.ex
 └── projects/
       ├── project.ex
       └── project_manager.ex

Y tambien cuenta con:
priv/storage
mix.exs
mix.lock
README.md
test/
```


## Persistencia

```bash
Los datos se guardan aqui:
priv/storage/
 ├── equipos.csv
 ├── mentores.csv
 └── proyectos.csv
```


## Descripción General por Módulos
### Hackathon.Auth

Maneja:
Registro de usuarios
Login
Validación de credenciales

Provee funciones de seguridad como:
Hashing de datos
Validaciones internas

### Hackathon.Teams
Incluye:
team.ex: estructura de un equipo
team_manager.ex: creación de equipos, agregar participantes, listar, etc.

### Hackathon.Mentors
Incluye:
mentor.ex: estructura de mentor
mentor_manager.ex: registro, listado y persistencia


### Hackathon.Projects
Incluye:
project.ex: definición de un proyecto
project_manager.ex: asignación, listado, registro


### Hackathon.Storage
Encargado de:
Guardar equipos, mentores y proyectos en CSV
Cargar información persistida
Manejar carpeta priv/storage


### Hackathon.CLI
Es la interfaz principal del usuario, permitiendo comandos como:

```bash
/teams
/mentors
/projects
/add_member
/help
```

